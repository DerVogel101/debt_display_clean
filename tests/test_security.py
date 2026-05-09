from __future__ import annotations

import hashlib
import tempfile
import unittest
from datetime import datetime, timedelta, timezone
from pathlib import Path
from unittest.mock import AsyncMock, patch

from fastapi import HTTPException
from httpx import ASGITransport, AsyncClient
from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
from sqlalchemy.orm import selectinload
from starlette.requests import Request

from backend import authorization, db, main, seed_test_data, services
from backend.config import Settings, settings
from backend.proto import debt_pb2
from backend.proto import auth_pb2
from backend.storage import resolve_storage_path


class SettingsDefaultTests(unittest.TestCase):
    def test_demo_seed_data_is_enabled_by_default_until_prod_ready(self) -> None:
        self.assertTrue(
            Settings.model_fields["GENERATE_TEST_DATA_ON_STARTUP"].default
        )


class AsyncDatabaseTestCase(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self) -> None:
        self._tmpdir = tempfile.TemporaryDirectory()
        self._db_path = Path(self._tmpdir.name) / "test.sqlite"
        self._db_url = f"sqlite+aiosqlite:///{self._db_path.as_posix()}"

        self._original_engine = db.engine
        self._original_session_maker = db.async_session_maker
        self._original_upload_dir = settings.UPLOAD_DIR
        self._original_file_upload_max_bytes = settings.FILE_UPLOAD_MAX_BYTES

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
        settings.FILE_UPLOAD_MAX_BYTES = self._original_file_upload_max_bytes
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
            owner_zero_receipts = await session.execute(
                select(db.Receipt)
                .where(db.Receipt.title == "Demo team lunch reimbursement")
                .options(selectinload(db.Receipt.recipient_shares))
            )
            visible_receipts = await services.list_visible_receipts(
                session,
                first_user.id,
                limit=20,
            )

        self.assertEqual([user.email for user in users], ["alice.demo@example.com"])
        recipient = recipients.scalar_one_or_none()
        receipt = receipts.scalar_one_or_none()
        self.assertIsNotNone(recipient)
        self.assertIsNotNone(receipt)
        self.assertEqual(recipient.owner_id, first_user.id)
        self.assertEqual(receipt.owner_id, first_user.id)
        self.assertEqual(receipt.owner_share_percent, 40.0)
        self.assertAlmostEqual(receipt.owner_amount_paid, 170.8)
        self.assertGreater(receipt.amount_paid, receipt.owner_amount_paid)
        self.assertEqual(len(receipt.recipient_shares), 2)
        self.assertEqual([(tag.icon, tag.text) for tag in receipt.tags], [("🏠", "Rent")])
        owner_zero_receipt = owner_zero_receipts.scalar_one_or_none()
        self.assertIsNotNone(owner_zero_receipt)
        self.assertEqual(owner_zero_receipt.owner_id, first_user.id)
        self.assertEqual(owner_zero_receipt.owner_share_percent, 0.0)
        self.assertEqual(owner_zero_receipt.owner_amount_paid, 0.0)
        self.assertEqual(len(owner_zero_receipt.recipient_shares), 2)
        self.assertGreater(len(visible_receipts.receipts), 10)

    async def test_seed_test_data_reconciles_members_after_demo_user_delete(self) -> None:
        first_user = await self._create_user(
            "auth0|first",
            "first@example.com",
            "First User",
        )

        await seed_test_data.seed_test_data()

        async with db.async_session_maker() as session:
            deleted_result = await db.delete_user_by_sub(session, "test|alice")
            await session.commit()

        await seed_test_data.seed_test_data()

        async with db.async_session_maker() as session:
            active_alice = (
                await session.execute(
                    select(db.User).where(db.User.sub == "test|alice")
                )
            ).scalar_one()
            deleted_alice = await db.get_user_by_id(session, deleted_result.user_id)
            household = (
                await session.execute(
                    select(db.Recipient)
                    .where(db.Recipient.owner_id == first_user.id)
                    .where(db.Recipient.name == "Demo household")
                    .options(selectinload(db.Recipient.members))
                )
            ).scalar_one()
            rent_receipt = (
                await session.execute(
                    select(db.Receipt)
                    .where(db.Receipt.owner_id == first_user.id)
                    .where(db.Receipt.title == "Demo rent top-up")
                    .options(selectinload(db.Receipt.recipient_shares))
                )
            ).scalar_one()

        self.assertIsNotNone(deleted_alice)
        self.assertTrue(deleted_alice.deleted)
        self.assertFalse(active_alice.deleted)
        self.assertEqual(active_alice.email, "alice.demo@example.com")
        self.assertIn(active_alice.id, [member.id for member in household.members])
        self.assertNotIn(
            deleted_result.user_id,
            [member.id for member in household.members],
        )
        self.assertIn(
            active_alice.id,
            [share.user_id for share in rent_receipt.recipient_shares],
        )
        self.assertNotIn(
            deleted_result.user_id,
            [share.user_id for share in rent_receipt.recipient_shares],
        )


class SchemaCompatibilityTests(AsyncDatabaseTestCase):
    async def test_schema_migration_backfills_participant_payments(self) -> None:
        async with db.engine.begin() as conn:  # type: ignore[arg-type]
            await conn.run_sync(db.Base.metadata.drop_all)
            await conn.execute(
                text(
                    "CREATE TABLE users ("
                    "id INTEGER PRIMARY KEY, "
                    "sub VARCHAR(256) NOT NULL, "
                    "email VARCHAR(256), "
                    "name VARCHAR(256), "
                    "avatar_url VARCHAR(512)"
                    ")"
                )
            )
            await conn.execute(
                text(
                    "CREATE TABLE receipts ("
                    "id INTEGER PRIMARY KEY, "
                    "amount_owed FLOAT NOT NULL, "
                    "amount_paid FLOAT, "
                    "owner_share_percent FLOAT, "
                    "is_paid BOOLEAN NOT NULL DEFAULT 0, "
                    "recipient_name VARCHAR(256)"
                    ")"
                )
            )
            await conn.execute(
                text(
                    "CREATE TABLE receipt_recipient_shares ("
                    "receipt_id INTEGER NOT NULL, "
                    "user_id INTEGER NOT NULL, "
                    "share_percent FLOAT NOT NULL, "
                    "user_name_snapshot VARCHAR(256), "
                    "user_email_snapshot VARCHAR(256), "
                    "PRIMARY KEY (receipt_id, user_id)"
                    ")"
                )
            )
            await conn.execute(
                text(
                    "INSERT INTO receipts "
                    "(id, amount_owed, amount_paid, owner_share_percent, is_paid) "
                    "VALUES "
                    "(1, 100.0, 0.0, 25.0, 1), "
                    "(2, 100.0, 50.0, 40.0, 0), "
                    "(3, 100.0, 30.0, NULL, 0)"
                )
            )
            await conn.execute(
                text(
                    "INSERT INTO receipt_recipient_shares "
                    "(receipt_id, user_id, share_percent) "
                    "VALUES (1, 20, 75.0), (2, 21, 60.0)"
                )
            )

        await db.ensure_schema_compatible()

        async with db.engine.begin() as conn:  # type: ignore[arg-type]
            receipts = {
                row.id: row
                for row in (
                    await conn.execute(
                        text(
                            "SELECT id, amount_paid, owner_amount_paid "
                            "FROM receipts ORDER BY id"
                        )
                    )
                ).all()
            }
            shares = {
                (row.receipt_id, row.user_id): row.amount_paid
                for row in (
                    await conn.execute(
                        text(
                            "SELECT receipt_id, user_id, amount_paid "
                            "FROM receipt_recipient_shares "
                            "ORDER BY receipt_id, user_id"
                        )
                    )
                ).all()
            }
            user_columns = {
                row[1]
                for row in (await conn.execute(text("PRAGMA table_info(users)"))).all()
            }
            receipt_columns = {
                row[1]
                for row in (await conn.execute(text("PRAGMA table_info(receipts)"))).all()
            }
            share_columns = {
                row[1]
                for row in (
                    await conn.execute(text("PRAGMA table_info(receipt_recipient_shares)"))
                ).all()
            }

        self.assertAlmostEqual(receipts[1].amount_paid, 100.0)
        self.assertAlmostEqual(receipts[1].owner_amount_paid, 25.0)
        self.assertAlmostEqual(shares[(1, 20)], 75.0)
        self.assertAlmostEqual(receipts[2].amount_paid, 50.0)
        self.assertAlmostEqual(receipts[2].owner_amount_paid, 20.0)
        self.assertAlmostEqual(shares[(2, 21)], 30.0)
        self.assertAlmostEqual(receipts[3].amount_paid, 30.0)
        self.assertAlmostEqual(receipts[3].owner_amount_paid, 30.0)
        self.assertIn("deleted", user_columns)
        self.assertNotIn("recipient_name", receipt_columns)
        self.assertNotIn("user_name_snapshot", share_columns)
        self.assertNotIn("user_email_snapshot", share_columns)


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

    async def _upload_file(
        self,
        *,
        token: str,
        receipt_id: int,
        filename: str,
        content: bytes,
        content_type: str,
    ):
        async def verify_side_effect(access_token: str):
            return self._claims_by_token[access_token]

        transport = ASGITransport(app=main.app)
        async with AsyncClient(transport=transport, base_url="http://testserver") as client:
            with patch("backend.auth.verify_token", new=AsyncMock(side_effect=verify_side_effect)):
                return await client.post(
                    "/api/files/upload",
                    data={"receipt_id": str(receipt_id)},
                    files={"file": (filename, content, content_type)},
                    headers={"Authorization": f"Bearer {token}"},
                )

    async def _get_file_content(self, *, token: str, file_id: int):
        async def verify_side_effect(access_token: str):
            return self._claims_by_token[access_token]

        transport = ASGITransport(app=main.app)
        async with AsyncClient(transport=transport, base_url="http://testserver") as client:
            with patch("backend.auth.verify_token", new=AsyncMock(side_effect=verify_side_effect)):
                return await client.get(
                    f"/api/files/{file_id}/content",
                    headers={"Authorization": f"Bearer {token}"},
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
                (share.user_id, share.share_percent, share.amount, share.user.name)
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

    async def test_set_receipt_payments_accumulates_individual_paid_amounts(self) -> None:
        create_response = await self._post_protobuf(
            "/api/receipts/create",
            self._create_receipt_request_with_split(),
            "owner-token",
        )
        created = self._parse_message(debt_pb2.ReceiptResponse, create_response)
        request = debt_pb2.SetReceiptPaymentsRequest(receipt_id=created.receipt.id)
        request.payments.add(amount_paid=15.0)
        request.payments.add(user_id=self.member_a.id, amount_paid=20.0)

        response = await self._post_protobuf(
            "/api/receipts/set-payments",
            request,
            "owner-token",
        )
        parsed = self._parse_message(debt_pb2.ReceiptResponse, response)

        self.assertEqual(response.status_code, 200)
        self.assertTrue(parsed.success)
        self.assertAlmostEqual(parsed.receipt.amount_paid, 35.0)
        self.assertAlmostEqual(parsed.receipt.split.owner_amount_paid, 15.0)
        self.assertFalse(parsed.receipt.is_paid)
        self.assertEqual(
            {
                (share.user_id, share.amount_paid)
                for share in parsed.receipt.split.recipient_shares
            },
            {
                (self.member_a.id, 20.0),
                (self.member_b.id, 0.0),
            },
        )

        async with db.async_session_maker() as session:
            stored = await db.get_receipt_by_id(session, created.receipt.id)

        self.assertAlmostEqual(stored.amount_paid, 35.0)
        self.assertAlmostEqual(stored.owner_amount_paid, 15.0)
        self.assertEqual(
            {
                (share.user_id, share.amount_paid)
                for share in stored.recipient_shares
            },
            {
                (self.member_a.id, 20.0),
                (self.member_b.id, 0.0),
            },
        )

    async def test_set_receipt_payments_rejects_non_owner_and_overpayment(self) -> None:
        create_response = await self._post_protobuf(
            "/api/receipts/create",
            self._create_receipt_request_with_split(),
            "owner-token",
        )
        created = self._parse_message(debt_pb2.ReceiptResponse, create_response)

        member_request = debt_pb2.SetReceiptPaymentsRequest(
            receipt_id=created.receipt.id
        )
        member_request.payments.add(user_id=self.member_a.id, amount_paid=1.0)
        member_response = await self._post_protobuf(
            "/api/receipts/set-payments",
            member_request,
            "member-a-token",
        )
        member_parsed = self._parse_message(debt_pb2.ReceiptResponse, member_response)

        self.assertEqual(member_response.status_code, 403)
        self.assertFalse(member_parsed.success)

        overpay_request = debt_pb2.SetReceiptPaymentsRequest(
            receipt_id=created.receipt.id
        )
        overpay_request.payments.add(user_id=self.member_a.id, amount_paid=31.0)
        overpay_response = await self._post_protobuf(
            "/api/receipts/set-payments",
            overpay_request,
            "owner-token",
        )
        overpay_parsed = self._parse_message(debt_pb2.ReceiptResponse, overpay_response)

        self.assertEqual(overpay_response.status_code, 400)
        self.assertFalse(overpay_parsed.success)
        self.assertIn("cannot exceed", overpay_parsed.message)

    async def test_mark_paid_and_unpaid_fill_and_clear_individual_amounts(self) -> None:
        create_response = await self._post_protobuf(
            "/api/receipts/create",
            self._create_receipt_request_with_split(),
            "owner-token",
        )
        created = self._parse_message(debt_pb2.ReceiptResponse, create_response)

        paid_response = await self._post_protobuf(
            "/api/receipts/mark-paid",
            debt_pb2.MarkReceiptPaidRequest(receipt_id=created.receipt.id),
            "owner-token",
        )
        paid = self._parse_message(debt_pb2.ReceiptResponse, paid_response)

        self.assertEqual(paid_response.status_code, 200)
        self.assertTrue(paid.receipt.is_paid)
        self.assertAlmostEqual(paid.receipt.amount_paid, 100.0)
        self.assertAlmostEqual(paid.receipt.split.owner_amount_paid, 30.0)
        self.assertEqual(
            {
                (share.user_id, share.amount_paid)
                for share in paid.receipt.split.recipient_shares
            },
            {
                (self.member_a.id, 30.0),
                (self.member_b.id, 40.0),
            },
        )

        unpaid_response = await self._post_protobuf(
            "/api/receipts/mark-unpaid",
            debt_pb2.ReceiptLookupRequest(receipt_id=created.receipt.id),
            "owner-token",
        )
        unpaid = self._parse_message(debt_pb2.ReceiptResponse, unpaid_response)

        self.assertEqual(unpaid_response.status_code, 200)
        self.assertFalse(unpaid.receipt.is_paid)
        self.assertAlmostEqual(unpaid.receipt.amount_paid, 0.0)
        self.assertAlmostEqual(unpaid.receipt.split.owner_amount_paid, 0.0)
        self.assertEqual(
            {
                (share.user_id, share.amount_paid)
                for share in unpaid.receipt.split.recipient_shares
            },
            {
                (self.member_a.id, 0.0),
                (self.member_b.id, 0.0),
            },
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

    async def test_delete_user_anonymizes_and_preserves_split_references(self) -> None:
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
            result = await db.delete_user(session, self.member_a.id)
            await session.commit()

        self.assertEqual(result.storage_keys, [])
        self.assertEqual(result.retained_memberships, 1)

        async with db.async_session_maker() as session:
            stored = await db.get_receipt_by_id(session, receipt.id)
            deleted_user = await db.get_user_by_id(session, self.member_a.id)

        self.assertIsNotNone(stored)
        self.assertIsNotNone(deleted_user)
        self.assertTrue(deleted_user.deleted)
        self.assertNotEqual(deleted_user.sub, "auth0|member-a")
        self.assertEqual(deleted_user.email, "[DELETED]")
        self.assertEqual(deleted_user.name, "[DELETED]")
        self.assertIsNone(deleted_user.avatar_url)
        self.assertEqual(stored.owner_share_percent, 25.0)
        self.assertEqual(
            [
                (
                    share.user_id,
                    share.share_percent,
                    share.user.deleted,
                    share.user.name,
                )
                for share in stored.recipient_shares
            ],
            [(self.member_a.id, 75.0, True, "[DELETED]")],
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
                    share.user.deleted,
                    share.user.name,
                )
                for share in parsed.receipt.split.recipient_shares
            ],
            [(self.member_a.id, 75.0, True, "[DELETED]")],
        )

    async def test_users_delete_route_removes_owned_data_and_keeps_other_group_membership(self) -> None:
        async with db.async_session_maker() as session:
            owned_group = await db.create_recipient(
                session=session,
                owner_id=self.member_a.id,
                name="Owned by deleted user",
                description=None,
                member_ids=[self.member_b.id],
            )
            retained_group = await db.create_recipient(
                session=session,
                owner_id=self.owner.id,
                name="Retained group",
                description=None,
                member_ids=[self.member_a.id],
            )
            owned_receipt = await db.create_receipt(
                session=session,
                owner_id=self.member_a.id,
                title="Deleted user receipt",
                amount_owed=42.0,
                recipient_id=owned_group.id,
            )
            file_record = await services.create_receipt_file_for_owner(
                session=session,
                actor_user_id=self.member_a.id,
                receipt_id=owned_receipt.id,
                client_filename="receipt.pdf",
            )
            await session.commit()

            file_path = resolve_storage_path(file_record.storage_key, settings.UPLOAD_DIR)
            file_path.parent.mkdir(parents=True, exist_ok=True)
            file_path.write_bytes(b"receipt")

        response = await self._post_protobuf(
            "/api/users/delete",
            debt_pb2.EmptyRequest(),
            "member-a-token",
        )
        parsed = self._parse_message(debt_pb2.ActionResponse, response)

        self.assertEqual(response.status_code, 200)
        self.assertTrue(parsed.success)
        self.assertFalse(file_path.exists())

        async with db.async_session_maker() as session:
            deleted_user = await db.get_user_by_id(session, self.member_a.id)
            removed_receipt = await db.get_receipt_by_id(session, owned_receipt.id)
            removed_group = await db.get_recipient_by_id(session, owned_group.id)
            kept_group = await db.get_recipient_by_id(session, retained_group.id)

        self.assertIsNotNone(deleted_user)
        self.assertTrue(deleted_user.deleted)
        self.assertEqual(deleted_user.email, "[DELETED]")
        self.assertIsNone(removed_receipt)
        self.assertIsNone(removed_group)
        self.assertIsNotNone(kept_group)
        self.assertEqual([member.id for member in kept_group.members], [self.member_a.id])
        self.assertTrue(kept_group.members[0].deleted)

        search_response = await self._post_protobuf(
            "/api/users/search",
            debt_pb2.UserSearchRequest(query="mem"),
            "owner-token",
        )
        search = self._parse_message(debt_pb2.UsersResponse, search_response)
        self.assertEqual(search_response.status_code, 200)
        self.assertNotIn(self.member_a.id, [user.id for user in search.users])

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

    async def _upload_file(
        self,
        *,
        token: str,
        receipt_id: int,
        filename: str,
        content: bytes,
        content_type: str,
    ):
        async def verify_side_effect(access_token: str):
            return self._claims_by_token[access_token]

        transport = ASGITransport(app=main.app)
        async with AsyncClient(transport=transport, base_url="http://testserver") as client:
            with patch("backend.auth.verify_token", new=AsyncMock(side_effect=verify_side_effect)):
                return await client.post(
                    "/api/files/upload",
                    data={"receipt_id": str(receipt_id)},
                    files={"file": (filename, content, content_type)},
                    headers={"Authorization": f"Bearer {token}"},
                )

    async def _get_file_content(self, *, token: str, file_id: int):
        async def verify_side_effect(access_token: str):
            return self._claims_by_token[access_token]

        transport = ASGITransport(app=main.app)
        async with AsyncClient(transport=transport, base_url="http://testserver") as client:
            with patch("backend.auth.verify_token", new=AsyncMock(side_effect=verify_side_effect)):
                return await client.get(
                    f"/api/files/{file_id}/content",
                    headers={"Authorization": f"Bearer {token}"},
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

    async def test_files_upload_writes_bytes_and_metadata(self) -> None:
        payload = b"%PDF-1.4\nreceipt"
        response = await self._upload_file(
            token="owner-token",
            receipt_id=self.shared_receipt.id,
            filename=r"..\..\Quarterly Report?.pdf",
            content=payload,
            content_type="application/pdf",
        )
        parsed = self._parse_message(debt_pb2.FileResponse, response)

        self.assertEqual(response.status_code, 200)
        self.assertTrue(parsed.success)
        self.assertEqual(parsed.file.original_filename, "Quarterly Report_.pdf")
        self.assertEqual(parsed.file.content_type, "application/pdf")
        self.assertEqual(parsed.file.size_bytes, len(payload))

        async with db.async_session_maker() as session:
            stored = await session.get(db.ReceiptFile, parsed.file.id)

        self.assertIsNotNone(stored)
        self.assertEqual(stored.sha256, hashlib.sha256(payload).hexdigest())
        stored_path = resolve_storage_path(stored.storage_key, self._tmpdir.name)
        self.assertEqual(stored_path.read_bytes(), payload)

    async def test_files_upload_rejects_payloads_over_size_limit(self) -> None:
        settings.FILE_UPLOAD_MAX_BYTES = 8
        response = await self._upload_file(
            token="owner-token",
            receipt_id=self.shared_receipt.id,
            filename="large.pdf",
            content=b"123456789",
            content_type="application/pdf",
        )
        parsed = self._parse_message(debt_pb2.FileResponse, response)

        self.assertEqual(response.status_code, 413)
        self.assertFalse(parsed.success)
        self.assertIn("upload limit", parsed.message)

        async with db.async_session_maker() as session:
            result = await session.execute(select(db.ReceiptFile))
            stored_files = result.scalars().all()

        self.assertEqual([file.id for file in stored_files], [self.shared_file.id])

    async def test_files_upload_requires_receipt_owner(self) -> None:
        response = await self._upload_file(
            token="member-token",
            receipt_id=self.shared_receipt.id,
            filename="member.pdf",
            content=b"not allowed",
            content_type="application/pdf",
        )
        parsed = self._parse_message(debt_pb2.FileResponse, response)

        self.assertEqual(response.status_code, 403)
        self.assertFalse(parsed.success)

    async def test_files_content_allows_member_and_rejects_stranger(self) -> None:
        payload = b"\x89PNG\r\nreceipt"
        upload = await self._upload_file(
            token="owner-token",
            receipt_id=self.shared_receipt.id,
            filename="receipt.png",
            content=payload,
            content_type="image/png",
        )
        uploaded = self._parse_message(debt_pb2.FileResponse, upload)

        member_response = await self._get_file_content(
            token="member-token",
            file_id=uploaded.file.id,
        )
        stranger_response = await self._get_file_content(
            token="stranger-token",
            file_id=uploaded.file.id,
        )

        self.assertEqual(member_response.status_code, 200)
        self.assertEqual(member_response.content, payload)
        self.assertEqual(member_response.headers["content-type"], "image/png")
        self.assertEqual(stranger_response.status_code, 404)

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

    async def test_receipts_list_page_token_paginates_remaining_for_user_sort(self) -> None:
        ids = await self._collect_page_token_ids(
            "member-a-token",
            limit=2,
            order_by=debt_pb2.RECEIPT_ORDER_BY_REMAINING_FOR_USER,
            order_direction=debt_pb2.RECEIPT_ORDER_DIRECTION_ASC,
        )
        self.assertEqual(
            ids,
            [
                self.shared_without_member_share.id,
                self.member_owned_paid.id,
                self.shared_with_split.id,
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

    async def test_receipts_list_rejects_page_token_when_remaining_sort_changes(self) -> None:
        first_page = await self._list_receipts_response(
            "member-a-token",
            limit=2,
            order_by=debt_pb2.RECEIPT_ORDER_BY_REMAINING_FOR_USER,
            order_direction=debt_pb2.RECEIPT_ORDER_DIRECTION_ASC,
        )

        response = await self._post_protobuf(
            "/api/receipts/list",
            debt_pb2.ReceiptListRequest(
                limit=2,
                page_token=first_page.next_page_token,
                order_by=debt_pb2.RECEIPT_ORDER_BY_COST_FOR_USER,
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

    async def test_receipts_list_orders_by_remaining_for_user_for_owner(self) -> None:
        ids = await self._list_receipts(
            "owner-token",
            order_by=debt_pb2.RECEIPT_ORDER_BY_REMAINING_FOR_USER,
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

    async def test_receipts_list_orders_by_remaining_for_user_for_member(self) -> None:
        ids = await self._list_receipts(
            "member-a-token",
            order_by=debt_pb2.RECEIPT_ORDER_BY_REMAINING_FOR_USER,
            order_direction=debt_pb2.RECEIPT_ORDER_DIRECTION_ASC,
        )
        self.assertEqual(
            ids,
            [
                self.shared_without_member_share.id,
                self.member_owned_paid.id,
                self.shared_with_split.id,
                self.tie_low_id.id,
                self.tie_high_id.id,
                self.member_owned_large.id,
            ],
        )

    async def test_receipts_list_remaining_sort_treats_paid_receipts_as_zero(self) -> None:
        ids = await self._list_receipts(
            "member-a-token",
            order_by=debt_pb2.RECEIPT_ORDER_BY_REMAINING_FOR_USER,
            order_direction=debt_pb2.RECEIPT_ORDER_DIRECTION_ASC,
        )
        self.assertLess(
            ids.index(self.member_owned_paid.id),
            ids.index(self.shared_with_split.id),
        )

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
