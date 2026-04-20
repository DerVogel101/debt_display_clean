from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
from unittest.mock import AsyncMock, patch

from fastapi import HTTPException
from httpx import ASGITransport, AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
from starlette.requests import Request

from backend import authorization, db, main, services
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
