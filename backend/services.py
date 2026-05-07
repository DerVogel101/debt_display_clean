from __future__ import annotations

import base64
import json
from dataclasses import asdict, dataclass
from datetime import datetime

from sqlalchemy import and_, case, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from backend import db
from backend.db import (
    Receipt,
    ReceiptFile,
    ReceiptRecipientShare,
    Recipient,
    TaggedReceipt,
    recipient_members,
)
from backend.storage import generate_storage_key, sanitize_download_filename


class ResourceNotFoundError(LookupError):
    pass


class AuthorizationError(PermissionError):
    pass


@dataclass(frozen=True)
class ReceiptPage:
    receipts: list[Receipt]
    next_page_token: str | None = None


@dataclass(frozen=True)
class ReceiptUnpaidSummary:
    unpaid_share_total: float
    unpaid_bill_count: int


@dataclass(frozen=True)
class _ReceiptSortSpec:
    order_by: str
    order_direction: str
    primary_expr: object
    null_rank_expr: object | None = None


@dataclass(frozen=True)
class _ReceiptPageToken:
    version: int
    actor_user_id: int
    order_by: str
    order_direction: str
    actor_filter: str
    is_paid: bool | None
    tag_ids: list[int]
    receipt_id: int
    primary: float | str | None = None
    null_rank: int | None = None


_TOKEN_VERSION = 1
_PAGE_PRIMARY_LABEL = "_page_primary"
_PAGE_NULL_RANK_LABEL = "_page_null_rank"


def _require_owned_resource(
    resource: Receipt | Recipient | ReceiptFile | None,
    resource_name: str,
    resource_id: int,
    owner_id: int | None,
    actor_user_id: int,
) -> Receipt | Recipient | ReceiptFile:
    if resource is None:
        raise ResourceNotFoundError(f"{resource_name} {resource_id} not found")
    if owner_id != actor_user_id:
        raise AuthorizationError(
            f"User {actor_user_id} cannot mutate {resource_name.lower()} {resource_id}"
        )
    return resource


def _member_recipient_ids(actor_user_id: int):
    return select(recipient_members.c.recipient_id).where(
        recipient_members.c.user_id == actor_user_id
    )


def _receipt_actor_visibility_filter(actor_user_id: int, actor_filter: str):
    in_recipient_group = Receipt.recipient_id.in_(_member_recipient_ids(actor_user_id))

    if actor_filter == "owner":
        return Receipt.owner_id == actor_user_id
    if actor_filter == "recipient_group":
        return in_recipient_group
    return or_(
        Receipt.owner_id == actor_user_id,
        in_recipient_group,
    )


def _receipt_cost_for_user_expr(actor_user_id: int):
    actor_share_percent = (
        select(ReceiptRecipientShare.share_percent)
        .where(
            ReceiptRecipientShare.receipt_id == Receipt.id,
            ReceiptRecipientShare.user_id == actor_user_id,
        )
        .correlate(Receipt)
        .scalar_subquery()
    )
    owner_cost = case(
        (
            Receipt.owner_share_percent.is_not(None),
            Receipt.amount_owed * Receipt.owner_share_percent / 100.0,
        ),
        else_=Receipt.amount_owed,
    )
    member_cost = Receipt.amount_owed * func.coalesce(actor_share_percent, 0.0) / 100.0
    return case(
        (Receipt.owner_id == actor_user_id, owner_cost),
        else_=member_cost,
    )


def _receipt_sort_spec(
    actor_user_id: int,
    order_by: str,
    order_direction: str,
):
    if order_by == "cost_total":
        return _ReceiptSortSpec(
            order_by=order_by,
            order_direction=order_direction,
            primary_expr=Receipt.amount_owed,
        )

    if order_by == "cost_for_user":
        return _ReceiptSortSpec(
            order_by=order_by,
            order_direction=order_direction,
            primary_expr=_receipt_cost_for_user_expr(actor_user_id),
        )

    if order_by == "due_date":
        return _ReceiptSortSpec(
            order_by=order_by,
            order_direction=order_direction,
            primary_expr=Receipt.due_date,
            null_rank_expr=case((Receipt.due_date.is_(None), 1), else_=0),
        )

    return _ReceiptSortSpec(
        order_by="id",
        order_direction=order_direction,
        primary_expr=Receipt.id,
    )


def _receipt_order_by_clauses(spec: _ReceiptSortSpec):
    is_desc = spec.order_direction == "desc"
    primary = spec.primary_expr.desc() if is_desc else spec.primary_expr.asc()

    if spec.order_by == "id":
        return [primary]

    clauses = []
    if spec.null_rank_expr is not None:
        clauses.append(spec.null_rank_expr.asc())
    clauses.extend([primary, Receipt.id.asc()])
    return clauses


def _normalize_tag_ids(tag_ids: list[int] | None) -> list[int]:
    return sorted(set(tag_ids or []))


def _encode_page_token(token: _ReceiptPageToken) -> str:
    raw = json.dumps(asdict(token), separators=(",", ":"), sort_keys=True).encode()
    return base64.urlsafe_b64encode(raw).decode().rstrip("=")


def _decode_page_token(raw_token: str) -> dict[str, object]:
    try:
        padded = raw_token + "=" * (-len(raw_token) % 4)
        decoded = base64.urlsafe_b64decode(padded.encode()).decode()
        payload = json.loads(decoded)
    except Exception as exc:  # pragma: no cover - defensive parsing branch
        raise ValueError("Invalid page token") from exc

    if not isinstance(payload, dict):
        raise ValueError("Invalid page token")
    return payload


def _parse_page_token(
    raw_token: str,
    *,
    actor_user_id: int,
    order_by: str,
    order_direction: str,
    actor_filter: str,
    is_paid: bool | None,
    tag_ids: list[int] | None,
) -> _ReceiptPageToken:
    payload = _decode_page_token(raw_token)

    try:
        token = _ReceiptPageToken(
            version=int(payload["version"]),
            actor_user_id=int(payload["actor_user_id"]),
            order_by=str(payload["order_by"]),
            order_direction=str(payload["order_direction"]),
            actor_filter=str(payload["actor_filter"]),
            is_paid=payload.get("is_paid"),
            tag_ids=[int(tag_id) for tag_id in payload.get("tag_ids", [])],
            receipt_id=int(payload["receipt_id"]),
            primary=payload.get("primary"),
            null_rank=(
                None
                if payload.get("null_rank") is None
                else int(payload["null_rank"])
            ),
        )
    except (KeyError, TypeError, ValueError) as exc:
        raise ValueError("Invalid page token") from exc

    if token.version != _TOKEN_VERSION:
        raise ValueError("Invalid page token")

    if (
        token.actor_user_id != actor_user_id
        or token.order_by != order_by
        or token.order_direction != order_direction
        or token.actor_filter != actor_filter
        or token.is_paid != is_paid
        or token.tag_ids != _normalize_tag_ids(tag_ids)
    ):
        raise ValueError("Page token does not match current receipt list configuration")

    return token


def _receipt_page_value_columns(spec: _ReceiptSortSpec) -> list[object]:
    columns: list[object] = []
    if spec.null_rank_expr is not None:
        columns.append(spec.null_rank_expr.label(_PAGE_NULL_RANK_LABEL))
    if spec.order_by != "id":
        columns.append(spec.primary_expr.label(_PAGE_PRIMARY_LABEL))
    return columns


def _receipt_page_token_filter(
    token: _ReceiptPageToken,
    spec: _ReceiptSortSpec,
):
    receipt_id = token.receipt_id
    is_desc = spec.order_direction == "desc"

    if spec.order_by == "id":
        if is_desc:
            return Receipt.id < receipt_id
        return Receipt.id > receipt_id

    if spec.order_by == "due_date":
        if token.null_rank not in (0, 1):
            raise ValueError("Invalid page token")

        if token.null_rank == 1:
            return and_(spec.null_rank_expr == 1, Receipt.id > receipt_id)

        if not isinstance(token.primary, str):
            raise ValueError("Invalid page token")

        primary_value = datetime.fromisoformat(token.primary)
        compare_primary = (
            spec.primary_expr < primary_value
            if is_desc
            else spec.primary_expr > primary_value
        )
        return or_(
            spec.null_rank_expr > token.null_rank,
            and_(
                spec.null_rank_expr == token.null_rank,
                or_(
                    compare_primary,
                    and_(spec.primary_expr == primary_value, Receipt.id > receipt_id),
                ),
            ),
        )

    if not isinstance(token.primary, (int, float)):
        raise ValueError("Invalid page token")

    primary_value = float(token.primary)
    compare_primary = (
        spec.primary_expr < primary_value
        if is_desc
        else spec.primary_expr > primary_value
    )
    return or_(
        compare_primary,
        and_(spec.primary_expr == primary_value, Receipt.id > receipt_id),
    )


def _build_receipt_page_token(
    row,
    *,
    spec: _ReceiptSortSpec,
    actor_user_id: int,
    actor_filter: str,
    is_paid: bool | None,
    tag_ids: list[int] | None,
) -> str:
    receipt = row[0]
    primary_value = None
    if spec.order_by != "id":
        primary_value = row._mapping[_PAGE_PRIMARY_LABEL]
        if spec.order_by == "due_date":
            primary_value = (
                None if primary_value is None else primary_value.isoformat()
            )
        else:
            primary_value = float(primary_value)

    null_rank = None
    if spec.null_rank_expr is not None:
        null_rank = int(row._mapping[_PAGE_NULL_RANK_LABEL])

    return _encode_page_token(
        _ReceiptPageToken(
            version=_TOKEN_VERSION,
            actor_user_id=actor_user_id,
            order_by=spec.order_by,
            order_direction=spec.order_direction,
            actor_filter=actor_filter,
            is_paid=is_paid,
            tag_ids=_normalize_tag_ids(tag_ids),
            receipt_id=receipt.id,
            primary=primary_value,
            null_rank=null_rank,
        )
    )


def _receipt_cursor_filter(
    cursor: int,
    order_by: str,
    order_direction: str,
):
    if order_by != "id":
        raise ValueError("cursor pagination is only supported when ordering by id")
    if order_direction == "desc":
        return Receipt.id < cursor
    return Receipt.id > cursor


async def get_visible_receipt(
    session: AsyncSession,
    actor_user_id: int,
    receipt_id: int,
) -> Receipt:
    result = await session.execute(
        select(Receipt)
        .where(Receipt.id == receipt_id)
        .where(
            or_(
                Receipt.owner_id == actor_user_id,
                Receipt.recipient_id.in_(_member_recipient_ids(actor_user_id)),
            )
        )
        .options(
            selectinload(Receipt.recipient),
            selectinload(Receipt.recipient_shares),
            selectinload(Receipt.files),
            selectinload(Receipt.tags),
        )
    )
    receipt = result.scalar_one_or_none()
    if receipt is None:
        raise ResourceNotFoundError(f"Receipt {receipt_id} not found or not visible")
    return receipt


async def get_visible_recipient(
    session: AsyncSession,
    actor_user_id: int,
    recipient_id: int,
) -> Recipient:
    result = await session.execute(
        select(Recipient)
        .where(Recipient.id == recipient_id)
        .where(
            or_(
                Recipient.owner_id == actor_user_id,
                Recipient.id.in_(_member_recipient_ids(actor_user_id)),
            )
        )
        .options(selectinload(Recipient.members))
    )
    recipient = result.scalar_one_or_none()
    if recipient is None:
        raise ResourceNotFoundError(
            f"Recipient {recipient_id} not found or not visible"
        )
    return recipient


async def get_owned_recipient(
    session: AsyncSession,
    actor_user_id: int,
    recipient_id: int,
) -> Recipient:
    result = await session.execute(
        select(Recipient)
        .where(Recipient.id == recipient_id)
        .options(selectinload(Recipient.members))
    )
    recipient = result.scalar_one_or_none()
    return _require_owned_resource(
        recipient,
        "Recipient",
        recipient_id,
        recipient.owner_id if recipient is not None else None,
        actor_user_id,
    )


async def get_owned_receipt(
    session: AsyncSession,
    actor_user_id: int,
    receipt_id: int,
) -> Receipt:
    result = await session.execute(
        select(Receipt)
        .where(Receipt.id == receipt_id)
        .options(
            selectinload(Receipt.recipient),
            selectinload(Receipt.recipient_shares),
            selectinload(Receipt.files),
            selectinload(Receipt.tags),
        )
    )
    receipt = result.scalar_one_or_none()
    return _require_owned_resource(
        receipt,
        "Receipt",
        receipt_id,
        receipt.owner_id if receipt is not None else None,
        actor_user_id,
    )


async def list_visible_receipts(
    session: AsyncSession,
    actor_user_id: int,
    is_paid: bool | None = None,
    tag_ids: list[int] | None = None,
    cursor: int | None = None,
    page_token: str | None = None,
    limit: int = 20,
    order_by: str = "id",
    order_direction: str = "asc",
    actor_filter: str = "owner_or_recipient_group",
) -> ReceiptPage:
    spec = _receipt_sort_spec(actor_user_id, order_by, order_direction)
    stmt = select(Receipt).where(
        _receipt_actor_visibility_filter(actor_user_id, actor_filter)
    )

    if is_paid is not None:
        stmt = stmt.where(Receipt.is_paid == is_paid)

    if tag_ids:
        for tag_id in tag_ids:
            stmt = stmt.where(
                Receipt.id.in_(
                    select(TaggedReceipt.receipt_id).where(TaggedReceipt.tag_id == tag_id)
                )
            )

    if cursor is not None and page_token is not None:
        raise ValueError("cursor and page_token cannot be used together")

    if cursor is not None:
        stmt = stmt.where(_receipt_cursor_filter(cursor, order_by, order_direction))
    elif page_token is not None:
        parsed_page_token = _parse_page_token(
            page_token,
            actor_user_id=actor_user_id,
            order_by=spec.order_by,
            order_direction=spec.order_direction,
            actor_filter=actor_filter,
            is_paid=is_paid,
            tag_ids=tag_ids,
        )
        stmt = stmt.where(_receipt_page_token_filter(parsed_page_token, spec))

    stmt = stmt.order_by(
        *_receipt_order_by_clauses(spec)
    ).limit(limit + 1).options(
        selectinload(Receipt.recipient),
        selectinload(Receipt.recipient_shares),
        selectinload(Receipt.files),
        selectinload(Receipt.tags),
    )
    stmt = stmt.add_columns(*_receipt_page_value_columns(spec))

    result = await session.execute(stmt)
    rows = list(result.all())
    has_next_page = len(rows) > limit
    page_rows = rows[:limit]
    receipts = [row[0] for row in page_rows]

    next_page_token = None
    if has_next_page and page_rows:
        next_page_token = _build_receipt_page_token(
            page_rows[-1],
            spec=spec,
            actor_user_id=actor_user_id,
            actor_filter=actor_filter,
            is_paid=is_paid,
            tag_ids=tag_ids,
        )

    return ReceiptPage(receipts=receipts, next_page_token=next_page_token)


async def summarize_visible_unpaid_receipts(
    session: AsyncSession,
    actor_user_id: int,
) -> ReceiptUnpaidSummary:
    result = await session.execute(
        select(Receipt)
        .where(_receipt_actor_visibility_filter(actor_user_id, "owner_or_recipient_group"))
        .where(Receipt.is_paid.is_(False))
        .options(selectinload(Receipt.recipient_shares))
    )
    total = 0.0
    count = 0
    for receipt in result.scalars().all():
        remaining = _remaining_share_for_user(receipt, actor_user_id)
        if remaining > 1e-6:
            total += remaining
            count += 1
    return ReceiptUnpaidSummary(
        unpaid_share_total=total,
        unpaid_bill_count=count,
    )


def _remaining_share_for_user(receipt: Receipt, actor_user_id: int) -> float:
    if receipt.owner_id == actor_user_id:
        if receipt.owner_share_percent is None:
            share_amount = float(receipt.amount_owed)
        else:
            share_amount = float(receipt.amount_owed) * float(receipt.owner_share_percent) / 100.0
        paid = float(receipt.owner_amount_paid or 0.0)
        return max(0.0, share_amount - paid)

    for share in getattr(receipt, "recipient_shares", []) or []:
        if share.user_id == actor_user_id:
            share_amount = float(receipt.amount_owed) * float(share.share_percent) / 100.0
            paid = float(share.amount_paid or 0.0)
            return max(0.0, share_amount - paid)

    return 0.0


async def update_receipt_for_owner(
    session: AsyncSession,
    actor_user_id: int,
    receipt_id: int,
    **changes,
) -> Receipt:
    await get_owned_receipt(session, actor_user_id, receipt_id)
    return await db.update_receipt(session, receipt_id, **changes)


async def set_receipt_split_for_owner(
    session: AsyncSession,
    actor_user_id: int,
    receipt_id: int,
    owner_share_percent: float,
    recipient_shares: list[tuple[int, float]],
) -> Receipt:
    await get_owned_receipt(session, actor_user_id, receipt_id)
    return await db.set_receipt_split(
        session,
        receipt_id=receipt_id,
        owner_share_percent=owner_share_percent,
        recipient_shares=recipient_shares,
    )


async def clear_receipt_split_for_owner(
    session: AsyncSession,
    actor_user_id: int,
    receipt_id: int,
) -> Receipt:
    await get_owned_receipt(session, actor_user_id, receipt_id)
    return await db.clear_receipt_split(session, receipt_id=receipt_id)


async def mark_receipt_paid_for_owner(
    session: AsyncSession,
    actor_user_id: int,
    receipt_id: int,
    amount_paid: float | None = None,
) -> Receipt:
    await get_owned_receipt(session, actor_user_id, receipt_id)
    return await db.mark_receipt_paid(session, receipt_id, amount_paid=amount_paid)


async def set_receipt_payments_for_owner(
    session: AsyncSession,
    actor_user_id: int,
    receipt_id: int,
    payments: list[tuple[int | None, float]],
) -> Receipt:
    await get_owned_receipt(session, actor_user_id, receipt_id)
    return await db.set_receipt_payments(session, receipt_id, payments)


async def mark_receipt_unpaid_for_owner(
    session: AsyncSession,
    actor_user_id: int,
    receipt_id: int,
) -> Receipt:
    await get_owned_receipt(session, actor_user_id, receipt_id)
    return await db.mark_receipt_unpaid(session, receipt_id)


async def delete_receipt_for_owner(
    session: AsyncSession,
    actor_user_id: int,
    receipt_id: int,
) -> list[str]:
    await get_owned_receipt(session, actor_user_id, receipt_id)
    return await db.delete_receipt(session, receipt_id)


async def set_receipt_tags_for_owner(
    session: AsyncSession,
    actor_user_id: int,
    receipt_id: int,
    tag_ids: list[int],
) -> None:
    await get_owned_receipt(session, actor_user_id, receipt_id)
    await db.set_receipt_tags(session, receipt_id, tag_ids)


async def create_receipt_file_for_owner(
    session: AsyncSession,
    actor_user_id: int,
    receipt_id: int,
    client_filename: str,
    content_type: str | None = None,
    size_bytes: int | None = None,
    sha256: str | None = None,
) -> ReceiptFile:
    await get_owned_receipt(session, actor_user_id, receipt_id)
    return await db.attach_file(
        session=session,
        receipt_id=receipt_id,
        storage_key=generate_storage_key(receipt_id),
        original_filename=sanitize_download_filename(client_filename),
        content_type=content_type,
        size_bytes=size_bytes,
        sha256=sha256,
    )


async def get_file_for_actor(
    session: AsyncSession,
    actor_user_id: int,
    file_id: int,
) -> ReceiptFile:
    result = await session.execute(
        select(ReceiptFile)
        .join(Receipt, Receipt.id == ReceiptFile.receipt_id)
        .where(ReceiptFile.id == file_id)
        .where(
            or_(
                Receipt.owner_id == actor_user_id,
                Receipt.recipient_id.in_(_member_recipient_ids(actor_user_id)),
            )
        )
    )
    file_record = result.scalar_one_or_none()
    if file_record is None:
        raise ResourceNotFoundError(f"File {file_id} not found or not visible")
    return file_record


async def delete_file_for_owner(
    session: AsyncSession,
    actor_user_id: int,
    file_id: int,
) -> str:
    result = await session.execute(
        select(ReceiptFile.id, Receipt.owner_id)
        .join(Receipt, Receipt.id == ReceiptFile.receipt_id)
        .where(ReceiptFile.id == file_id)
    )
    row = result.one_or_none()
    if row is None:
        raise ResourceNotFoundError(f"File {file_id} not found")
    if row.owner_id != actor_user_id:
        raise AuthorizationError(
            f"User {actor_user_id} cannot delete file {file_id}"
        )
    return await db.delete_file_record(session, file_id)


async def get_file_for_owner(
    session: AsyncSession,
    actor_user_id: int,
    file_id: int,
) -> ReceiptFile:
    result = await session.execute(
        select(ReceiptFile, Receipt.owner_id)
        .join(Receipt, Receipt.id == ReceiptFile.receipt_id)
        .where(ReceiptFile.id == file_id)
    )
    row = result.one_or_none()
    file_record = row[0] if row is not None else None
    owner_id = row[1] if row is not None else None
    return _require_owned_resource(
        file_record,
        "File",
        file_id,
        owner_id,
        actor_user_id,
    )
