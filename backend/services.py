from __future__ import annotations

from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from backend import db
from backend.db import Receipt, ReceiptFile, Recipient, TaggedReceipt, recipient_members
from backend.storage import generate_storage_key, sanitize_download_filename


class ResourceNotFoundError(LookupError):
    pass


class AuthorizationError(PermissionError):
    pass


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
    limit: int = 20,
) -> list[Receipt]:
    stmt = select(Receipt).where(
        or_(
            Receipt.owner_id == actor_user_id,
            Receipt.recipient_id.in_(_member_recipient_ids(actor_user_id)),
        )
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

    if cursor is not None:
        stmt = stmt.where(Receipt.id > cursor)

    stmt = stmt.order_by(Receipt.id).limit(limit).options(
        selectinload(Receipt.recipient),
        selectinload(Receipt.files),
        selectinload(Receipt.tags),
    )

    result = await session.execute(stmt)
    return list(result.scalars().all())


async def update_receipt_for_owner(
    session: AsyncSession,
    actor_user_id: int,
    receipt_id: int,
    **changes,
) -> Receipt:
    await get_owned_receipt(session, actor_user_id, receipt_id)
    return await db.update_receipt(session, receipt_id, **changes)


async def mark_receipt_paid_for_owner(
    session: AsyncSession,
    actor_user_id: int,
    receipt_id: int,
    amount_paid: float | None = None,
) -> Receipt:
    await get_owned_receipt(session, actor_user_id, receipt_id)
    return await db.mark_receipt_paid(session, receipt_id, amount_paid=amount_paid)


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
