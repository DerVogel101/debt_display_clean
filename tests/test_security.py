from __future__ import annotations

import tempfile
import unittest
from datetime import datetime, timedelta, timezone
from pathlib import Path
from unittest.mock import AsyncMock, patch

from fastapi import HTTPException
from httpx import ASGITransport, AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
from sqlalchemy.orm import selectinload
from starlette.requests import Request

from backend import authorization, db, main, seed_test_data, services
from backend.config import settings
from backend.proto import debt_pb2
from backend.proto import auth_pb2
from backend.storage import resolve_storage_path


class AsyncDatabaseTestCase(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self) -> None:
        self._tmpdir = tempfile.TemporaryDirectory()
        self._db_path = Path(self._tmpdir.name) / "test.sqlite"
        self._db_url = f"sqlite+aiosqlite:///{self._db_path.as_posix()}"

        self._original_engine = db.engine
        self._original_session_maker = db.async_session_maker
        self._original_upload_dir = settings.UPLOAD_DIR

        self._engine = create_async_engine(self._db_url, echo=False)
        db.engine = self._engine
        db.async_session_maker = async_sessionmaker(self._engine, expire_on_commit=False)
        settings.UPLOAD_DIR = self._tmpdir.name

        async with self._engine.begin() as conn:
            await conn.run_sync(db.Base.metadata.create_all)

    async def asyncTearDown(self) -> None:
        await self._engine.dispose()
        db.engine = self._original_engine
        db.async_session_maker = self._original_session_maker
        settings.UPLOAD_DIR = self._original_upload_dir
        try:
            self._tmpdir.cleanup()
        except PermissionError:
            pass

    async def _create_user(
        self,
        sub: str,
        email: str | None = None,
        name: str | None = None,
    ) -> db.User:
        async with db.async_session_maker() as session:
            user = await db.get_or_create_user(
                session=session,
                sub=sub,
                email=email,
                name=name,
                avatar_url=None,
            )
            await session.commit()
            return user


class LoginHardeningTests(AsyncDatabaseTestCase):
    async def test_login_ignores_spoofed_profile_fields(self) -> None:
        claims = {
            "sub": "auth0|owner",
            "email": "claim@example.com",
            "name": "Claim Name",
            "picture": "https://example.com/avatar.png",
        }
        request = auth_pb2.LoginRequest(
            access_token="valid-token",
            email="spoof@example.com",
            name="Spoofed Name",
            avatar_url="https://evil.example/avatar.png",
        )

        with (
            patch("backend.api.verify_token", new=AsyncMock(return_value=claims)),
            patch("backend.api.fetch_userinfo", new=AsyncMock(return_value={})),
        ):
            transport = ASGITransport(app=main.app)
            async with AsyncClient(
                transport=transport,
                base_url="http://testserver",
            ) as client:
                response = await client.post(
                    "/api/auth/login",
                    content=request.SerializeToString(),
                    headers={"Content-Type": "application/x-protobuf"},
                )

        self.assertEqual(response.status_code, 200)

        async with db.async_session_maker() as session:
            result = await session.execute(
                select(db.User).where(db.User.sub == claims["sub"])
            )
            user = result.scalar_one()

        self.assertEqual(user.email, claims["email"])
        self.assertEqual(user.name, claims["name"])
        self.assertEqual(user.avatar_url, claims["picture"])

    async def test_login_fetches_userinfo_when_claims_are_missing(self) -> None:
        claims_without_profile = {"sub": "auth0|owner"}
        userinfo = {
            "email": "userinfo@example.com",
            "name": "Userinfo Name",
            "picture": "https://example.com/userinfo.png",
        }
        request = auth_pb2.LoginRequest(
            access_token="valid-token",
            email="body@example.com",
            name="Body Name",
            avatar_url="https://example.com/body.png",
        )

        with (
            patch("backend.api.verify_token", new=AsyncMock(return_value=claims_without_profile)),
            patch("backend.api.fetch_userinfo", new=AsyncMock(return_value=userinfo)),
        ):
            transport = ASGITransport(app=main.app)
            async with AsyncClient(
                transport=transport,
                base_url="http://testserver",
            ) as client:
                response = await client.post(
                    "/api/auth/login",
                    content=request.SerializeToString(),
                    headers={"Content-Type": "application/x-protobuf"},
                )

        self.assertEqual(response.status_code, 200)

        async with db.async_session_maker() as session:
            result = await session.execute(
                select(db.User).where(db.User.sub == claims_without_profile["sub"])
            )
            user = result.scalar_one()

        self.assertEqual(user.email, userinfo["email"])
        self.assertEqual(user.name, userinfo["name"])
        self.assertEqual(user.avatar_url, userinfo["picture"])

    async def test_login_prefers_custom_full_name_claim_over_other_name_sources(self) -> None:
        claims = {
            "sub": "auth0|owner",
            "email": "claim@example.com",
            "name": "Claim Name",
            "picture": "https://example.com/claim.png",
            settings.AUTH0_FULL_NAME_CLAIM: "Metadata Full Name",
        }
        conflicting_userinfo = {
            "email": "userinfo@example.com",
            "name": "Userinfo Name",
            "picture": "https://example.com/userinfo.png",
        }
        request = auth_pb2.LoginRequest(
            access_token="valid-token",
            email="body@example.com",
            name="Body Name",
            avatar_url="https://example.com/body.png",
        )

        with (
            patch("backend.api.verify_token", new=AsyncMock(return_value=claims)),
            patch("backend.api.fetch_userinfo", new=AsyncMock(return_value=conflicting_userinfo)),
        ):
            transport = ASGITransport(app=main.app)
            async with AsyncClient(
                transport=transport,
                base_url="http://testserver",
            ) as client:
                response = await client.post(
                    "/api/auth/login",
                    content=request.SerializeToString(),
                    headers={"Content-Type": "application/x-protobuf"},
                )

        self.assertEqual(response.status_code, 200)

        async with db.async_session_maker() as session:
            result = await session.execute(
                select(db.User).where(db.User.sub == claims["sub"])
            )
            user = result.scalar_one()

        self.assertEqual(user.name, claims[settings.AUTH0_FULL_NAME_CLAIM])

    async def test_login_skips_userinfo_when_custom_full_name_claim_is_present(self) -> None:
        claims = {
            "sub": "auth0|owner",
            "email": "claim@example.com",
            "picture": "https://example.com/claim.png",
            settings.AUTH0_FULL_NAME_CLAIM: "Metadata Full Name",
        }
        fetch_userinfo = AsyncMock(return_value={"name": "Userinfo Name"})
        request = auth_pb2.LoginRequest(access_token="valid-token")

        with (
            patch("backend.api.verify_token", new=AsyncMock(return_value=claims)),
            patch("backend.api.fetch_userinfo", new=fetch_userinfo),
        ):
            transport = ASGITransport(app=main.app)
            async with AsyncClient(
                transport=transport,
                base_url="http://testserver",
            ) as client:
                response = await client.post(
                    "/api/auth/login",
                    content=request.SerializeToString(),
                    headers={"Content-Type": "application/x-protobuf"},
                )

        self.assertEqual(response.status_code, 200)
        fetch_userinfo.assert_not_awaited()

        async with db.async_session_maker() as session:
            result = await session.execute(
                select(db.User).where(db.User.sub == claims["sub"])
            )
            user = result.scalar_one()

        self.assertEqual(user.name, claims[settings.AUTH0_FULL_NAME_CLAIM])

    async def test_login_uses_request_profile_as_last_resort(self) -> None:
        claims_without_profile = {"sub": "auth0|owner"}
        request = auth_pb2.LoginRequest(
            access_token="valid-token",
            email="body@example.com",
            name="Body Name",
            avatar_url="https://example.com/body.png",
        )

        with (
            patch("backend.api.verify_token", new=AsyncMock(return_value=claims_without_profile)),
            patch("backend.api.fetch_userinfo", new=AsyncMock(return_value={})),
        ):
            transport = ASGITransport(app=main.app)
            async with AsyncClient(
                transport=transport,
                base_url="http://testserver",
            ) as client:
                response = await client.post(
                    "/api/auth/login",
                    content=request.SerializeToString(),
                    headers={"Content-Type": "application/x-protobuf"},
                )

        self.assertEqual(response.status_code, 200)

        async with db.async_session_maker() as session:
            result = await session.execute(
                select(db.User).where(db.User.sub == claims_without_profile["sub"])
            )
            user = result.scalar_one()

        self.assertEqual(user.email, request.email)
        self.assertEqual(user.name, request.name)
        self.assertEqual(user.avatar_url, request.avatar_url)

    async def test_login_preserves_existing_profile_when_claims_and_userinfo_are_empty(self) -> None:
        claims_with_profile = {
            "sub": "auth0|owner",
            "email": "claim@example.com",
            "name": "Claim Name",
            "picture": "https://example.com/avatar.png",
        }
        claims_without_profile = {"sub": "auth0|owner"}

        first_request = auth_pb2.LoginRequest(
            access_token="first-token",
            email="ignored@example.com",
            name="Ignored",
            avatar_url="https://ignored.example/avatar.png",
        )
        second_request = auth_pb2.LoginRequest(access_token="second-token")

        with (
            patch(
                "backend.api.verify_token",
                new=AsyncMock(side_effect=[claims_with_profile, claims_without_profile]),
            ),
            patch("backend.api.fetch_userinfo", new=AsyncMock(return_value={})),
        ):
            transport = ASGITransport(app=main.app)
            async with AsyncClient(
                transport=transport,
                base_url="http://testserver",
            ) as client:
                first_response = await client.post(
                    "/api/auth/login",
                    content=first_request.SerializeToString(),
                    headers={"Content-Type": "application/x-protobuf"},
                )
                second_response = await client.post(
                    "/api/auth/login",
                    content=second_request.SerializeToString(),
                    headers={"Content-Type": "application/x-protobuf"},
                )

        self.assertEqual(first_response.status_code, 200)
        self.assertEqual(second_response.status_code, 200)

        async with db.async_session_maker() as session:
            result = await session.execute(
                select(db.User).where(db.User.sub == claims_with_profile["sub"])
            )
            user = result.scalar_one()

        self.assertEqual(user.email, claims_with_profile["email"])
        self.assertEqual(user.name, claims_with_profile["name"])
        self.assertEqual(user.avatar_url, claims_with_profile["picture"])

    async def test_login_prefers_claims_over_userinfo(self) -> None:
        claims = {
            "sub": "auth0|owner",
            "email": "claim@example.com",
            "name": "Claim Name",
            "picture": "https://example.com/claim.png",
        }
        conflicting_userinfo = {
            "email": "userinfo@example.com",
            "name": "Userinfo Name",
            "picture": "https://example.com/userinfo.png",
        }
        request = auth_pb2.LoginRequest(access_token="valid-token")

        with (
            patch("backend.api.verify_token", new=AsyncMock(return_value=claims)),
            patch("backend.api.fetch_userinfo", new=AsyncMock(return_value=conflicting_userinfo)),
        ):
            transport = ASGITransport(app=main.app)
            async with AsyncClient(
                transport=transport,
                base_url="http://testserver",
            ) as client:
                response = await client.post(
                    "/api/auth/login",
                    content=request.SerializeToString(),
                    headers={"Content-Type": "application/x-protobuf"},
                )

        self.assertEqual(response.status_code, 200)

        async with db.async_session_maker() as session:
            result = await session.execute(
                select(db.User).where(db.User.sub == claims["sub"])
            )
            user = result.scalar_one()

        self.assertEqual(user.email, claims["email"])
        self.assertEqual(user.name, claims["name"])
        self.assertEqual(user.avatar_url, claims["picture"])


class TestDataSeedTests(AsyncDatabaseTestCase):
    async def test_seed_test_data_uses_first_user_and_is_idempotent(self) -> None:
        first_user = await self._create_user(
            "auth0|first",
            "first@example.com",
            "First User",
        )

        await seed_test_data.seed_test_data()
        await seed_test_data.seed_test_data()

        async with db.async_session_maker() as session:
            users = await db.search_users_by_prefix(
                session,
                "ali",
                exclude_user_id=0,
            )
            recipients = await session.execute(
                select(db.Recipient).where(db.Recipient.name == "Demo household")
            )
            receipts = await session.execute(
                select(db.Receipt)
                .where(db.Receipt.title == "Demo rent top-up")
                .options(selectinload(db.Receipt.recipient_shares), selectinload(db.Receipt.tags))
            )

        self.assertEqual([user.email for user in users], ["alice.demo@example.com"])
        recipient = recipients.scalar_one_or_none()
        receipt = receipts.scalar_one_or_none()
        self.assertIsNotNone(recipient)
        self.assertIsNotNone(receipt)
        self.assertEqual(recipient.owner_id, first_user.id)
        self.assertEqual(receipt.owner_id, first_user.id)
        self.assertEqual(receipt.owner_share_percent, 40.0)
        self.assertEqual(len(receipt.recipient_shares), 2)
        self.assertEqual([(tag.icon, tag.text) for tag in receipt.tags], [("🏠", "Rent")])


class ReceiptAndFileAuthorizationTests(AsyncDatabaseTestCase):
    async def asyncSetUp(self) -> None:
        await super().asyncSetUp()

        self.owner = await self._create_user("auth0|owner", "owner@example.com", "Owner")
        self.member = await self._create_user(
            "auth0|member", "member@example.com", "Member"
        )
        self.stranger = await self._create_user(
            "auth0|stranger", "stranger@example.com", "Stranger"
        )

        async with db.async_session_maker() as session:
            recipient = await db.create_recipient(
                session=session,
                owner_id=self.owner.id,
                name="Shared Group",
                description=None,
                member_ids=[self.member.id],
            )
            self.receipt = await db.create_receipt(
                session=session,
                owner_id=self.owner.id,
                title="Shared Receipt",
                amount_owed=42.0,
                recipient_id=recipient.id,
            )
            await session.commit()

    async def test_receipt_visibility_allows_owner_and_member_only(self) -> None:
        async with db.async_session_maker() as session:
            owner_receipt = await services.get_visible_receipt(
                session, self.owner.id, self.receipt.id
            )
            member_receipt = await services.get_visible_receipt(
                session, self.member.id, self.receipt.id
            )

            with self.assertRaises(services.ResourceNotFoundError):
                await services.get_visible_receipt(
                    session, self.stranger.id, self.receipt.id
                )

        self.assertEqual(owner_receipt.id, self.receipt.id)
        self.assertEqual(member_receipt.id, self.receipt.id)

    async def test_receipt_mutation_is_owner_only(self) -> None:
        async with db.async_session_maker() as session:
            updated = await services.update_receipt_for_owner(
                session,
                self.owner.id,
                self.receipt.id,
                title="Updated Title",
            )
            await session.commit()

        self.assertEqual(updated.title, "Updated Title")

        async with db.async_session_maker() as session:
            with self.assertRaises(services.AuthorizationError):
                await services.update_receipt_for_owner(
                    session,
                    self.member.id,
                    self.receipt.id,
                    title="Member Cannot Edit",
                )

            with self.assertRaises(services.AuthorizationError):
                await services.mark_receipt_paid_for_owner(
                    session,
                    self.member.id,
                    self.receipt.id,
                    amount_paid=42.0,
                )

    async def test_file_keys_are_server_generated_and_access_checks_follow_receipt(self) -> None:
        async with db.async_session_maker() as session:
            file_record = await services.create_receipt_file_for_owner(
                session=session,
                actor_user_id=self.owner.id,
                receipt_id=self.receipt.id,
                client_filename=r"..\..\Quarterly Report?.pdf",
                content_type="application/pdf",
            )
            await session.commit()

        self.assertTrue(file_record.storage_key.startswith(f"{self.receipt.id}/"))
        self.assertNotIn("Quarterly", file_record.storage_key)
        self.assertNotIn("..", file_record.storage_key)
        self.assertNotIn("\\", file_record.storage_key)
        self.assertEqual(file_record.original_filename, "Quarterly Report_.pdf")

        safe_path = resolve_storage_path(file_record.storage_key, self._tmpdir.name)
        self.assertTrue(str(safe_path).startswith(self._tmpdir.name))

        with self.assertRaises(ValueError):
            resolve_storage_path("../escape", self._tmpdir.name)

        async with db.async_session_maker() as session:
            visible_to_member = await services.get_file_for_actor(
                session, self.member.id, file_record.id
            )
            self.assertEqual(visible_to_member.id, file_record.id)

            with self.assertRaises(services.ResourceNotFoundError):
                await services.get_file_for_actor(
                    session, self.stranger.id, file_record.id
                )

            with self.assertRaises(services.AuthorizationError):
                await services.delete_file_for_owner(
                    session, self.member.id, file_record.id
                )


class ReceiptSplitTests(AsyncDatabaseTestCase):
    async def asyncSetUp(self) -> None:
        await super().asyncSetUp()

        self.owner = await self._create_user("auth0|owner", "owner@example.com", "Owner")
        self.member_a = await self._create_user(
            "auth0|member-a", "member-a@example.com", "Member A"
        )
        self.member_b = await self._create_user(
            "auth0|member-b", "member-b@example.com", "Member B"
        )
        self.stranger = await self._create_user(
            "auth0|stranger", "stranger@example.com", "Stranger"
        )

        async with db.async_session_maker() as session:
            self.recipient = await db.create_recipient(
                session=session,
                owner_id=self.owner.id,
                name="Split Group",
                description=None,
                member_ids=[self.member_a.id, self.member_b.id],
            )
            await session.commit()

        self._claims_by_token = {
            "owner-token": {"sub": self.owner.sub},
            "member-a-token": {"sub": self.member_a.sub},
            "member-b-token": {"sub": self.member_b.sub},
            "stranger-token": {"sub": self.stranger.sub},
        }

    async def _post_protobuf(self, path: str, message, token: str):
        async def verify_side_effect(access_token: str):
            return self._claims_by_token[access_token]

        transport = ASGITransport(app=main.app)
        async with AsyncClient(transport=transport, base_url="http://testserver") as client:
            with patch("backend.auth.verify_token", new=AsyncMock(side_effect=verify_side_effect)):
                return await client.post(
                    path,
                    content=message.SerializeToString(),
                    headers={
                        "Content-Type": "application/x-protobuf",
                        "Authorization": f"Bearer {token}",
                    },
                )

    def _parse_message(self, message_cls, response) -> object:
        message = message_cls()
        message.ParseFromString(response.content)
        return message

    def _create_receipt_request_with_split(self) -> debt_pb2.CreateReceiptRequest:
        request = debt_pb2.CreateReceiptRequest(
            title="Dinner",
            amount_owed=100.0,
            recipient_id=self.recipient.id,
        )
        request.split.owner_share_percent = 30.0
        request.split.recipient_shares.add(
            user_id=self.member_a.id,
            share_percent=30.0,
        )
        request.split.recipient_shares.add(
            user_id=self.member_b.id,
            share_percent=40.0,
        )
        return request

    async def test_create_receipt_with_split_persists_and_returns_computed_amounts(self) -> None:
        response = await self._post_protobuf(
            "/api/receipts/create",
            self._create_receipt_request_with_split(),
            "owner-token",
        )
        parsed = self._parse_message(debt_pb2.ReceiptResponse, response)

        self.assertEqual(response.status_code, 200)
        self.assertTrue(parsed.success)
        self.assertTrue(parsed.receipt.HasField("split"))
        self.assertEqual(parsed.receipt.split.owner_share_percent, 30.0)
        self.assertEqual(parsed.receipt.split.owner_amount, 30.0)
        self.assertEqual(
            {
                (share.user_id, share.share_percent, share.amount, share.user_name)
                for share in parsed.receipt.split.recipient_shares
            },
            {
                (self.member_a.id, 30.0, 30.0, "Member A"),
                (self.member_b.id, 40.0, 40.0, "Member B"),
            },
        )

        async with db.async_session_maker() as session:
            receipt = await db.get_receipt_by_id(session, parsed.receipt.id)

        self.assertIsNotNone(receipt)
        self.assertEqual(receipt.owner_share_percent, 30.0)
        self.assertEqual(
            {(share.user_id, share.share_percent) for share in receipt.recipient_shares},
            {(self.member_a.id, 30.0), (self.member_b.id, 40.0)},
        )

    async def test_create_receipt_rejects_split_total_not_equal_to_100(self) -> None:
        request = self._create_receipt_request_with_split()
        request.split.recipient_shares[1].share_percent = 30.0

        response = await self._post_protobuf(
            "/api/receipts/create",
            request,
            "owner-token",
        )
        parsed = self._parse_message(debt_pb2.ReceiptResponse, response)

        self.assertEqual(response.status_code, 400)
        self.assertFalse(parsed.success)
        self.assertIn("sum to 100", parsed.message)

    async def test_set_receipt_split_rejects_duplicate_and_non_member_users(self) -> None:
        async with db.async_session_maker() as session:
            receipt = await db.create_receipt(
                session=session,
                owner_id=self.owner.id,
                title="Dinner",
                amount_owed=100.0,
                recipient_id=self.recipient.id,
            )
            await session.flush()

            with self.assertRaisesRegex(ValueError, "Duplicate split user"):
                await db.set_receipt_split(
                    session=session,
                    receipt_id=receipt.id,
                    owner_share_percent=40.0,
                    recipient_shares=[
                        (self.member_a.id, 30.0),
                        (self.member_a.id, 30.0),
                    ],
                )

            with self.assertRaisesRegex(ValueError, "current members"):
                await db.set_receipt_split(
                    session=session,
                    receipt_id=receipt.id,
                    owner_share_percent=50.0,
                    recipient_shares=[(self.stranger.id, 50.0)],
                )

    async def test_delete_user_preserves_split_rows_and_snapshots(self) -> None:
        async with db.async_session_maker() as session:
            receipt = await db.create_receipt(
                session=session,
                owner_id=self.owner.id,
                title="Dinner",
                amount_owed=100.0,
                recipient_id=self.recipient.id,
            )
            await db.set_receipt_split(
                session=session,
                receipt_id=receipt.id,
                owner_share_percent=25.0,
                recipient_shares=[(self.member_a.id, 75.0)],
            )
            await session.commit()

        async with db.async_session_maker() as session:
            deleted_storage_keys = await db.delete_user(session, self.member_a.id)
            await session.commit()

        self.assertEqual(deleted_storage_keys, [])

        async with db.async_session_maker() as session:
            stored = await db.get_receipt_by_id(session, receipt.id)

        self.assertIsNotNone(stored)
        self.assertEqual(stored.owner_share_percent, 25.0)
        self.assertEqual(
            [
                (
                    share.user_id,
                    share.share_percent,
                    share.user_name_snapshot,
                    share.user_email_snapshot,
                )
                for share in stored.recipient_shares
            ],
            [(self.member_a.id, 75.0, "Member A", "member-a@example.com")],
        )

        response = await self._post_protobuf(
            "/api/receipts/get",
            debt_pb2.ReceiptLookupRequest(receipt_id=receipt.id),
            "owner-token",
        )
        parsed = self._parse_message(debt_pb2.ReceiptResponse, response)

        self.assertEqual(response.status_code, 200)
        self.assertTrue(parsed.success)
        self.assertTrue(parsed.receipt.HasField("split"))
        self.assertEqual(parsed.receipt.split.owner_share_percent, 25.0)
        self.assertEqual(
            [
                (
                    share.user_id,
                    share.share_percent,
                    share.user_name,
                    share.user_email,
                )
                for share in parsed.receipt.split.recipient_shares
            ],
            [(self.member_a.id, 75.0, "Member A", "member-a@example.com")],
        )

    async def test_update_receipt_split_fully_replaces_old_rows(self) -> None:
        async with db.async_session_maker() as session:
            receipt = await db.create_receipt(
                session=session,
                owner_id=self.owner.id,
                title="Dinner",
                amount_owed=100.0,
                recipient_id=self.recipient.id,
            )
            await db.set_receipt_split(
                session=session,
                receipt_id=receipt.id,
                owner_share_percent=30.0,
                recipient_shares=[(self.member_a.id, 70.0)],
            )
            await session.commit()

        request = debt_pb2.UpdateReceiptRequest(
            receipt_id=receipt.id,
            amount_owed=200.0,
        )
        request.split.owner_share_percent = 50.0
        request.split.recipient_shares.add(
            user_id=self.member_b.id,
            share_percent=50.0,
        )

        response = await self._post_protobuf(
            "/api/receipts/update",
            request,
            "owner-token",
        )
        parsed = self._parse_message(debt_pb2.ReceiptResponse, response)

        self.assertEqual(response.status_code, 200)
        self.assertTrue(parsed.success)
        self.assertEqual(parsed.receipt.split.owner_amount, 100.0)
        self.assertEqual(len(parsed.receipt.split.recipient_shares), 1)
        self.assertEqual(parsed.receipt.split.recipient_shares[0].user_id, self.member_b.id)
        self.assertEqual(parsed.receipt.split.recipient_shares[0].amount, 100.0)

        async with db.async_session_maker() as session:
            stored = await db.get_receipt_by_id(session, receipt.id)

        self.assertEqual(stored.owner_share_percent, 50.0)
        self.assertEqual(
            [(share.user_id, share.share_percent) for share in stored.recipient_shares],
            [(self.member_b.id, 50.0)],
        )

    async def test_update_receipt_with_clear_split_removes_saved_split(self) -> None:
        async with db.async_session_maker() as session:
            receipt = await db.create_receipt(
                session=session,
                owner_id=self.owner.id,
                title="Dinner",
                amount_owed=100.0,
                recipient_id=self.recipient.id,
            )
            await db.set_receipt_split(
                session=session,
                receipt_id=receipt.id,
                owner_share_percent=25.0,
                recipient_shares=[(self.member_a.id, 75.0)],
            )
            await session.commit()

        response = await self._post_protobuf(
            "/api/receipts/update",
            debt_pb2.UpdateReceiptRequest(
                receipt_id=receipt.id,
                clear_split=True,
            ),
            "owner-token",
        )
        parsed = self._parse_message(debt_pb2.ReceiptResponse, response)

        self.assertEqual(response.status_code, 200)
        self.assertTrue(parsed.success)
        self.assertFalse(parsed.receipt.HasField("split"))

        async with db.async_session_maker() as session:
            stored = await db.get_receipt_by_id(session, receipt.id)

        self.assertIsNone(stored.owner_share_percent)
        self.assertEqual(stored.recipient_shares, [])

    async def test_update_receipt_clear_split_is_noop_when_split_missing(self) -> None:
        async with db.async_session_maker() as session:
            receipt = await db.create_receipt(
                session=session,
                owner_id=self.owner.id,
                title="Dinner",
                amount_owed=100.0,
                recipient_id=self.recipient.id,
            )
            await session.commit()

        response = await self._post_protobuf(
            "/api/receipts/update",
            debt_pb2.UpdateReceiptRequest(
                receipt_id=receipt.id,
                clear_split=True,
            ),
            "owner-token",
        )
        parsed = self._parse_message(debt_pb2.ReceiptResponse, response)

        self.assertEqual(response.status_code, 200)
        self.assertTrue(parsed.success)
        self.assertFalse(parsed.receipt.HasField("split"))

        async with db.async_session_maker() as session:
            stored = await db.get_receipt_by_id(session, receipt.id)

        self.assertIsNone(stored.owner_share_percent)
        self.assertEqual(stored.recipient_shares, [])

    async def test_update_receipt_rejects_split_and_clear_split_together(self) -> None:
        async with db.async_session_maker() as session:
            receipt = await db.create_receipt(
                session=session,
                owner_id=self.owner.id,
                title="Dinner",
                amount_owed=100.0,
                recipient_id=self.recipient.id,
            )
            await db.set_receipt_split(
                session=session,
                receipt_id=receipt.id,
                owner_share_percent=30.0,
                recipient_shares=[(self.member_a.id, 70.0)],
            )
            await session.commit()

        request = debt_pb2.UpdateReceiptRequest(
            receipt_id=receipt.id,
            clear_split=True,
        )
        request.split.owner_share_percent = 50.0
        request.split.recipient_shares.add(
            user_id=self.member_b.id,
            share_percent=50.0,
        )

        response = await self._post_protobuf(
            "/api/receipts/update",
            request,
            "owner-token",
        )
        parsed = self._parse_message(debt_pb2.ReceiptResponse, response)

        self.assertEqual(response.status_code, 400)
        self.assertFalse(parsed.success)
        self.assertIn("clear_split", parsed.message)

        async with db.async_session_maker() as session:
            stored = await db.get_receipt_by_id(session, receipt.id)

        self.assertEqual(stored.owner_share_percent, 30.0)
        self.assertEqual(
            [(share.user_id, share.share_percent) for share in stored.recipient_shares],
            [(self.member_a.id, 70.0)],
        )

    async def test_no_split_receipt_create_get_and_list_stays_legacy_shape(self) -> None:
        create_response = await self._post_protobuf(
            "/api/receipts/create",
            debt_pb2.CreateReceiptRequest(
                title="No Split",
                amount_owed=25.0,
                recipient_id=self.recipient.id,
            ),
            "owner-token",
        )
        created = self._parse_message(debt_pb2.ReceiptResponse, create_response)

        self.assertEqual(create_response.status_code, 200)
        self.assertFalse(created.receipt.HasField("split"))

        get_response = await self._post_protobuf(
            "/api/receipts/get",
            debt_pb2.ReceiptLookupRequest(receipt_id=created.receipt.id),
            "member-a-token",
        )
        got = self._parse_message(debt_pb2.ReceiptResponse, get_response)

        self.assertEqual(get_response.status_code, 200)
        self.assertTrue(got.success)
        self.assertFalse(got.receipt.HasField("split"))

        list_response = await self._post_protobuf(
            "/api/receipts/list",
            debt_pb2.ReceiptListRequest(),
            "member-a-token",
        )
        listed = self._parse_message(debt_pb2.ReceiptsResponse, list_response)

        self.assertEqual(list_response.status_code, 200)
        self.assertTrue(listed.success)
        self.assertIn(created.receipt.id, {receipt.id for receipt in listed.receipts})


class LiveApiRegressionTests(AsyncDatabaseTestCase):
    async def asyncSetUp(self) -> None:
        await super().asyncSetUp()

        self.owner = await self._create_user("auth0|owner", "owner@example.com", "Owner")
        self.member = await self._create_user(
            "auth0|member", "member@example.com", "Member"
        )
        self.stranger = await self._create_user(
            "auth0|stranger", "stranger@example.com", "Stranger"
        )

        async with db.async_session_maker() as session:
            self.recipient = await db.create_recipient(
                session=session,
                owner_id=self.owner.id,
                name="Shared Group",
                description=None,
                member_ids=[self.member.id],
            )
            self.shared_receipt = await db.create_receipt(
                session=session,
                owner_id=self.owner.id,
                title="Shared Receipt",
                amount_owed=42.0,
                recipient_id=self.recipient.id,
            )
            self.member_receipt = await db.create_receipt(
                session=session,
                owner_id=self.member.id,
                title="Member Receipt",
                amount_owed=11.0,
            )
            self.shared_file = await services.create_receipt_file_for_owner(
                session=session,
                actor_user_id=self.owner.id,
                receipt_id=self.shared_receipt.id,
                client_filename="invoice.pdf",
            )
            await session.commit()

        self._claims_by_token = {
            "owner-token": {"sub": self.owner.sub},
            "member-token": {"sub": self.member.sub},
            "stranger-token": {"sub": self.stranger.sub},
            "unknown-token": {"sub": "auth0|unknown"},
        }

    async def _post_protobuf(self, path: str, message, token: str):
        async def verify_side_effect(access_token: str):
            return self._claims_by_token[access_token]

        transport = ASGITransport(app=main.app)
        async with AsyncClient(transport=transport, base_url="http://testserver") as client:
            with patch("backend.auth.verify_token", new=AsyncMock(side_effect=verify_side_effect)):
                return await client.post(
                    path,
                    content=message.SerializeToString(),
                    headers={
                        "Content-Type": "application/x-protobuf",
                        "Authorization": f"Bearer {token}",
                    },
                )

    def _parse_message(self, message_cls, response) -> object:
        message = message_cls()
        message.ParseFromString(response.content)
        return message

    async def test_users_me_rejects_unknown_subject_without_creating_user(self) -> None:
        response = await self._post_protobuf("/api/users/me", debt_pb2.EmptyRequest(), "unknown-token")
        parsed = self._parse_message(debt_pb2.UserResponse, response)

        self.assertEqual(response.status_code, 401)
        self.assertFalse(parsed.success)

        async with db.async_session_maker() as session:
            result = await session.execute(
                select(db.User).where(db.User.sub == "auth0|unknown")
            )
            self.assertIsNone(result.scalar_one_or_none())

    async def test_users_search_requires_auth(self) -> None:
        transport = ASGITransport(app=main.app)
        async with AsyncClient(transport=transport, base_url="http://testserver") as client:
            response = await client.post(
                "/api/users/search",
                content=debt_pb2.UserSearchRequest(query="mem").SerializeToString(),
                headers={"Content-Type": "application/x-protobuf"},
            )
        parsed = self._parse_message(debt_pb2.UsersResponse, response)

        self.assertEqual(response.status_code, 401)
        self.assertFalse(parsed.success)

    async def test_users_search_rejects_short_query(self) -> None:
        response = await self._post_protobuf(
            "/api/users/search",
            debt_pb2.UserSearchRequest(query="me"),
            "owner-token",
        )
        parsed = self._parse_message(debt_pb2.UsersResponse, response)

        self.assertEqual(response.status_code, 400)
        self.assertFalse(parsed.success)
        self.assertIn("at least 3 characters", parsed.message)

    async def test_users_search_matches_prefix_and_excludes_current_user(self) -> None:
        async with db.async_session_maker() as session:
            await db.get_or_create_user(
                session=session,
                sub="auth0|member-two",
                email="member.two@example.com",
                name="Member Two",
                avatar_url=None,
            )
            await db.get_or_create_user(
                session=session,
                sub="auth0|other",
                email="other@example.com",
                name="Other",
                avatar_url=None,
            )
            await session.commit()

        response = await self._post_protobuf(
            "/api/users/search",
            debt_pb2.UserSearchRequest(query="mem", limit=10),
            "owner-token",
        )
        parsed = self._parse_message(debt_pb2.UsersResponse, response)

        self.assertEqual(response.status_code, 200)
        self.assertTrue(parsed.success)
        self.assertEqual(
            [user.email for user in parsed.users],
            ["member@example.com", "member.two@example.com"],
        )
        self.assertNotIn(self.owner.id, [user.id for user in parsed.users])

    async def test_users_search_respects_limit_cap(self) -> None:
        async with db.async_session_maker() as session:
            for index in range(12):
                await db.get_or_create_user(
                    session=session,
                    sub=f"auth0|prefix-{index}",
                    email=f"prefix-{index}@example.com",
                    name=f"Prefix {index}",
                    avatar_url=None,
                )
            await session.commit()

        response = await self._post_protobuf(
            "/api/users/search",
            debt_pb2.UserSearchRequest(query="pre", limit=99),
            "owner-token",
        )
        parsed = self._parse_message(debt_pb2.UsersResponse, response)

        self.assertEqual(response.status_code, 200)
        self.assertTrue(parsed.success)
        self.assertEqual(len(parsed.users), 10)

    async def test_receipts_get_allows_recipient_member(self) -> None:
        response = await self._post_protobuf(
            "/api/receipts/get",
            debt_pb2.ReceiptLookupRequest(receipt_id=self.shared_receipt.id),
            "member-token",
        )
        parsed = self._parse_message(debt_pb2.ReceiptResponse, response)

        self.assertEqual(response.status_code, 200)
        self.assertTrue(parsed.success)
        self.assertEqual(parsed.receipt.id, self.shared_receipt.id)

    async def test_receipts_list_includes_owned_and_member_visible_receipts(self) -> None:
        response = await self._post_protobuf(
            "/api/receipts/list",
            debt_pb2.ReceiptListRequest(),
            "member-token",
        )
        parsed = self._parse_message(debt_pb2.ReceiptsResponse, response)

        self.assertEqual(response.status_code, 200)
        self.assertTrue(parsed.success)
        self.assertEqual(
            {receipt.id for receipt in parsed.receipts},
            {self.shared_receipt.id, self.member_receipt.id},
        )

    async def test_files_get_allows_recipient_member(self) -> None:
        response = await self._post_protobuf(
            "/api/files/get",
            debt_pb2.FileLookupRequest(file_id=self.shared_file.id),
            "member-token",
        )
        parsed = self._parse_message(debt_pb2.FileResponse, response)

        self.assertEqual(response.status_code, 200)
        self.assertTrue(parsed.success)
        self.assertEqual(parsed.file.id, self.shared_file.id)

    async def test_files_list_allows_recipient_member(self) -> None:
        response = await self._post_protobuf(
            "/api/files/list",
            debt_pb2.FileListRequest(receipt_id=self.shared_receipt.id),
            "member-token",
        )
        parsed = self._parse_message(debt_pb2.FilesResponse, response)

        self.assertEqual(response.status_code, 200)
        self.assertTrue(parsed.success)
        self.assertEqual([file.id for file in parsed.files], [self.shared_file.id])

    async def test_files_attach_sanitizes_persisted_and_echoed_filename(self) -> None:
        response = await self._post_protobuf(
            "/api/files/attach",
            debt_pb2.ReceiptFileRequest(
                receipt_id=self.shared_receipt.id,
                original_filename=r"..\..\Quarterly Report?.pdf",
            ),
            "owner-token",
        )
        parsed = self._parse_message(debt_pb2.FileResponse, response)

        self.assertEqual(response.status_code, 200)
        self.assertTrue(parsed.success)
        self.assertEqual(parsed.file.original_filename, "Quarterly Report_.pdf")

        async with db.async_session_maker() as session:
            stored = await session.get(db.ReceiptFile, parsed.file.id)

        self.assertIsNotNone(stored)
        self.assertEqual(stored.original_filename, "Quarterly Report_.pdf")

    async def test_recipient_member_routes_are_owner_only(self) -> None:
        owner_response = await self._post_protobuf(
            "/api/recipients/add-member",
            debt_pb2.RecipientMemberRequest(
                recipient_id=self.recipient.id,
                user_id=self.stranger.id,
            ),
            "owner-token",
        )
        owner_parsed = self._parse_message(debt_pb2.ActionResponse, owner_response)

        self.assertEqual(owner_response.status_code, 200)
        self.assertTrue(owner_parsed.success)

        member_response = await self._post_protobuf(
            "/api/recipients/remove-member",
            debt_pb2.RecipientMemberRequest(
                recipient_id=self.recipient.id,
                user_id=self.stranger.id,
            ),
            "member-token",
        )
        member_parsed = self._parse_message(debt_pb2.ActionResponse, member_response)

        self.assertEqual(member_response.status_code, 403)
        self.assertFalse(member_parsed.success)


class ReceiptListOrderingAndFilterTests(AsyncDatabaseTestCase):
    async def asyncSetUp(self) -> None:
        await super().asyncSetUp()

        self.owner = await self._create_user("auth0|owner", "owner@example.com", "Owner")
        self.member_a = await self._create_user(
            "auth0|member-a", "member-a@example.com", "Member A"
        )
        self.member_b = await self._create_user(
            "auth0|member-b", "member-b@example.com", "Member B"
        )
        self.stranger = await self._create_user(
            "auth0|stranger", "stranger@example.com", "Stranger"
        )

        async with db.async_session_maker() as session:
            self.recipient = await db.create_recipient(
                session=session,
                owner_id=self.owner.id,
                name="Sorting Group",
                description=None,
                member_ids=[self.member_a.id, self.member_b.id],
            )

            due_base = datetime(2026, 1, 1, tzinfo=timezone.utc)
            self.owner_unpaid = await db.create_receipt(
                session=session,
                owner_id=self.owner.id,
                title="Owner Unpaid",
                amount_owed=50.0,
                due_date=due_base + timedelta(days=2),
            )
            self.shared_with_split = await db.create_receipt(
                session=session,
                owner_id=self.owner.id,
                title="Shared Split",
                amount_owed=90.0,
                recipient_id=self.recipient.id,
                due_date=due_base + timedelta(days=1),
            )
            self.shared_without_member_share = await db.create_receipt(
                session=session,
                owner_id=self.owner.id,
                title="Shared No Member Share",
                amount_owed=120.0,
                recipient_id=self.recipient.id,
                due_date=None,
            )
            self.member_owned_paid = await db.create_receipt(
                session=session,
                owner_id=self.member_a.id,
                title="Member Paid",
                amount_owed=30.0,
                due_date=due_base + timedelta(days=3),
            )
            self.member_owned_large = await db.create_receipt(
                session=session,
                owner_id=self.member_a.id,
                title="Member Large",
                amount_owed=120.0,
                due_date=due_base + timedelta(days=4),
            )
            self.tie_low_id = await db.create_receipt(
                session=session,
                owner_id=self.member_a.id,
                title="Tie Low Id",
                amount_owed=77.0,
                due_date=due_base + timedelta(days=5),
            )
            self.tie_high_id = await db.create_receipt(
                session=session,
                owner_id=self.member_a.id,
                title="Tie High Id",
                amount_owed=77.0,
                due_date=due_base + timedelta(days=6),
            )
            self.stranger_receipt = await db.create_receipt(
                session=session,
                owner_id=self.stranger.id,
                title="Stranger Receipt",
                amount_owed=999.0,
                due_date=due_base + timedelta(days=7),
            )

            await db.set_receipt_split(
                session=session,
                receipt_id=self.shared_with_split.id,
                owner_share_percent=50.0,
                recipient_shares=[
                    (self.member_a.id, 20.0),
                    (self.member_b.id, 30.0),
                ],
            )
            await db.set_receipt_split(
                session=session,
                receipt_id=self.shared_without_member_share.id,
                owner_share_percent=100.0,
                recipient_shares=[],
            )
            await db.mark_receipt_paid(
                session=session,
                receipt_id=self.member_owned_paid.id,
                amount_paid=30.0,
            )

            tag_shared = await db.get_or_create_tag(
                session=session,
                text="shared",
                icon="s",
                color="#111111",
            )
            tag_urgent = await db.get_or_create_tag(
                session=session,
                text="urgent",
                icon="u",
                color="#222222",
            )
            tag_personal = await db.get_or_create_tag(
                session=session,
                text="personal",
                icon="p",
                color="#333333",
            )
            self.shared_tag_id = tag_shared.id
            self.urgent_tag_id = tag_urgent.id
            self.personal_tag_id = tag_personal.id

            await db.set_receipt_tags(
                session,
                self.shared_with_split.id,
                [self.shared_tag_id, self.urgent_tag_id],
            )
            await db.set_receipt_tags(
                session,
                self.shared_without_member_share.id,
                [self.shared_tag_id],
            )
            await db.set_receipt_tags(
                session,
                self.member_owned_paid.id,
                [self.personal_tag_id],
            )

            await session.commit()

        self._claims_by_token = {
            "owner-token": {"sub": self.owner.sub},
            "member-a-token": {"sub": self.member_a.sub},
            "member-b-token": {"sub": self.member_b.sub},
            "stranger-token": {"sub": self.stranger.sub},
        }

    async def _post_protobuf(self, path: str, message, token: str):
        async def verify_side_effect(access_token: str):
            return self._claims_by_token[access_token]

        transport = ASGITransport(app=main.app)
        async with AsyncClient(transport=transport, base_url="http://testserver") as client:
            with patch("backend.auth.verify_token", new=AsyncMock(side_effect=verify_side_effect)):
                return await client.post(
                    path,
                    content=message.SerializeToString(),
                    headers={
                        "Content-Type": "application/x-protobuf",
                        "Authorization": f"Bearer {token}",
                    },
                )

    def _parse_message(self, message_cls, response) -> object:
        message = message_cls()
        message.ParseFromString(response.content)
        return message

    async def _list_receipts_response(self, token: str, **kwargs):
        response = await self._post_protobuf(
            "/api/receipts/list",
            debt_pb2.ReceiptListRequest(**kwargs),
            token,
        )
        parsed = self._parse_message(debt_pb2.ReceiptsResponse, response)
        self.assertEqual(response.status_code, 200)
        self.assertTrue(parsed.success)
        return parsed

    async def _list_receipts(self, token: str, **kwargs) -> list[int]:
        parsed = await self._list_receipts_response(token, **kwargs)
        return [receipt.id for receipt in parsed.receipts]

    async def _collect_page_token_ids(self, token: str, **kwargs) -> list[int]:
        ids: list[int] = []
        next_page_token: str | None = None

        while True:
            request_kwargs = dict(kwargs)
            if next_page_token is not None:
                request_kwargs["page_token"] = next_page_token

            parsed = await self._list_receipts_response(token, **request_kwargs)
            ids.extend(receipt.id for receipt in parsed.receipts)

            if not parsed.HasField("next_page_token"):
                break
            next_page_token = parsed.next_page_token

        return ids

    async def test_receipts_list_filters_paid_true(self) -> None:
        ids = await self._list_receipts("member-a-token", is_paid=True)
        self.assertEqual(ids, [self.member_owned_paid.id])

    async def test_receipts_list_filters_paid_false(self) -> None:
        ids = await self._list_receipts("member-a-token", is_paid=False)
        self.assertNotIn(self.member_owned_paid.id, ids)
        self.assertEqual(
            set(ids),
            {
                self.shared_with_split.id,
                self.shared_without_member_share.id,
                self.member_owned_large.id,
                self.tie_low_id.id,
                self.tie_high_id.id,
            },
        )

    async def test_receipts_list_filters_by_all_tag_ids(self) -> None:
        ids = await self._list_receipts(
            "member-a-token",
            tag_ids=[self.shared_tag_id, self.urgent_tag_id],
        )
        self.assertEqual(ids, [self.shared_with_split.id])

    async def test_receipts_list_cursor_paginates_id_ascending(self) -> None:
        ids = await self._list_receipts(
            "member-a-token",
            cursor=self.member_owned_paid.id,
            order_by=debt_pb2.RECEIPT_ORDER_BY_ID,
            order_direction=debt_pb2.RECEIPT_ORDER_DIRECTION_ASC,
        )
        self.assertTrue(all(receipt_id > self.member_owned_paid.id for receipt_id in ids))

    async def test_receipts_list_cursor_paginates_id_descending(self) -> None:
        ids = await self._list_receipts(
            "member-a-token",
            cursor=self.tie_high_id.id,
            order_by=debt_pb2.RECEIPT_ORDER_BY_ID,
            order_direction=debt_pb2.RECEIPT_ORDER_DIRECTION_DESC,
        )
        self.assertTrue(all(receipt_id < self.tie_high_id.id for receipt_id in ids))

    async def test_receipts_list_rejects_cursor_for_non_id_sort(self) -> None:
        response = await self._post_protobuf(
            "/api/receipts/list",
            debt_pb2.ReceiptListRequest(
                cursor=self.shared_with_split.id,
                order_by=debt_pb2.RECEIPT_ORDER_BY_COST_TOTAL,
                order_direction=debt_pb2.RECEIPT_ORDER_DIRECTION_DESC,
            ),
            "member-a-token",
        )
        parsed = self._parse_message(debt_pb2.ReceiptsResponse, response)

        self.assertEqual(response.status_code, 400)
        self.assertFalse(parsed.success)
        self.assertIn("cursor pagination is only supported", parsed.message)

    async def test_receipts_list_page_token_paginates_id_sort(self) -> None:
        ids = await self._collect_page_token_ids(
            "member-a-token",
            limit=2,
            order_by=debt_pb2.RECEIPT_ORDER_BY_ID,
            order_direction=debt_pb2.RECEIPT_ORDER_DIRECTION_DESC,
        )
        self.assertEqual(ids, sorted(ids, reverse=True))

    async def test_receipts_list_page_token_paginates_cost_total_sort(self) -> None:
        ids = await self._collect_page_token_ids(
            "member-a-token",
            limit=2,
            order_by=debt_pb2.RECEIPT_ORDER_BY_COST_TOTAL,
            order_direction=debt_pb2.RECEIPT_ORDER_DIRECTION_ASC,
        )
        self.assertEqual(
            ids,
            [
                self.member_owned_paid.id,
                self.tie_low_id.id,
                self.tie_high_id.id,
                self.shared_with_split.id,
                self.shared_without_member_share.id,
                self.member_owned_large.id,
            ],
        )

    async def test_receipts_list_page_token_paginates_due_date_sort(self) -> None:
        ids = await self._collect_page_token_ids(
            "member-a-token",
            limit=2,
            order_by=debt_pb2.RECEIPT_ORDER_BY_DUE_DATE,
            order_direction=debt_pb2.RECEIPT_ORDER_DIRECTION_ASC,
        )
        self.assertEqual(
            ids,
            [
                self.shared_with_split.id,
                self.member_owned_paid.id,
                self.member_owned_large.id,
                self.tie_low_id.id,
                self.tie_high_id.id,
                self.shared_without_member_share.id,
            ],
        )

    async def test_receipts_list_page_token_paginates_cost_for_user_sort(self) -> None:
        ids = await self._collect_page_token_ids(
            "member-a-token",
            limit=2,
            order_by=debt_pb2.RECEIPT_ORDER_BY_COST_FOR_USER,
            order_direction=debt_pb2.RECEIPT_ORDER_DIRECTION_ASC,
        )
        self.assertEqual(
            ids,
            [
                self.shared_without_member_share.id,
                self.shared_with_split.id,
                self.member_owned_paid.id,
                self.tie_low_id.id,
                self.tie_high_id.id,
                self.member_owned_large.id,
            ],
        )

    async def test_receipts_list_rejects_malformed_page_token(self) -> None:
        response = await self._post_protobuf(
            "/api/receipts/list",
            debt_pb2.ReceiptListRequest(
                page_token="not-valid-base64",
                order_by=debt_pb2.RECEIPT_ORDER_BY_ID,
                order_direction=debt_pb2.RECEIPT_ORDER_DIRECTION_DESC,
            ),
            "member-a-token",
        )
        parsed = self._parse_message(debt_pb2.ReceiptsResponse, response)

        self.assertEqual(response.status_code, 400)
        self.assertFalse(parsed.success)
        self.assertIn("Invalid page token", parsed.message)

    async def test_receipts_list_rejects_mismatched_page_token(self) -> None:
        first_page = await self._list_receipts_response(
            "member-a-token",
            limit=2,
            order_by=debt_pb2.RECEIPT_ORDER_BY_COST_TOTAL,
            order_direction=debt_pb2.RECEIPT_ORDER_DIRECTION_ASC,
        )

        response = await self._post_protobuf(
            "/api/receipts/list",
            debt_pb2.ReceiptListRequest(
                limit=2,
                page_token=first_page.next_page_token,
                order_by=debt_pb2.RECEIPT_ORDER_BY_DUE_DATE,
                order_direction=debt_pb2.RECEIPT_ORDER_DIRECTION_ASC,
            ),
            "member-a-token",
        )
        parsed = self._parse_message(debt_pb2.ReceiptsResponse, response)

        self.assertEqual(response.status_code, 400)
        self.assertFalse(parsed.success)
        self.assertIn("Page token does not match", parsed.message)

    async def test_receipts_list_orders_by_id_ascending_and_descending(self) -> None:
        asc_ids = await self._list_receipts(
            "member-a-token",
            order_by=debt_pb2.RECEIPT_ORDER_BY_ID,
            order_direction=debt_pb2.RECEIPT_ORDER_DIRECTION_ASC,
        )
        desc_ids = await self._list_receipts(
            "member-a-token",
            order_by=debt_pb2.RECEIPT_ORDER_BY_ID,
            order_direction=debt_pb2.RECEIPT_ORDER_DIRECTION_DESC,
        )
        self.assertEqual(asc_ids, sorted(asc_ids))
        self.assertEqual(desc_ids, sorted(desc_ids, reverse=True))

    async def test_receipts_list_orders_by_cost_total(self) -> None:
        ids = await self._list_receipts(
            "member-a-token",
            order_by=debt_pb2.RECEIPT_ORDER_BY_COST_TOTAL,
            order_direction=debt_pb2.RECEIPT_ORDER_DIRECTION_ASC,
        )
        self.assertEqual(
            ids,
            [
                self.member_owned_paid.id,
                self.tie_low_id.id,
                self.tie_high_id.id,
                self.shared_with_split.id,
                self.shared_without_member_share.id,
                self.member_owned_large.id,
            ],
        )

    async def test_receipts_list_orders_by_due_date_with_nulls_last(self) -> None:
        ids = await self._list_receipts(
            "member-a-token",
            order_by=debt_pb2.RECEIPT_ORDER_BY_DUE_DATE,
            order_direction=debt_pb2.RECEIPT_ORDER_DIRECTION_ASC,
        )
        self.assertEqual(
            ids,
            [
                self.shared_with_split.id,
                self.member_owned_paid.id,
                self.member_owned_large.id,
                self.tie_low_id.id,
                self.tie_high_id.id,
                self.shared_without_member_share.id,
            ],
        )

    async def test_receipts_list_orders_by_cost_for_user_for_owner(self) -> None:
        ids = await self._list_receipts(
            "owner-token",
            order_by=debt_pb2.RECEIPT_ORDER_BY_COST_FOR_USER,
            order_direction=debt_pb2.RECEIPT_ORDER_DIRECTION_ASC,
        )
        self.assertEqual(
            ids,
            [
                self.shared_with_split.id,
                self.owner_unpaid.id,
                self.shared_without_member_share.id,
            ],
        )

    async def test_receipts_list_orders_by_cost_for_user_for_member_with_explicit_share(self) -> None:
        ids = await self._list_receipts(
            "member-a-token",
            order_by=debt_pb2.RECEIPT_ORDER_BY_COST_FOR_USER,
            order_direction=debt_pb2.RECEIPT_ORDER_DIRECTION_ASC,
        )
        self.assertEqual(
            ids,
            [
                self.shared_without_member_share.id,
                self.shared_with_split.id,
                self.member_owned_paid.id,
                self.tie_low_id.id,
                self.tie_high_id.id,
                self.member_owned_large.id,
            ],
        )

    async def test_receipts_list_orders_by_cost_for_user_uses_zero_for_missing_member_share(self) -> None:
        ids = await self._list_receipts(
            "member-b-token",
            order_by=debt_pb2.RECEIPT_ORDER_BY_COST_FOR_USER,
            order_direction=debt_pb2.RECEIPT_ORDER_DIRECTION_ASC,
        )
        self.assertEqual(ids[0], self.shared_without_member_share.id)

    async def test_receipts_list_uses_id_tiebreaker_for_equal_primary_sort(self) -> None:
        ids = await self._list_receipts(
            "member-a-token",
            order_by=debt_pb2.RECEIPT_ORDER_BY_COST_TOTAL,
            order_direction=debt_pb2.RECEIPT_ORDER_DIRECTION_ASC,
        )
        self.assertLess(ids.index(self.tie_low_id.id), ids.index(self.tie_high_id.id))

    async def test_receipts_list_visibility_is_unchanged_under_sorting(self) -> None:
        ids = await self._list_receipts(
            "member-a-token",
            order_by=debt_pb2.RECEIPT_ORDER_BY_COST_FOR_USER,
            order_direction=debt_pb2.RECEIPT_ORDER_DIRECTION_DESC,
        )
        self.assertNotIn(self.owner_unpaid.id, ids)
        self.assertNotIn(self.stranger_receipt.id, ids)

    async def test_receipts_list_actor_filter_owner_only(self) -> None:
        ids = await self._list_receipts(
            "member-a-token",
            actor_filter=debt_pb2.RECEIPT_ACTOR_FILTER_OWNER,
            order_by=debt_pb2.RECEIPT_ORDER_BY_ID,
            order_direction=debt_pb2.RECEIPT_ORDER_DIRECTION_ASC,
        )
        self.assertEqual(
            ids,
            [
                self.member_owned_paid.id,
                self.member_owned_large.id,
                self.tie_low_id.id,
                self.tie_high_id.id,
            ],
        )

    async def test_receipts_list_actor_filter_recipient_group_only(self) -> None:
        ids = await self._list_receipts(
            "member-a-token",
            actor_filter=debt_pb2.RECEIPT_ACTOR_FILTER_RECIPIENT_GROUP,
            order_by=debt_pb2.RECEIPT_ORDER_BY_ID,
            order_direction=debt_pb2.RECEIPT_ORDER_DIRECTION_ASC,
        )
        self.assertEqual(
            ids,
            [
                self.shared_with_split.id,
                self.shared_without_member_share.id,
            ],
        )

    async def test_receipts_list_actor_filter_default_matches_owner_or_recipient_group(self) -> None:
        default_ids = await self._list_receipts(
            "member-a-token",
            order_by=debt_pb2.RECEIPT_ORDER_BY_ID,
            order_direction=debt_pb2.RECEIPT_ORDER_DIRECTION_ASC,
        )
        explicit_ids = await self._list_receipts(
            "member-a-token",
            actor_filter=debt_pb2.RECEIPT_ACTOR_FILTER_OWNER_OR_RECIPIENT_GROUP,
            order_by=debt_pb2.RECEIPT_ORDER_BY_ID,
            order_direction=debt_pb2.RECEIPT_ORDER_DIRECTION_ASC,
        )
        self.assertEqual(default_ids, explicit_ids)


class AuthorizationDependencyTests(AsyncDatabaseTestCase):
    async def asyncSetUp(self) -> None:
        await super().asyncSetUp()

        self.owner = await self._create_user("auth0|owner", "owner@example.com", "Owner")
        self.member = await self._create_user(
            "auth0|member", "member@example.com", "Member"
        )
        self.stranger = await self._create_user(
            "auth0|stranger", "stranger@example.com", "Stranger"
        )

        async with db.async_session_maker() as session:
            self.recipient = await db.create_recipient(
                session=session,
                owner_id=self.owner.id,
                name="Shared Group",
                description=None,
                member_ids=[self.member.id],
            )
            self.receipt = await db.create_receipt(
                session=session,
                owner_id=self.owner.id,
                title="Shared Receipt",
                amount_owed=42.0,
                recipient_id=self.recipient.id,
            )
            self.file_record = await services.create_receipt_file_for_owner(
                session=session,
                actor_user_id=self.owner.id,
                receipt_id=self.receipt.id,
                client_filename="invoice.pdf",
            )
            await session.commit()

    def _make_request(self, **path_params: str) -> Request:
        scope = {
            "type": "http",
            "method": "GET",
            "path": "/",
            "headers": [],
            "path_params": path_params,
        }
        return Request(scope)

    async def test_receipt_read_dependency_allows_member_and_stores_state(self) -> None:
        dependency = authorization.authorize_resource(
            authorization.ResourceType.RECEIPT,
            "receipt_id",
            authorization.AccessPolicy.READ,
        )

        async with db.async_session_maker() as session:
            request = self._make_request(receipt_id=str(self.receipt.id))
            resource = await dependency(
                request=request,
                session=session,
                current_user=self.member,
            )

        self.assertEqual(resource.id, self.receipt.id)
        self.assertEqual(request.state.authorized_receipt.id, self.receipt.id)

    async def test_receipt_mutation_dependency_rejects_member(self) -> None:
        dependency = authorization.authorize_resource(
            authorization.ResourceType.RECEIPT,
            "receipt_id",
            authorization.AccessPolicy.MUTATE,
        )

        async with db.async_session_maker() as session:
            request = self._make_request(receipt_id=str(self.receipt.id))
            with self.assertRaises(HTTPException) as ctx:
                await dependency(
                    request=request,
                    session=session,
                    current_user=self.member,
                )

        self.assertEqual(ctx.exception.status_code, 403)

    async def test_receipt_mutation_dependency_allows_owner(self) -> None:
        dependency = authorization.authorize_resource(
            authorization.ResourceType.RECEIPT,
            "receipt_id",
            authorization.AccessPolicy.MUTATE,
        )

        async with db.async_session_maker() as session:
            request = self._make_request(receipt_id=str(self.receipt.id))
            resource = await dependency(
                request=request,
                session=session,
                current_user=self.owner,
            )

        self.assertEqual(resource.id, self.receipt.id)
        self.assertEqual(request.state.authorized_receipt.id, self.receipt.id)

    async def test_receipt_mutation_dependency_returns_404_for_missing_receipt(self) -> None:
        dependency = authorization.authorize_resource(
            authorization.ResourceType.RECEIPT,
            "receipt_id",
            authorization.AccessPolicy.MUTATE,
        )

        async with db.async_session_maker() as session:
            request = self._make_request(receipt_id="999999")
            with self.assertRaises(HTTPException) as ctx:
                await dependency(
                    request=request,
                    session=session,
                    current_user=self.owner,
                )

        self.assertEqual(ctx.exception.status_code, 404)

    async def test_file_read_dependency_hides_resource_from_stranger(self) -> None:
        dependency = authorization.authorize_resource(
            authorization.ResourceType.FILE,
            "file_id",
            authorization.AccessPolicy.READ,
        )

        async with db.async_session_maker() as session:
            request = self._make_request(file_id=str(self.file_record.id))
            with self.assertRaises(HTTPException) as ctx:
                await dependency(
                    request=request,
                    session=session,
                    current_user=self.stranger,
                )

        self.assertEqual(ctx.exception.status_code, 404)

    async def test_file_mutation_dependency_allows_owner(self) -> None:
        dependency = authorization.authorize_resource(
            authorization.ResourceType.FILE,
            "file_id",
            authorization.AccessPolicy.MUTATE,
        )

        async with db.async_session_maker() as session:
            request = self._make_request(file_id=str(self.file_record.id))
            resource = await dependency(
                request=request,
                session=session,
                current_user=self.owner,
            )

        self.assertEqual(resource.id, self.file_record.id)
        self.assertEqual(request.state.authorized_file.id, self.file_record.id)

    async def test_file_mutation_dependency_rejects_member(self) -> None:
        dependency = authorization.authorize_resource(
            authorization.ResourceType.FILE,
            "file_id",
            authorization.AccessPolicy.MUTATE,
        )

        async with db.async_session_maker() as session:
            request = self._make_request(file_id=str(self.file_record.id))
            with self.assertRaises(HTTPException) as ctx:
                await dependency(
                    request=request,
                    session=session,
                    current_user=self.member,
                )

        self.assertEqual(ctx.exception.status_code, 403)

    async def test_file_mutation_dependency_returns_404_for_missing_file(self) -> None:
        dependency = authorization.authorize_resource(
            authorization.ResourceType.FILE,
            "file_id",
            authorization.AccessPolicy.MUTATE,
        )

        async with db.async_session_maker() as session:
            request = self._make_request(file_id="999999")
            with self.assertRaises(HTTPException) as ctx:
                await dependency(
                    request=request,
                    session=session,
                    current_user=self.owner,
                )

        self.assertEqual(ctx.exception.status_code, 404)

    async def test_recipient_manage_members_dependency_is_owner_only(self) -> None:
        dependency = authorization.authorize_resource(
            authorization.ResourceType.RECIPIENT,
            "recipient_id",
            authorization.AccessPolicy.MANAGE_MEMBERS,
        )

        async with db.async_session_maker() as session:
            owner_request = self._make_request(recipient_id=str(self.recipient.id))
            resource = await dependency(
                request=owner_request,
                session=session,
                current_user=self.owner,
            )

            member_request = self._make_request(recipient_id=str(self.recipient.id))
            with self.assertRaises(HTTPException) as ctx:
                await dependency(
                    request=member_request,
                    session=session,
                    current_user=self.member,
                )

        self.assertEqual(resource.id, self.recipient.id)
        self.assertEqual(ctx.exception.status_code, 403)

    async def test_recipient_manage_members_dependency_returns_404_for_missing_recipient(self) -> None:
        dependency = authorization.authorize_resource(
            authorization.ResourceType.RECIPIENT,
            "recipient_id",
            authorization.AccessPolicy.MANAGE_MEMBERS,
        )

        async with db.async_session_maker() as session:
            request = self._make_request(recipient_id="999999")
            with self.assertRaises(HTTPException) as ctx:
                await dependency(
                    request=request,
                    session=session,
                    current_user=self.owner,
                )

        self.assertEqual(ctx.exception.status_code, 404)
