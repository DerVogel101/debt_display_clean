from __future__ import annotations

import hashlib
from datetime import datetime, timezone
from pathlib import Path

import aiofiles
from fastapi import Depends, FastAPI, File, Form, HTTPException, Request, UploadFile
from fastapi.responses import FileResponse as DownloadFileResponse, Response
from sqlalchemy.ext.asyncio import AsyncSession

from backend import authorization, services
from backend.auth import fetch_userinfo, get_current_user, verify_token
from backend.db import (
    add_member_to_recipient,
    create_recipient,
    delete_recipient,
    delete_user,
    get_or_create_tag,
    get_or_create_user,
    get_recipient_by_id,
    get_receipt_by_id,
    get_tag_by_id,
    get_tag_by_text,
    list_all_tags,
    list_files_for_receipt,
    list_recipients_for_user,
    list_visible_recommended_tags,
    remove_member_from_recipient,
    search_users_by_prefix,
    tag_receipt,
    untag_receipt,
    update_recipient,
    update_tag,
    update_user_profile,
    create_receipt,
    delete_tag,
)
from backend.db import get_session
from backend.config import settings
from backend.proto import auth_pb2, debt_pb2
from backend.storage import resolve_storage_path

api_app = FastAPI(title="api")


class ProtobufResponse(Response):
    media_type = "application/x-protobuf"


def _first_non_empty(*values: str | None) -> str | None:
    for value in values:
        if value:
            return value
    return None


def _trimmed_non_empty_string(value: object | None) -> str | None:
    if not isinstance(value, str):
        return None
    trimmed = value.strip()
    return trimmed or None


def _pb_response(message, status_code: int = 200) -> ProtobufResponse:
    return ProtobufResponse(content=message.SerializeToString(), status_code=status_code)


def _dt_to_proto(value: datetime | None) -> str:
    if value is None:
        return ""
    if value.tzinfo is None:
        value = value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")


def _dt_from_proto(value: str | None) -> datetime | None:
    return None if not value else datetime.fromisoformat(value.replace("Z", "+00:00"))


def _upload_root() -> Path:
    return Path(settings.UPLOAD_DIR).resolve()

def _delete_managed_file(storage_key: str) -> bool:
    try:
        resolved = resolve_storage_path(storage_key, _upload_root())
    except ValueError:
        return False
    resolved.unlink(missing_ok=True)
    return True


def _has_field(message, field: str) -> bool:
    try:
        return message.HasField(field)
    except ValueError:
        return False


def _receipt_list_order_by(value: int) -> str:
    if value == 0 or value == 1:
        return "id"
    if value == 2:
        return "cost_total"
    if value == 3:
        return "cost_for_user"
    if value == 4:
        return "due_date"
    raise ValueError("Unsupported receipt list order_by")


def _receipt_list_order_direction(value: int) -> str:
    if value == 0 or value == 1:
        return "asc"
    if value == 2:
        return "desc"
    raise ValueError("Unsupported receipt list order_direction")


def _receipt_list_actor_filter(value: int) -> str:
    if value == 0 or value == 1:
        return "owner_or_recipient_group"
    if value == 2:
        return "owner"
    if value == 3:
        return "recipient_group"
    raise ValueError("Unsupported receipt list actor_filter")


def _status_for_exc(exc: Exception) -> int:
    if isinstance(exc, HTTPException):
        return exc.status_code
    if isinstance(exc, PermissionError):
        return 403
    if isinstance(exc, (LookupError, FileNotFoundError)):
        return 404
    if isinstance(exc, ValueError):
        return 404 if "not found" in str(exc).lower() else 400
    return 500


def _error_message(exc: Exception) -> str:
    return str(exc.detail) if isinstance(exc, HTTPException) else str(exc)


def _error_response(response_cls, exc: Exception) -> ProtobufResponse:
    return _pb_response(response_cls(success=False, message=_error_message(exc)), _status_for_exc(exc))


def _action_response(message: str = "") -> debt_pb2.ActionResponse:
    return debt_pb2.ActionResponse(success=True, message=message)


def _user_to_pb(user) -> debt_pb2.User:
    msg = debt_pb2.User(id=user.id, sub=user.sub)
    if user.email is not None:
        msg.email = user.email
    if user.name is not None:
        msg.name = user.name
    if user.avatar_url is not None:
        msg.avatar_url = user.avatar_url
    return msg


def _recipient_to_pb(recipient, *, include_members: bool = True) -> debt_pb2.Recipient:
    msg = debt_pb2.Recipient(
        id=recipient.id,
        name=recipient.name,
        owner_id=recipient.owner_id,
        created_at=_dt_to_proto(recipient.created_at),
    )
    if recipient.description is not None:
        msg.description = recipient.description
    if include_members:
        for member in getattr(recipient, "members", []) or []:
            msg.members.add().CopyFrom(_user_to_pb(member))
            msg.member_ids.append(member.id)
    return msg


def _file_to_pb(file_record) -> debt_pb2.ReceiptFile:
    msg = debt_pb2.ReceiptFile(
        id=file_record.id,
        receipt_id=file_record.receipt_id,
        original_filename=file_record.original_filename,
        created_at=_dt_to_proto(file_record.created_at),
    )
    if file_record.content_type is not None:
        msg.content_type = file_record.content_type
    if file_record.size_bytes is not None:
        msg.size_bytes = int(file_record.size_bytes)
    if file_record.sha256 is not None:
        msg.sha256 = file_record.sha256
    return msg


def _tag_to_pb(tag) -> debt_pb2.TagIndex:
    return debt_pb2.TagIndex(id=tag.id, icon=tag.icon, text=tag.text, color=tag.color)


def _split_input_from_pb(split) -> tuple[float, list[tuple[int, float]]]:
    return (
        float(split.owner_share_percent),
        [
            (int(share.user_id), float(share.share_percent))
            for share in split.recipient_shares
        ],
    )


def _payment_inputs_from_pb(request) -> list[tuple[int | None, float]]:
    return [
        (
            int(payment.user_id) if _has_field(payment, "user_id") else None,
            float(payment.amount_paid),
        )
        for payment in request.payments
    ]


def _receipt_split_to_pb(receipt) -> debt_pb2.ReceiptSplit | None:
    if receipt.owner_share_percent is None:
        return None

    amount_owed = float(receipt.amount_owed)
    msg = debt_pb2.ReceiptSplit(
        owner_share_percent=float(receipt.owner_share_percent),
        owner_amount=amount_owed * float(receipt.owner_share_percent) / 100.0,
        owner_amount_paid=float(receipt.owner_amount_paid or 0.0),
    )
    for share in getattr(receipt, "recipient_shares", []) or []:
        share_msg = msg.recipient_shares.add(
            user_id=share.user_id,
            share_percent=float(share.share_percent),
            amount=amount_owed * float(share.share_percent) / 100.0,
            amount_paid=float(share.amount_paid or 0.0),
        )
        if share.user_name_snapshot is not None:
            share_msg.user_name = share.user_name_snapshot
        if share.user_email_snapshot is not None:
            share_msg.user_email = share.user_email_snapshot
    return msg


def _receipt_to_pb(receipt) -> debt_pb2.Receipt:
    msg = debt_pb2.Receipt(
        id=receipt.id,
        title=receipt.title,
        amount_owed=float(receipt.amount_owed),
        is_paid=bool(receipt.is_paid),
        currency=receipt.currency,
        created_at=_dt_to_proto(receipt.created_at),
        owner_id=receipt.owner_id,
    )
    if receipt.description is not None:
        msg.description = receipt.description
    if receipt.amount_paid is not None:
        msg.amount_paid = float(receipt.amount_paid)
    if receipt.due_date is not None:
        msg.due_date = _dt_to_proto(receipt.due_date)
    if receipt.paid_at is not None:
        msg.paid_at = _dt_to_proto(receipt.paid_at)
    if receipt.notes is not None:
        msg.notes = receipt.notes
    if receipt.updated_at is not None:
        msg.updated_at = _dt_to_proto(receipt.updated_at)
    if receipt.recipient_id is not None:
        msg.recipient_id = receipt.recipient_id
    if receipt.recipient_name is not None:
        msg.recipient_name = receipt.recipient_name
    if receipt.recipient is not None:
        msg.recipient.CopyFrom(_recipient_to_pb(receipt.recipient, include_members=False))
    for file_record in getattr(receipt, "files", []) or []:
        msg.files.add().CopyFrom(_file_to_pb(file_record))
    for tag in getattr(receipt, "tags", []) or []:
        msg.tags.add().CopyFrom(_tag_to_pb(tag))
    split = _receipt_split_to_pb(receipt)
    if split is not None:
        msg.split.CopyFrom(split)
    return msg


async def _current_user(request: Request, session: AsyncSession):
    return await get_current_user(request=request, session=session)


async def _authorize_message_resource(
    request: Request,
    session: AsyncSession,
    user,
    resource_type: authorization.ResourceType,
    field_name: str,
    message,
    policy: authorization.AccessPolicy,
):
    return await authorization.authorize_resource_from_message(
        request=request,
        session=session,
        current_user=user,
        resource_type=resource_type,
        field_name=field_name,
        message=message,
        policy=policy,
    )


@api_app.post("/auth/login")
async def login(request: Request, session: AsyncSession = Depends(get_session)) -> ProtobufResponse:
    body = await request.body()
    proto_req = auth_pb2.LoginRequest()
    proto_req.ParseFromString(body)
    try:
        claims = await verify_token(proto_req.access_token)
        full_name_claim = _trimmed_non_empty_string(
            claims.get(settings.AUTH0_FULL_NAME_CLAIM)
        )
        token_name = _trimmed_non_empty_string(claims.get("name"))
        userinfo = {}
        if (
            any(claims.get(field) is None for field in ("email", "picture"))
            or (full_name_claim is None and token_name is None)
        ):
            userinfo = await fetch_userinfo(proto_req.access_token)

        user = await get_or_create_user(
            session=session,
            sub=claims["sub"],
            email=_first_non_empty(
                claims.get("email"),
                userinfo.get("email"),
                proto_req.email,
            ),
            name=_first_non_empty(
                full_name_claim,
                token_name,
                _trimmed_non_empty_string(userinfo.get("name")),
                _trimmed_non_empty_string(proto_req.name),
            ),
            avatar_url=_first_non_empty(
                claims.get("picture"),
                userinfo.get("picture"),
                proto_req.avatar_url,
            ),
        )
        await session.commit()
        return _pb_response(
            auth_pb2.LoginResponse(
                success=True,
                user_id=str(user.id),
                auth0_sub=user.sub,
                email=user.email or "",
            )
        )
    except Exception as exc:
        await session.rollback()
        return _pb_response(
            auth_pb2.LoginResponse(success=False, message=_error_message(exc)),
            _status_for_exc(exc),
        )


@api_app.post("/auth/verify")
async def verify(request: Request) -> ProtobufResponse:
    body = await request.body()
    proto_req = auth_pb2.TokenVerifyRequest()
    proto_req.ParseFromString(body)
    try:
        claims = await verify_token(proto_req.access_token)
        return _pb_response(
            auth_pb2.TokenVerifyResponse(
                valid=True,
                auth0_sub=claims["sub"],
                email=claims.get("email", ""),
                expires_at=int(claims["exp"]),
            )
        )
    except Exception as exc:
        return _pb_response(
            auth_pb2.TokenVerifyResponse(valid=False, message=_error_message(exc)),
            _status_for_exc(exc),
        )


@api_app.post("/users/me")
async def get_me(request: Request, session: AsyncSession = Depends(get_session)) -> ProtobufResponse:
    try:
        user = await _current_user(request, session)
        await session.commit()
        return _pb_response(debt_pb2.UserResponse(success=True, user=_user_to_pb(user)))
    except Exception as exc:
        await session.rollback()
        return _error_response(debt_pb2.UserResponse, exc)


@api_app.post("/users/update")
async def update_me(request: Request, session: AsyncSession = Depends(get_session)) -> ProtobufResponse:
    body = await request.body()
    proto_req = debt_pb2.UpdateUserRequest()
    proto_req.ParseFromString(body)
    try:
        user = await _current_user(request, session)
        user = await update_user_profile(
            session=session,
            user_id=user.id,
            email=proto_req.email if _has_field(proto_req, "email") else None,
            name=proto_req.name if _has_field(proto_req, "name") else None,
            avatar_url=proto_req.avatar_url if _has_field(proto_req, "avatar_url") else None,
        )
        await session.commit()
        return _pb_response(debt_pb2.UserResponse(success=True, user=_user_to_pb(user)))
    except Exception as exc:
        await session.rollback()
        return _error_response(debt_pb2.UserResponse, exc)


@api_app.post("/users/search")
async def search_users_route(request: Request, session: AsyncSession = Depends(get_session)) -> ProtobufResponse:
    body = await request.body()
    proto_req = debt_pb2.UserSearchRequest()
    proto_req.ParseFromString(body)
    try:
        user = await _current_user(request, session)
        limit = proto_req.limit if _has_field(proto_req, "limit") else 10
        users = await search_users_by_prefix(
            session,
            proto_req.query,
            exclude_user_id=user.id,
            limit=limit,
        )
        await session.commit()
        resp = debt_pb2.UsersResponse(success=True)
        for matched_user in users:
            resp.users.add().CopyFrom(_user_to_pb(matched_user))
        return _pb_response(resp)
    except Exception as exc:
        await session.rollback()
        return _error_response(debt_pb2.UsersResponse, exc)


@api_app.post("/users/delete")
async def delete_me(request: Request, session: AsyncSession = Depends(get_session)) -> ProtobufResponse:
    try:
        user = await _current_user(request, session)
        storage_keys = await delete_user(session, user.id)
        await session.commit()
        for storage_key in storage_keys:
            _delete_managed_file(storage_key)
        return _pb_response(debt_pb2.ActionResponse(success=True, message="User deleted"))
    except Exception as exc:
        await session.rollback()
        return _error_response(debt_pb2.ActionResponse, exc)


@api_app.post("/recipients/create")
async def create_recipient_route(request: Request, session: AsyncSession = Depends(get_session)) -> ProtobufResponse:
    body = await request.body()
    proto_req = debt_pb2.CreateRecipientRequest()
    proto_req.ParseFromString(body)
    try:
        user = await _current_user(request, session)
        recipient = await create_recipient(
            session=session,
            owner_id=user.id,
            name=proto_req.name,
            description=proto_req.description if _has_field(proto_req, "description") else None,
            member_ids=list(proto_req.member_ids),
        )
        await session.commit()
        recipient = await get_recipient_by_id(session, recipient.id)
        return _pb_response(debt_pb2.RecipientResponse(success=True, recipient=_recipient_to_pb(recipient)))
    except Exception as exc:
        await session.rollback()
        return _error_response(debt_pb2.RecipientResponse, exc)


@api_app.post("/recipients/get")
async def get_recipient_route(request: Request, session: AsyncSession = Depends(get_session)) -> ProtobufResponse:
    body = await request.body()
    proto_req = debt_pb2.RecipientLookupRequest()
    proto_req.ParseFromString(body)
    try:
        user = await _current_user(request, session)
        recipient = await _authorize_message_resource(
            request,
            session,
            user,
            authorization.ResourceType.RECIPIENT,
            "recipient_id",
            proto_req,
            authorization.AccessPolicy.READ,
        )
        await session.commit()
        return _pb_response(debt_pb2.RecipientResponse(success=True, recipient=_recipient_to_pb(recipient)))
    except Exception as exc:
        await session.rollback()
        return _error_response(debt_pb2.RecipientResponse, exc)


@api_app.post("/recipients/list")
async def list_recipients_route(request: Request, session: AsyncSession = Depends(get_session)) -> ProtobufResponse:
    try:
        user = await _current_user(request, session)
        recipients = await list_recipients_for_user(session, user.id)
        await session.commit()
        resp = debt_pb2.RecipientsResponse(success=True)
        for recipient in recipients:
            resp.recipients.add().CopyFrom(_recipient_to_pb(recipient))
        return _pb_response(resp)
    except Exception as exc:
        await session.rollback()
        return _error_response(debt_pb2.RecipientsResponse, exc)


@api_app.post("/recipients/update")
async def update_recipient_route(request: Request, session: AsyncSession = Depends(get_session)) -> ProtobufResponse:
    body = await request.body()
    proto_req = debt_pb2.UpdateRecipientRequest()
    proto_req.ParseFromString(body)
    try:
        user = await _current_user(request, session)
        await _authorize_message_resource(
            request,
            session,
            user,
            authorization.ResourceType.RECIPIENT,
            "recipient_id",
            proto_req,
            authorization.AccessPolicy.MUTATE,
        )
        recipient = await update_recipient(
            session=session,
            recipient_id=proto_req.recipient_id,
            name=proto_req.name if _has_field(proto_req, "name") else None,
            description=proto_req.description if _has_field(proto_req, "description") else None,
        )
        await session.commit()
        recipient = await get_recipient_by_id(session, recipient.id)
        return _pb_response(debt_pb2.RecipientResponse(success=True, recipient=_recipient_to_pb(recipient)))
    except Exception as exc:
        await session.rollback()
        return _error_response(debt_pb2.RecipientResponse, exc)


@api_app.post("/recipients/add-member")
async def add_member_route(request: Request, session: AsyncSession = Depends(get_session)) -> ProtobufResponse:
    body = await request.body()
    proto_req = debt_pb2.RecipientMemberRequest()
    proto_req.ParseFromString(body)
    try:
        user = await _current_user(request, session)
        await _authorize_message_resource(
            request,
            session,
            user,
            authorization.ResourceType.RECIPIENT,
            "recipient_id",
            proto_req,
            authorization.AccessPolicy.MANAGE_MEMBERS,
        )
        await add_member_to_recipient(session, proto_req.recipient_id, proto_req.user_id)
        await session.commit()
        return _pb_response(debt_pb2.ActionResponse(success=True, message="Member added"))
    except Exception as exc:
        await session.rollback()
        return _error_response(debt_pb2.ActionResponse, exc)


@api_app.post("/recipients/remove-member")
async def remove_member_route(request: Request, session: AsyncSession = Depends(get_session)) -> ProtobufResponse:
    body = await request.body()
    proto_req = debt_pb2.RecipientMemberRequest()
    proto_req.ParseFromString(body)
    try:
        user = await _current_user(request, session)
        await _authorize_message_resource(
            request,
            session,
            user,
            authorization.ResourceType.RECIPIENT,
            "recipient_id",
            proto_req,
            authorization.AccessPolicy.MANAGE_MEMBERS,
        )
        await remove_member_from_recipient(session, proto_req.recipient_id, proto_req.user_id)
        await session.commit()
        return _pb_response(debt_pb2.ActionResponse(success=True, message="Member removed"))
    except Exception as exc:
        await session.rollback()
        return _error_response(debt_pb2.ActionResponse, exc)


@api_app.post("/recipients/delete")
async def delete_recipient_route(request: Request, session: AsyncSession = Depends(get_session)) -> ProtobufResponse:
    body = await request.body()
    proto_req = debt_pb2.RecipientLookupRequest()
    proto_req.ParseFromString(body)
    try:
        user = await _current_user(request, session)
        await _authorize_message_resource(
            request,
            session,
            user,
            authorization.ResourceType.RECIPIENT,
            "recipient_id",
            proto_req,
            authorization.AccessPolicy.DELETE,
        )
        await delete_recipient(session, proto_req.recipient_id)
        await session.commit()
        return _pb_response(debt_pb2.ActionResponse(success=True, message="Recipient deleted"))
    except Exception as exc:
        await session.rollback()
        return _error_response(debt_pb2.ActionResponse, exc)


@api_app.post("/receipts/create")
async def create_receipt_route(request: Request, session: AsyncSession = Depends(get_session)) -> ProtobufResponse:
    body = await request.body()
    proto_req = debt_pb2.CreateReceiptRequest()
    proto_req.ParseFromString(body)
    try:
        user = await _current_user(request, session)
        recipient_id = proto_req.recipient_id if _has_field(proto_req, "recipient_id") else None
        if recipient_id is not None:
            await _authorize_message_resource(
                request,
                session,
                user,
                authorization.ResourceType.RECIPIENT,
                "recipient_id",
                proto_req,
                authorization.AccessPolicy.READ,
            )
        receipt = await create_receipt(
            session=session,
            owner_id=user.id,
            title=proto_req.title,
            amount_owed=proto_req.amount_owed,
            currency=proto_req.currency if _has_field(proto_req, "currency") else "EUR",
            recipient_id=recipient_id,
            description=proto_req.description if _has_field(proto_req, "description") else None,
            due_date=_dt_from_proto(proto_req.due_date if _has_field(proto_req, "due_date") else None),
            notes=proto_req.notes if _has_field(proto_req, "notes") else None,
        )
        if _has_field(proto_req, "split"):
            owner_share_percent, recipient_shares = _split_input_from_pb(proto_req.split)
            await services.set_receipt_split_for_owner(
                session=session,
                actor_user_id=user.id,
                receipt_id=receipt.id,
                owner_share_percent=owner_share_percent,
                recipient_shares=recipient_shares,
            )
        await session.commit()
        receipt = await get_receipt_by_id(session, receipt.id)
        return _pb_response(debt_pb2.ReceiptResponse(success=True, receipt=_receipt_to_pb(receipt)))
    except Exception as exc:
        await session.rollback()
        return _error_response(debt_pb2.ReceiptResponse, exc)


@api_app.post("/receipts/get")
async def get_receipt_route(request: Request, session: AsyncSession = Depends(get_session)) -> ProtobufResponse:
    body = await request.body()
    proto_req = debt_pb2.ReceiptLookupRequest()
    proto_req.ParseFromString(body)
    try:
        user = await _current_user(request, session)
        receipt = await _authorize_message_resource(
            request,
            session,
            user,
            authorization.ResourceType.RECEIPT,
            "receipt_id",
            proto_req,
            authorization.AccessPolicy.READ,
        )
        await session.commit()
        return _pb_response(debt_pb2.ReceiptResponse(success=True, receipt=_receipt_to_pb(receipt)))
    except Exception as exc:
        await session.rollback()
        return _error_response(debt_pb2.ReceiptResponse, exc)


@api_app.post("/receipts/list")
async def list_receipts_route(request: Request, session: AsyncSession = Depends(get_session)) -> ProtobufResponse:
    body = await request.body()
    proto_req = debt_pb2.ReceiptListRequest()
    proto_req.ParseFromString(body)
    try:
        user = await _current_user(request, session)
        receipt_page = await services.list_visible_receipts(
            session,
            actor_user_id=user.id,
            is_paid=proto_req.is_paid if _has_field(proto_req, "is_paid") else None,
            tag_ids=list(proto_req.tag_ids) or None,
            cursor=proto_req.cursor if _has_field(proto_req, "cursor") else None,
            page_token=proto_req.page_token if _has_field(proto_req, "page_token") else None,
            limit=proto_req.limit if _has_field(proto_req, "limit") else 20,
            order_by=_receipt_list_order_by(proto_req.order_by),
            order_direction=_receipt_list_order_direction(proto_req.order_direction),
            actor_filter=_receipt_list_actor_filter(proto_req.actor_filter),
        )
        await session.commit()
        resp = debt_pb2.ReceiptsResponse(success=True)
        for receipt in receipt_page.receipts:
            resp.receipts.add().CopyFrom(_receipt_to_pb(receipt))
        if receipt_page.next_page_token is not None:
            resp.next_page_token = receipt_page.next_page_token
        return _pb_response(resp)
    except Exception as exc:
        await session.rollback()
        return _error_response(debt_pb2.ReceiptsResponse, exc)


@api_app.post("/receipts/update")
async def update_receipt_route(request: Request, session: AsyncSession = Depends(get_session)) -> ProtobufResponse:
    body = await request.body()
    proto_req = debt_pb2.UpdateReceiptRequest()
    proto_req.ParseFromString(body)
    try:
        user = await _current_user(request, session)
        if _has_field(proto_req, "amount_paid"):
            raise ValueError(
                "amount_paid is derived; use /receipts/set-payments"
            )
        receipt = await services.update_receipt_for_owner(
            session=session,
            actor_user_id=user.id,
            receipt_id=proto_req.receipt_id,
            title=proto_req.title if _has_field(proto_req, "title") else None,
            description=proto_req.description if _has_field(proto_req, "description") else None,
            amount_owed=proto_req.amount_owed if _has_field(proto_req, "amount_owed") else None,
            amount_paid=None,
            due_date=_dt_from_proto(proto_req.due_date if _has_field(proto_req, "due_date") else None),
            notes=proto_req.notes if _has_field(proto_req, "notes") else None,
            currency=proto_req.currency if _has_field(proto_req, "currency") else None,
        )
        has_split = _has_field(proto_req, "split")
        clear_split = _has_field(proto_req, "clear_split") and proto_req.clear_split
        if has_split and clear_split:
            raise ValueError("split and clear_split cannot both be set")
        if has_split:
            owner_share_percent, recipient_shares = _split_input_from_pb(proto_req.split)
            receipt = await services.set_receipt_split_for_owner(
                session=session,
                actor_user_id=user.id,
                receipt_id=receipt.id,
                owner_share_percent=owner_share_percent,
                recipient_shares=recipient_shares,
            )
        elif clear_split:
            receipt = await services.clear_receipt_split_for_owner(
                session=session,
                actor_user_id=user.id,
                receipt_id=receipt.id,
            )
        await session.commit()
        receipt = await get_receipt_by_id(session, receipt.id)
        return _pb_response(debt_pb2.ReceiptResponse(success=True, receipt=_receipt_to_pb(receipt)))
    except Exception as exc:
        await session.rollback()
        return _error_response(debt_pb2.ReceiptResponse, exc)


@api_app.post("/receipts/set-payments")
async def set_receipt_payments_route(request: Request, session: AsyncSession = Depends(get_session)) -> ProtobufResponse:
    body = await request.body()
    proto_req = debt_pb2.SetReceiptPaymentsRequest()
    proto_req.ParseFromString(body)
    try:
        user = await _current_user(request, session)
        receipt = await services.set_receipt_payments_for_owner(
            session=session,
            actor_user_id=user.id,
            receipt_id=proto_req.receipt_id,
            payments=_payment_inputs_from_pb(proto_req),
        )
        await session.commit()
        receipt = await get_receipt_by_id(session, receipt.id)
        return _pb_response(debt_pb2.ReceiptResponse(success=True, receipt=_receipt_to_pb(receipt)))
    except Exception as exc:
        await session.rollback()
        return _error_response(debt_pb2.ReceiptResponse, exc)


@api_app.post("/receipts/mark-paid")
async def mark_receipt_paid_route(request: Request, session: AsyncSession = Depends(get_session)) -> ProtobufResponse:
    body = await request.body()
    proto_req = debt_pb2.MarkReceiptPaidRequest()
    proto_req.ParseFromString(body)
    try:
        user = await _current_user(request, session)
        receipt = await services.mark_receipt_paid_for_owner(
            session=session,
            actor_user_id=user.id,
            receipt_id=proto_req.receipt_id,
            amount_paid=proto_req.amount_paid if _has_field(proto_req, "amount_paid") else None,
        )
        await session.commit()
        receipt = await get_receipt_by_id(session, receipt.id)
        return _pb_response(debt_pb2.ReceiptResponse(success=True, receipt=_receipt_to_pb(receipt)))
    except Exception as exc:
        await session.rollback()
        return _error_response(debt_pb2.ReceiptResponse, exc)


@api_app.post("/receipts/mark-unpaid")
async def mark_receipt_unpaid_route(request: Request, session: AsyncSession = Depends(get_session)) -> ProtobufResponse:
    body = await request.body()
    proto_req = debt_pb2.ReceiptLookupRequest()
    proto_req.ParseFromString(body)
    try:
        user = await _current_user(request, session)
        receipt = await services.mark_receipt_unpaid_for_owner(
            session=session,
            actor_user_id=user.id,
            receipt_id=proto_req.receipt_id,
        )
        await session.commit()
        receipt = await get_receipt_by_id(session, receipt.id)
        return _pb_response(debt_pb2.ReceiptResponse(success=True, receipt=_receipt_to_pb(receipt)))
    except Exception as exc:
        await session.rollback()
        return _error_response(debt_pb2.ReceiptResponse, exc)


@api_app.post("/receipts/delete")
async def delete_receipt_route(request: Request, session: AsyncSession = Depends(get_session)) -> ProtobufResponse:
    body = await request.body()
    proto_req = debt_pb2.ReceiptLookupRequest()
    proto_req.ParseFromString(body)
    try:
        user = await _current_user(request, session)
        storage_keys = await services.delete_receipt_for_owner(
            session=session,
            actor_user_id=user.id,
            receipt_id=proto_req.receipt_id,
        )
        await session.commit()
        for storage_key in storage_keys:
            _delete_managed_file(storage_key)
        return _pb_response(debt_pb2.ActionResponse(success=True, message="Receipt deleted"))
    except Exception as exc:
        await session.rollback()
        return _error_response(debt_pb2.ActionResponse, exc)


@api_app.post("/files/attach")
async def attach_file_route(request: Request, session: AsyncSession = Depends(get_session)) -> ProtobufResponse:
    body = await request.body()
    proto_req = debt_pb2.ReceiptFileRequest()
    proto_req.ParseFromString(body)
    try:
        user = await _current_user(request, session)
        file_record = await services.create_receipt_file_for_owner(
            session=session,
            actor_user_id=user.id,
            receipt_id=proto_req.receipt_id,
            client_filename=proto_req.original_filename,
            content_type=proto_req.content_type if _has_field(proto_req, "content_type") else None,
            size_bytes=proto_req.size_bytes if _has_field(proto_req, "size_bytes") else None,
            sha256=proto_req.sha256 if _has_field(proto_req, "sha256") else None,
        )
        await session.commit()
        return _pb_response(debt_pb2.FileResponse(success=True, file=_file_to_pb(file_record)))
    except Exception as exc:
        await session.rollback()
        return _error_response(debt_pb2.FileResponse, exc)


@api_app.post("/files/upload")
async def upload_file_route(
    request: Request,
    receipt_id: int = Form(...),
    file: UploadFile = File(...),
    session: AsyncSession = Depends(get_session),
) -> ProtobufResponse:
    try:
        user = await _current_user(request, session)
        payload = await file.read()
        filename = file.filename or "file"
        content_type = file.content_type or "application/octet-stream"
        sha256 = hashlib.sha256(payload).hexdigest()
        file_record = await services.create_receipt_file_for_owner(
            session=session,
            actor_user_id=user.id,
            receipt_id=receipt_id,
            client_filename=filename,
            content_type=content_type,
            size_bytes=len(payload),
            sha256=sha256,
        )
        target_path = resolve_storage_path(file_record.storage_key, _upload_root())
        target_path.parent.mkdir(parents=True, exist_ok=True)
        try:
            async with aiofiles.open(target_path, "wb") as handle:
                await handle.write(payload)
        except Exception:
            await session.rollback()
            target_path.unlink(missing_ok=True)
            raise

        await session.commit()
        return _pb_response(debt_pb2.FileResponse(success=True, file=_file_to_pb(file_record)))
    except Exception as exc:
        await session.rollback()
        return _error_response(debt_pb2.FileResponse, exc)


@api_app.post("/files/get")
async def get_file_route(request: Request, session: AsyncSession = Depends(get_session)) -> ProtobufResponse:
    body = await request.body()
    proto_req = debt_pb2.FileLookupRequest()
    proto_req.ParseFromString(body)
    try:
        user = await _current_user(request, session)
        file_record = await _authorize_message_resource(
            request,
            session,
            user,
            authorization.ResourceType.FILE,
            "file_id",
            proto_req,
            authorization.AccessPolicy.READ,
        )
        await session.commit()
        return _pb_response(debt_pb2.FileResponse(success=True, file=_file_to_pb(file_record)))
    except Exception as exc:
        await session.rollback()
        return _error_response(debt_pb2.FileResponse, exc)


@api_app.get("/files/{file_id}/content")
async def get_file_content_route(
    file_id: int,
    request: Request,
    session: AsyncSession = Depends(get_session),
) -> DownloadFileResponse:
    try:
        user = await _current_user(request, session)
        file_record = await services.get_file_for_actor(session, user.id, file_id)
        path = resolve_storage_path(file_record.storage_key, _upload_root())
        if not path.is_file():
            raise FileNotFoundError("File content not found")
        await session.commit()
        return DownloadFileResponse(
            path,
            media_type=file_record.content_type or "application/octet-stream",
            filename=file_record.original_filename,
            content_disposition_type="inline",
        )
    except Exception as exc:
        await session.rollback()
        raise HTTPException(
            status_code=_status_for_exc(exc),
            detail=_error_message(exc),
        ) from exc


@api_app.post("/files/list")
async def list_files_route(request: Request, session: AsyncSession = Depends(get_session)) -> ProtobufResponse:
    body = await request.body()
    proto_req = debt_pb2.FileListRequest()
    proto_req.ParseFromString(body)
    try:
        user = await _current_user(request, session)
        await _authorize_message_resource(
            request,
            session,
            user,
            authorization.ResourceType.RECEIPT,
            "receipt_id",
            proto_req,
            authorization.AccessPolicy.READ,
        )
        files = await list_files_for_receipt(session, proto_req.receipt_id)
        await session.commit()
        resp = debt_pb2.FilesResponse(success=True)
        for file_record in files:
            resp.files.add().CopyFrom(_file_to_pb(file_record))
        return _pb_response(resp)
    except Exception as exc:
        await session.rollback()
        return _error_response(debt_pb2.FilesResponse, exc)


@api_app.post("/files/delete")
async def delete_file_route(request: Request, session: AsyncSession = Depends(get_session)) -> ProtobufResponse:
    body = await request.body()
    proto_req = debt_pb2.FileLookupRequest()
    proto_req.ParseFromString(body)
    try:
        user = await _current_user(request, session)
        file_record = await _authorize_message_resource(
            request,
            session,
            user,
            authorization.ResourceType.FILE,
            "file_id",
            proto_req,
            authorization.AccessPolicy.DELETE,
        )
        storage_key = await services.delete_file_for_owner(session, user.id, file_record.id)
        await session.commit()
        _delete_managed_file(storage_key)
        return _pb_response(debt_pb2.ActionResponse(success=True, message="File deleted"))
    except Exception as exc:
        await session.rollback()
        return _error_response(debt_pb2.ActionResponse, exc)


@api_app.post("/tags/get-or-create")
async def get_or_create_tag_route(request: Request, session: AsyncSession = Depends(get_session)) -> ProtobufResponse:
    body = await request.body()
    proto_req = debt_pb2.TagUpsertRequest()
    proto_req.ParseFromString(body)
    try:
        await _current_user(request, session)
        tag = await get_or_create_tag(session, proto_req.text, proto_req.icon, proto_req.color)
        await session.commit()
        return _pb_response(debt_pb2.TagResponse(success=True, tag=_tag_to_pb(tag)))
    except Exception as exc:
        await session.rollback()
        return _error_response(debt_pb2.TagResponse, exc)


@api_app.post("/tags/get")
async def get_tag_route(request: Request, session: AsyncSession = Depends(get_session)) -> ProtobufResponse:
    body = await request.body()
    proto_req = debt_pb2.TagLookupRequest()
    proto_req.ParseFromString(body)
    try:
        await _current_user(request, session)
        if _has_field(proto_req, "tag_id"):
            tag = await get_tag_by_id(session, proto_req.tag_id)
        elif _has_field(proto_req, "text"):
            tag = await get_tag_by_text(session, proto_req.text)
        else:
            raise ValueError("tag_id or text required")
        if tag is None:
            raise ValueError("Tag not found")
        await session.commit()
        return _pb_response(debt_pb2.TagResponse(success=True, tag=_tag_to_pb(tag)))
    except Exception as exc:
        await session.rollback()
        return _error_response(debt_pb2.TagResponse, exc)


@api_app.post("/tags/list")
async def list_tags_route(request: Request, session: AsyncSession = Depends(get_session)) -> ProtobufResponse:
    try:
        await _current_user(request, session)
        tags = await list_all_tags(session)
        await session.commit()
        resp = debt_pb2.TagsResponse(success=True)
        for tag in tags:
            resp.tags.add().CopyFrom(_tag_to_pb(tag))
        return _pb_response(resp)
    except Exception as exc:
        await session.rollback()
        return _error_response(debt_pb2.TagsResponse, exc)


@api_app.post("/tags/recommended")
async def list_recommended_tags_route(request: Request, session: AsyncSession = Depends(get_session)) -> ProtobufResponse:
    try:
        user = await _current_user(request, session)
        tags = await list_visible_recommended_tags(session, user.id)
        await session.commit()
        resp = debt_pb2.TagsResponse(success=True)
        for tag in tags:
            resp.tags.add().CopyFrom(_tag_to_pb(tag))
        return _pb_response(resp)
    except Exception as exc:
        await session.rollback()
        return _error_response(debt_pb2.TagsResponse, exc)


@api_app.post("/tags/update")
async def update_tag_route(request: Request, session: AsyncSession = Depends(get_session)) -> ProtobufResponse:
    body = await request.body()
    proto_req = debt_pb2.UpdateTagRequest()
    proto_req.ParseFromString(body)
    try:
        await _current_user(request, session)
        tag = await update_tag(
            session=session,
            tag_id=proto_req.tag_id,
            icon=proto_req.icon if _has_field(proto_req, "icon") else None,
            color=proto_req.color if _has_field(proto_req, "color") else None,
        )
        await session.commit()
        return _pb_response(debt_pb2.TagResponse(success=True, tag=_tag_to_pb(tag)))
    except Exception as exc:
        await session.rollback()
        return _error_response(debt_pb2.TagResponse, exc)


@api_app.post("/tags/delete")
async def delete_tag_route(request: Request, session: AsyncSession = Depends(get_session)) -> ProtobufResponse:
    body = await request.body()
    proto_req = debt_pb2.TagLookupRequest()
    proto_req.ParseFromString(body)
    try:
        await _current_user(request, session)
        if not _has_field(proto_req, "tag_id"):
            raise ValueError("tag_id required")
        await delete_tag(session, proto_req.tag_id)
        await session.commit()
        return _pb_response(debt_pb2.ActionResponse(success=True, message="Tag deleted"))
    except Exception as exc:
        await session.rollback()
        return _error_response(debt_pb2.ActionResponse, exc)


@api_app.post("/receipt-tags/tag")
async def tag_receipt_route(request: Request, session: AsyncSession = Depends(get_session)) -> ProtobufResponse:
    body = await request.body()
    proto_req = debt_pb2.TagReceiptRequest()
    proto_req.ParseFromString(body)
    try:
        user = await _current_user(request, session)
        await _authorize_message_resource(
            request,
            session,
            user,
            authorization.ResourceType.RECEIPT,
            "receipt_id",
            proto_req,
            authorization.AccessPolicy.MUTATE,
        )
        if await get_tag_by_id(session, proto_req.tag_id) is None:
            raise ValueError("Tag not found")
        await tag_receipt(session, proto_req.receipt_id, proto_req.tag_id)
        await session.commit()
        return _pb_response(debt_pb2.ActionResponse(success=True, message="Tag attached"))
    except Exception as exc:
        await session.rollback()
        return _error_response(debt_pb2.ActionResponse, exc)


@api_app.post("/receipt-tags/untag")
async def untag_receipt_route(request: Request, session: AsyncSession = Depends(get_session)) -> ProtobufResponse:
    body = await request.body()
    proto_req = debt_pb2.TagReceiptRequest()
    proto_req.ParseFromString(body)
    try:
        user = await _current_user(request, session)
        await _authorize_message_resource(
            request,
            session,
            user,
            authorization.ResourceType.RECEIPT,
            "receipt_id",
            proto_req,
            authorization.AccessPolicy.MUTATE,
        )
        await untag_receipt(session, proto_req.receipt_id, proto_req.tag_id)
        await session.commit()
        return _pb_response(debt_pb2.ActionResponse(success=True, message="Tag removed"))
    except Exception as exc:
        await session.rollback()
        return _error_response(debt_pb2.ActionResponse, exc)


@api_app.post("/receipt-tags/set")
async def set_receipt_tags_route(request: Request, session: AsyncSession = Depends(get_session)) -> ProtobufResponse:
    body = await request.body()
    proto_req = debt_pb2.SetReceiptTagsRequest()
    proto_req.ParseFromString(body)
    try:
        user = await _current_user(request, session)
        await _authorize_message_resource(
            request,
            session,
            user,
            authorization.ResourceType.RECEIPT,
            "receipt_id",
            proto_req,
            authorization.AccessPolicy.MUTATE,
        )
        for tag_id in proto_req.tag_ids:
            if await get_tag_by_id(session, tag_id) is None:
                raise ValueError(f"Tag {tag_id} not found")
        await services.set_receipt_tags_for_owner(
            session=session,
            actor_user_id=user.id,
            receipt_id=proto_req.receipt_id,
            tag_ids=list(proto_req.tag_ids),
        )
        await session.commit()
        return _pb_response(debt_pb2.ActionResponse(success=True, message="Receipt tags updated"))
    except Exception as exc:
        await session.rollback()
        return _error_response(debt_pb2.ActionResponse, exc)
