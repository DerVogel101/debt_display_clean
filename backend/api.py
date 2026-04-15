from __future__ import annotations

import re
from datetime import datetime, timezone
from pathlib import Path
from uuid import uuid4

from fastapi import Depends, FastAPI, HTTPException, Request
from fastapi.responses import Response
from sqlalchemy.ext.asyncio import AsyncSession

from backend.auth import require_auth, verify_token
from backend.db import (
    add_member_to_recipient,
    create_recipient,
    delete_recipient,
    delete_user,
    get_file_by_id,
    get_or_create_tag,
    get_or_create_user,
    get_recipient_by_id,
    get_receipt_by_id,
    get_tag_by_id,
    get_tag_by_text,
    list_all_tags,
    list_files_for_receipt,
    list_recipients_for_user,
    list_receipts_for_owner,
    mark_receipt_paid,
    mark_receipt_unpaid,
    remove_member_from_recipient,
    set_receipt_tags,
    tag_receipt,
    untag_receipt,
    update_recipient,
    update_receipt,
    update_tag,
    update_user_profile,
    attach_file,
    create_receipt,
    delete_file_record,
    delete_receipt, delete_tag,
)
from backend.db import get_session
from backend.config import settings
from backend.proto import auth_pb2, debt_pb2

api_app = FastAPI(title="api")


class ProtobufResponse(Response):
    media_type = "application/x-protobuf"


def _first_non_empty(*values: str | None) -> str | None:
    for value in values:
        if value:
            return value
    return None


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


def _sanitize_filename(filename: str) -> str:
    candidate = Path(filename).name.strip()
    if not candidate:
        candidate = "file"
    sanitized = re.sub(r"[^A-Za-z0-9._-]+", "_", candidate).strip("._")
    return sanitized or "file"


def _build_storage_key(owner_id: int, receipt_id: int, original_filename: str) -> str:
    safe_name = _sanitize_filename(original_filename)
    suffix = Path(safe_name).suffix
    generated_name = f"{uuid4().hex}{suffix}"
    return Path(str(owner_id), str(receipt_id), generated_name).as_posix()


def _resolve_managed_storage_path(storage_key: str) -> Path | None:
    root = _upload_root()
    candidate = Path(storage_key)
    resolved = candidate.resolve() if candidate.is_absolute() else (root / candidate).resolve()
    try:
        resolved.relative_to(root)
    except ValueError:
        return None
    return resolved


def _delete_managed_file(storage_key: str) -> bool:
    resolved = _resolve_managed_storage_path(storage_key)
    if resolved is None:
        return False
    resolved.unlink(missing_ok=True)
    return True


def _has_field(message, field: str) -> bool:
    try:
        return message.HasField(field)
    except ValueError:
        return False


def _status_for_exc(exc: Exception) -> int:
    if isinstance(exc, HTTPException):
        return exc.status_code
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
    return msg


async def _current_user(request: Request, session: AsyncSession):
    claims = await require_auth(request)
    return await get_or_create_user(
        session=session,
        sub=claims["sub"],
        email=claims.get("email"),
        name=claims.get("name"),
        avatar_url=claims.get("picture"),
    )


async def _require_recipient_access(session: AsyncSession, recipient_id: int, user_id: int):
    recipient = await get_recipient_by_id(session, recipient_id)
    if recipient is None:
        raise ValueError(f"Recipient {recipient_id} not found")
    if recipient.owner_id != user_id and all(member.id != user_id for member in recipient.members):
        raise HTTPException(status_code=403, detail="Forbidden")
    return recipient


async def _require_recipient_owner(session: AsyncSession, recipient_id: int, user_id: int):
    recipient = await get_recipient_by_id(session, recipient_id)
    if recipient is None:
        raise ValueError(f"Recipient {recipient_id} not found")
    if recipient.owner_id != user_id:
        raise HTTPException(status_code=403, detail="Forbidden")
    return recipient


async def _require_receipt_owner(session: AsyncSession, receipt_id: int, user_id: int):
    receipt = await get_receipt_by_id(session, receipt_id)
    if receipt is None:
        raise ValueError(f"Receipt {receipt_id} not found")
    if receipt.owner_id != user_id:
        raise HTTPException(status_code=403, detail="Forbidden")
    return receipt


async def _require_file_owner(session: AsyncSession, file_id: int, user_id: int):
    file_record = await get_file_by_id(session, file_id)
    if file_record is None:
        raise ValueError(f"ReceiptFile {file_id} not found")
    await _require_receipt_owner(session, file_record.receipt_id, user_id)
    return file_record


@api_app.post("/auth/login")
async def login(request: Request, session: AsyncSession = Depends(get_session)) -> ProtobufResponse:
    body = await request.body()
    proto_req = auth_pb2.LoginRequest()
    proto_req.ParseFromString(body)
    try:
        claims = await verify_token(proto_req.access_token)
        user = await get_or_create_user(
            session=session,
            sub=claims["sub"],
            email=_first_non_empty(claims.get("email"), proto_req.email or None),
            name=_first_non_empty(claims.get("name"), proto_req.name or None),
            avatar_url=_first_non_empty(claims.get("picture"), proto_req.avatar_url or None),
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
        recipient = await _require_recipient_access(session, proto_req.recipient_id, user.id)
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
        await _require_recipient_owner(session, proto_req.recipient_id, user.id)
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
        await _require_recipient_owner(session, proto_req.recipient_id, user.id)
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
        await _require_recipient_owner(session, proto_req.recipient_id, user.id)
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
        await _require_recipient_owner(session, proto_req.recipient_id, user.id)
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
            await _require_recipient_access(session, recipient_id, user.id)
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
        receipt = await _require_receipt_owner(session, proto_req.receipt_id, user.id)
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
        receipts = await list_receipts_for_owner(
            session,
            owner_id=user.id,
            is_paid=proto_req.is_paid if _has_field(proto_req, "is_paid") else None,
            tag_ids=list(proto_req.tag_ids) or None,
            cursor=proto_req.cursor if _has_field(proto_req, "cursor") else None,
            limit=proto_req.limit if _has_field(proto_req, "limit") else 20,
        )
        await session.commit()
        resp = debt_pb2.ReceiptsResponse(success=True)
        for receipt in receipts:
            resp.receipts.add().CopyFrom(_receipt_to_pb(receipt))
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
        await _require_receipt_owner(session, proto_req.receipt_id, user.id)
        receipt = await update_receipt(
            session=session,
            receipt_id=proto_req.receipt_id,
            title=proto_req.title if _has_field(proto_req, "title") else None,
            description=proto_req.description if _has_field(proto_req, "description") else None,
            amount_owed=proto_req.amount_owed if _has_field(proto_req, "amount_owed") else None,
            amount_paid=proto_req.amount_paid if _has_field(proto_req, "amount_paid") else None,
            due_date=_dt_from_proto(proto_req.due_date if _has_field(proto_req, "due_date") else None),
            notes=proto_req.notes if _has_field(proto_req, "notes") else None,
            currency=proto_req.currency if _has_field(proto_req, "currency") else None,
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
        await _require_receipt_owner(session, proto_req.receipt_id, user.id)
        receipt = await mark_receipt_paid(
            session=session,
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
        await _require_receipt_owner(session, proto_req.receipt_id, user.id)
        receipt = await mark_receipt_unpaid(session=session, receipt_id=proto_req.receipt_id)
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
        await _require_receipt_owner(session, proto_req.receipt_id, user.id)
        storage_keys = await delete_receipt(session, proto_req.receipt_id)
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
        receipt = await _require_receipt_owner(session, proto_req.receipt_id, user.id)
        storage_key = _build_storage_key(receipt.owner_id, receipt.id, proto_req.original_filename)
        file_record = await attach_file(
            session=session,
            receipt_id=proto_req.receipt_id,
            storage_key=storage_key,
            original_filename=proto_req.original_filename,
            content_type=proto_req.content_type if _has_field(proto_req, "content_type") else None,
            size_bytes=proto_req.size_bytes if _has_field(proto_req, "size_bytes") else None,
            sha256=proto_req.sha256 if _has_field(proto_req, "sha256") else None,
        )
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
        if proto_req.file_id <= 0:
            raise ValueError("file_id required")
        file_record = await _require_file_owner(session, proto_req.file_id, user.id)
        await session.commit()
        return _pb_response(debt_pb2.FileResponse(success=True, file=_file_to_pb(file_record)))
    except Exception as exc:
        await session.rollback()
        return _error_response(debt_pb2.FileResponse, exc)


@api_app.post("/files/list")
async def list_files_route(request: Request, session: AsyncSession = Depends(get_session)) -> ProtobufResponse:
    body = await request.body()
    proto_req = debt_pb2.FileListRequest()
    proto_req.ParseFromString(body)
    try:
        user = await _current_user(request, session)
        await _require_receipt_owner(session, proto_req.receipt_id, user.id)
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
        if proto_req.file_id <= 0:
            raise ValueError("file_id required")
        file_record = await _require_file_owner(session, proto_req.file_id, user.id)
        storage_key = await delete_file_record(session, file_record.id)
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
        await _require_receipt_owner(session, proto_req.receipt_id, user.id)
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
        await _require_receipt_owner(session, proto_req.receipt_id, user.id)
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
        await _require_receipt_owner(session, proto_req.receipt_id, user.id)
        for tag_id in proto_req.tag_ids:
            if await get_tag_by_id(session, tag_id) is None:
                raise ValueError(f"Tag {tag_id} not found")
        await set_receipt_tags(session, proto_req.receipt_id, list(proto_req.tag_ids))
        await session.commit()
        return _pb_response(debt_pb2.ActionResponse(success=True, message="Receipt tags updated"))
    except Exception as exc:
        await session.rollback()
        return _error_response(debt_pb2.ActionResponse, exc)
