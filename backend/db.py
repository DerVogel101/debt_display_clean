"""
SQLite database setup via SQLAlchemy async.
Stores a local user record keyed by the Auth0 `sub` claim.
Auth0 owns authentication – we only store what we need for our app.
"""
from datetime import datetime, timezone
import math

from collections.abc import AsyncGenerator
from sqlalchemy import (
    String, Integer, ForeignKey, event, DateTime, func,
    BigInteger, UniqueConstraint, Index, Boolean, Table, Column, Text, select,
    or_,
)
from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship, Session, selectinload
from backend.config import settings

engine = create_async_engine(settings.DATABASE_URL, echo=False)
async_session_maker = async_sessionmaker(engine, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


# ── Recipient ↔ User membership ───────────────────────────────────────────────
recipient_members = Table(
    "recipient_members",
    Base.metadata,
    Column("recipient_id", ForeignKey("recipients.id", ondelete="CASCADE"), primary_key=True),
    Column("user_id",      ForeignKey("users.id",      ondelete="CASCADE"), primary_key=True),
)


class Recipient(Base):
    """A named group of one or more users that can be billed via a Receipt."""
    __tablename__ = "recipients"

    id:          Mapped[int]         = mapped_column(primary_key=True, autoincrement=True)
    name:        Mapped[str]         = mapped_column(String(256), nullable=False)
    owner_id:    Mapped[int]         = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    description: Mapped[str|None]    = mapped_column(String(512), nullable=True)
    created_at:  Mapped[datetime]    = mapped_column(DateTime(timezone=True), server_default=func.now())

    members: Mapped[list["User"]] = relationship(
        secondary="recipient_members",
        back_populates="recipient_memberships",
    )
    receipts_received: Mapped[list["Receipt"]] = relationship(
        back_populates="recipient",
        foreign_keys="Receipt.recipient_id",
    )


class User(Base):
    __tablename__ = "users"

    id:         Mapped[int]      = mapped_column(primary_key=True, autoincrement=True)
    sub:        Mapped[str]      = mapped_column(String(256), unique=True, index=True)
    email:      Mapped[str|None] = mapped_column(String(256), nullable=True)
    name:       Mapped[str|None] = mapped_column(String(256), nullable=True)
    avatar_url: Mapped[str|None] = mapped_column(String(512), nullable=True)

    recipient_memberships: Mapped[list["Recipient"]] = relationship(
        secondary="recipient_members",
        back_populates="members",
    )
    receipts_owned: Mapped[list["Receipt"]] = relationship(
        back_populates="owner",
        foreign_keys="Receipt.owner_id",
        cascade="all, delete-orphan",
    )


class Receipt(Base):
    __tablename__ = "receipts"

    id:          Mapped[int]           = mapped_column(primary_key=True, autoincrement=True)
    title:       Mapped[str]           = mapped_column(String(256), nullable=False)
    description: Mapped[str|None]      = mapped_column(String(256), nullable=True)

    amount_owed: Mapped[float]         = mapped_column(nullable=False)
    amount_paid: Mapped[float|None]    = mapped_column(nullable=True, default=0.0)
    owner_share_percent: Mapped[float|None] = mapped_column(nullable=True)
    due_date:    Mapped[datetime|None] = mapped_column(DateTime(timezone=True), nullable=True)
    is_paid:     Mapped[bool]          = mapped_column(Boolean, default=False, nullable=False)
    currency:    Mapped[str]           = mapped_column(String(8), default="EUR", nullable=False)
    paid_at:     Mapped[datetime|None] = mapped_column(DateTime(timezone=True), nullable=True)
    notes:       Mapped[str|None]      = mapped_column(Text, nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    updated_at: Mapped[datetime|None] = mapped_column(
        DateTime(timezone=True),
        onupdate=func.now(),
        nullable=True,
    )

    owner_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    recipient_id: Mapped[int|None] = mapped_column(
        Integer,
        ForeignKey("recipients.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )

    # Snapshot — survives recipient deletion
    recipient_name: Mapped[str|None] = mapped_column(String(256), nullable=True)

    owner: Mapped["User"] = relationship(
        back_populates="receipts_owned",
        foreign_keys=[owner_id],
    )
    recipient: Mapped["Recipient|None"] = relationship(
        back_populates="receipts_received",
        foreign_keys=[recipient_id],
    )
    files: Mapped[list["ReceiptFile"]] = relationship(
        back_populates="receipt",
        cascade="all, delete-orphan",
    )
    recipient_shares: Mapped[list["ReceiptRecipientShare"]] = relationship(
        back_populates="receipt",
        cascade="all, delete-orphan",
        order_by="ReceiptRecipientShare.user_id",
    )
    tagged_receipts: Mapped[list["TaggedReceipt"]] = relationship(
        back_populates="receipt",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )
    tags: Mapped[list["TagIndex"]] = relationship(
        secondary="tagged_receipts",
        back_populates="receipts",
        viewonly=True,
    )


class ReceiptRecipientShare(Base):
    __tablename__ = "receipt_recipient_shares"
    __table_args__ = (
        Index("ix_receipt_recipient_shares_receipt_id", "receipt_id"),
        Index("ix_receipt_recipient_shares_user_id", "user_id"),
    )

    receipt_id: Mapped[int] = mapped_column(
        ForeignKey("receipts.id", ondelete="CASCADE"),
        primary_key=True,
    )
    user_id: Mapped[int] = mapped_column(Integer, primary_key=True)
    share_percent: Mapped[float] = mapped_column(nullable=False)
    user_name_snapshot: Mapped[str|None] = mapped_column(String(256), nullable=True)
    user_email_snapshot: Mapped[str|None] = mapped_column(String(256), nullable=True)

    receipt: Mapped["Receipt"] = relationship(back_populates="recipient_shares")


class ReceiptFile(Base):
    __tablename__ = "receipt_files"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)

    receipt_id: Mapped[int] = mapped_column(
        ForeignKey("receipts.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    storage_key:       Mapped[str]      = mapped_column(String(512), nullable=False, unique=True)
    original_filename: Mapped[str]      = mapped_column(String(256), nullable=False)
    content_type:      Mapped[str|None] = mapped_column(String(128), nullable=True)
    size_bytes:        Mapped[int|None] = mapped_column(BigInteger, nullable=True)
    sha256:            Mapped[str|None] = mapped_column(String(64), nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    receipt: Mapped["Receipt"] = relationship(back_populates="files")


class TagIndex(Base):
    __tablename__ = "tag_index"

    id:    Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    icon:  Mapped[str] = mapped_column(String(256), nullable=False)
    text:  Mapped[str] = mapped_column(String(256), nullable=False, unique=True, index=True)
    color: Mapped[str] = mapped_column(String(256), nullable=False)

    tagged_receipts: Mapped[list["TaggedReceipt"]] = relationship(
        back_populates="tag",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )
    receipts: Mapped[list["Receipt"]] = relationship(
        secondary="tagged_receipts",
        back_populates="tags",
        viewonly=True,
    )


class TaggedReceipt(Base):
    __tablename__ = "tagged_receipts"
    __table_args__ = (
        UniqueConstraint("receipt_id", "tag_id", name="uq_tagged_receipts_receipt_tag"),
        Index("ix_tagged_receipts_receipt_id", "receipt_id"),
        Index("ix_tagged_receipts_tag_id", "tag_id"),
    )

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    receipt_id: Mapped[int] = mapped_column(
        ForeignKey("receipts.id", ondelete="CASCADE"),
        nullable=False,
    )
    tag_id: Mapped[int] = mapped_column(
        ForeignKey("tag_index.id", ondelete="CASCADE"),
        nullable=False,
    )

    receipt: Mapped["Receipt"]  = relationship(back_populates="tagged_receipts")
    tag:     Mapped["TagIndex"] = relationship(back_populates="tagged_receipts")


# ── Event listener ────────────────────────────────────────────────────────────
@event.listens_for(Receipt.recipient_id, "set")
def sync_recipient_name(target: Receipt, value: int | None, oldvalue, initiator):
    if value is None:
        return  # preserve existing snapshot
    session = Session.object_session(target)
    if session:
        r = session.get(Recipient, value)
        if r:
            target.recipient_name = r.name


# ── User Methods ──────────────────────────────────────────────────────────────

async def get_or_create_user(
    session: AsyncSession,
    sub: str,
    email: str | None,
    name: str | None,
    avatar_url: str | None,
) -> "User":
    """Upsert by Auth0 `sub`. Updates profile fields on every login."""
    result = await session.execute(select(User).where(User.sub == sub))
    user = result.scalar_one_or_none()
    if user is None:
        user = User(sub=sub, email=email, name=name, avatar_url=avatar_url)
        session.add(user)
        await session.flush()
    else:
        if email is not None:
            user.email = email
        if name is not None:
            user.name = name
        if avatar_url is not None:
            user.avatar_url = avatar_url
        await session.flush()
    return user


async def get_user_by_sub(session: AsyncSession, sub: str) -> "User | None":
    """Primary lookup used after JWT validation."""
    result = await session.execute(select(User).where(User.sub == sub))
    return result.scalar_one_or_none()


async def get_user_by_id(session: AsyncSession, user_id: int) -> "User | None":
    """Internal PK lookup."""
    return await session.get(User, user_id)


async def update_user_profile(
    session: AsyncSession,
    user_id: int,
    email: str | None = None,
    name: str | None = None,
    avatar_url: str | None = None,
) -> "User":
    """Partial update of profile fields. Only updates provided (non-None) fields."""
    user = await session.get(User, user_id)
    if user is None:
        raise ValueError(f"User {user_id} not found")
    if email is not None:
        user.email = email
    if name is not None:
        user.name = name
    if avatar_url is not None:
        user.avatar_url = avatar_url
    await session.flush()
    return user


async def search_users_by_prefix(
    session: AsyncSession,
    query: str,
    *,
    exclude_user_id: int,
    limit: int = 10,
) -> "list[User]":
    normalized = query.strip().lower()
    if len(normalized) < 3:
        raise ValueError("User search query must be at least 3 characters")

    capped_limit = max(1, min(limit, 10))
    prefix = f"{normalized}%"
    result = await session.execute(
        select(User)
        .where(User.id != exclude_user_id)
        .where(
            or_(
                func.lower(User.name).like(prefix),
                func.lower(User.email).like(prefix),
            )
        )
        .order_by(func.lower(func.coalesce(User.name, User.email, "")), User.id)
        .limit(capped_limit)
    )
    return list(result.scalars().all())


async def delete_user(session: AsyncSession, user_id: int) -> list[str]:
    """
    Deletes the user row. DB cascade removes owned receipts and their file rows.
    Returns all storage_key paths of deleted ReceiptFiles so the caller can
    remove the actual files from disk.
    """
    # Collect all storage keys before deletion
    result = await session.execute(
        select(ReceiptFile.storage_key)
        .join(Receipt, Receipt.id == ReceiptFile.receipt_id)
        .where(Receipt.owner_id == user_id)
    )
    storage_keys = list(result.scalars().all())

    user = await session.get(User, user_id)
    if user is not None:
        await session.delete(user)
        await session.flush()
    return storage_keys


# ── Recipient Methods ─────────────────────────────────────────────────────────

async def create_recipient(
    session: AsyncSession,
    owner_id: int,
    name: str,
    description: str | None,
    member_ids: list[int],
) -> "Recipient":
    """Creates a recipient and adds all listed users as members."""
    recipient = Recipient(owner_id=owner_id, name=name, description=description)

    if member_ids:
        result = await session.execute(select(User).where(User.id.in_(member_ids)))
        members = list(result.scalars().all())
        recipient.members = members

    session.add(recipient)
    await session.flush()  # get recipient.id
    return recipient


async def get_recipient_by_id(
    session: AsyncSession,
    recipient_id: int,
) -> "Recipient | None":
    """Eager-loads `members` via selectinload."""
    result = await session.execute(
        select(Recipient)
        .where(Recipient.id == recipient_id)
        .options(selectinload(Recipient.members))
    )
    return result.scalar_one_or_none()


async def list_recipients_for_user(
    session: AsyncSession,
    user_id: int,
) -> "list[Recipient]":
    """Returns recipients the user owns OR is a member of."""
    owned = await session.execute(
        select(Recipient)
        .where(Recipient.owner_id == user_id)
        .options(selectinload(Recipient.members))
    )
    owned_set = {r.id: r for r in owned.scalars().all()}

    member_of = await session.execute(
        select(Recipient)
        .join(recipient_members, recipient_members.c.recipient_id == Recipient.id)
        .where(recipient_members.c.user_id == user_id)
        .options(selectinload(Recipient.members))
    )
    for r in member_of.scalars().all():
        owned_set.setdefault(r.id, r)

    return list(owned_set.values())


async def update_recipient(
    session: AsyncSession,
    recipient_id: int,
    name: str | None = None,
    description: str | None = None,
) -> "Recipient":
    """Partial update. Only updates provided (non-None) fields."""
    recipient = await session.get(Recipient, recipient_id)
    if recipient is None:
        raise ValueError(f"Recipient {recipient_id} not found")
    if name is not None:
        recipient.name = name
    if description is not None:
        recipient.description = description
    await session.flush()
    return recipient


async def add_member_to_recipient(
    session: AsyncSession,
    recipient_id: int,
    user_id: int,
) -> None:
    """Appends a user to `recipient_members`. No-op if already a member."""
    recipient = await get_recipient_by_id(session, recipient_id)
    if recipient is None:
        raise ValueError(f"Recipient {recipient_id} not found")
    user = await session.get(User, user_id)
    if user is None:
        raise ValueError(f"User {user_id} not found")
    if user not in recipient.members:
        recipient.members.append(user)
        await session.flush()


async def remove_member_from_recipient(
        session: AsyncSession,
        recipient_id: int,
        user_id: int,
) -> None:
    recipient = await get_recipient_by_id(session, recipient_id)
    if recipient is None:
        raise ValueError(f"Recipient {recipient_id} not found")
    user = await session.get(User, user_id)
    if user is not None and user in recipient.members:
        recipient.members.remove(user)
    await session.flush()


async def delete_recipient(session: AsyncSession, recipient_id: int) -> None:
    """
    Deletes recipient row. DB sets Receipt.recipient_id = NULL (SET NULL).
    The receipt_name snapshot on existing receipts is preserved.
    """
    recipient = await session.get(Recipient, recipient_id)
    if recipient is not None:
        await session.delete(recipient)
        await session.flush()


# ── Receipt Methods ───────────────────────────────────────────────────────────
#
# These helpers are low-level and ownership-neutral by design. Route code should
# prefer the actor-scoped service layer in backend.services to avoid IDOR bugs.

async def create_receipt(
    session: AsyncSession,
    owner_id: int,
    title: str,
    amount_owed: float,
    currency: str = "EUR",
    recipient_id: int | None = None,
    description: str | None = None,
    due_date: datetime | None = None,
    notes: str | None = None,
) -> "Receipt":
    receipt = Receipt(
        owner_id=owner_id,
        title=title,
        amount_owed=amount_owed,
        currency=currency,
        recipient_id=recipient_id,
        description=description,
        due_date=due_date,
        notes=notes,
    )
    session.add(receipt)
    await session.flush()
    return receipt


async def get_receipt_by_id(
    session: AsyncSession,
    receipt_id: int,
) -> "Receipt | None":
    """Eager-loads `recipient`, `files`, and `tags` via selectinload."""
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
    return result.scalar_one_or_none()


async def list_receipts_for_owner(
    session: AsyncSession,
    owner_id: int,
    is_paid: bool | None = None,
    tag_ids: list[int] | None = None,
    cursor: int | None = None,
    limit: int = 20,
) -> "list[Receipt]":
    """
    Cursor-paginated (keyset on `id`). Optionally filter by payment status
    and/or a list of tag IDs (AND logic — receipt must have all listed tags).
    """
    stmt = select(Receipt).where(Receipt.owner_id == owner_id)

    if is_paid is not None:
        stmt = stmt.where(Receipt.is_paid == is_paid)

    if tag_ids:
        # AND logic: receipt must have ALL listed tags
        for tag_id in tag_ids:
            stmt = stmt.where(
                Receipt.id.in_(
                    select(TaggedReceipt.receipt_id).where(TaggedReceipt.tag_id == tag_id)
                )
            )

    if cursor is not None:
        stmt = stmt.where(Receipt.id > cursor)

    stmt = stmt.order_by(Receipt.id).limit(limit)
    stmt = stmt.options(
        selectinload(Receipt.recipient),
        selectinload(Receipt.recipient_shares),
        selectinload(Receipt.files),
        selectinload(Receipt.tags),
    )

    result = await session.execute(stmt)
    return list(result.scalars().all())


async def update_receipt(
    session: AsyncSession,
    receipt_id: int,
    title: str | None = None,
    description: str | None = None,
    amount_owed: float | None = None,
    amount_paid: float | None = None,
    due_date: datetime | None = None,
    notes: str | None = None,
    currency: str | None = None,
) -> "Receipt":
    """Partial update. Only updates provided (non-None) fields."""
    receipt = await session.get(Receipt, receipt_id)
    if receipt is None:
        raise ValueError(f"Receipt {receipt_id} not found")
    if title is not None:
        receipt.title = title
    if description is not None:
        receipt.description = description
    if amount_owed is not None:
        receipt.amount_owed = amount_owed
    if amount_paid is not None:
        receipt.amount_paid = amount_paid
    if due_date is not None:
        receipt.due_date = due_date
    if notes is not None:
        receipt.notes = notes
    if currency is not None:
        receipt.currency = currency
    await session.flush()
    return receipt


def _validate_percent(value: float, field_name: str) -> None:
    if not math.isfinite(value):
        raise ValueError(f"{field_name} must be finite")


async def set_receipt_split(
    session: AsyncSession,
    receipt_id: int,
    owner_share_percent: float,
    recipient_shares: list[tuple[int, float]],
) -> "Receipt":
    """
    Full-replaces a receipt split. Recipient share users must be current
    members of the receipt's recipient group. Percentages sum to 100.
    """
    result = await session.execute(
        select(Receipt)
        .where(Receipt.id == receipt_id)
        .options(selectinload(Receipt.recipient_shares))
    )
    receipt = result.scalar_one_or_none()
    if receipt is None:
        raise ValueError(f"Receipt {receipt_id} not found")

    _validate_percent(owner_share_percent, "owner_share_percent")
    if owner_share_percent < 0 or owner_share_percent > 100:
        raise ValueError("owner_share_percent must be between 0 and 100")

    seen_user_ids: set[int] = set()
    recipient_user_ids = [user_id for user_id, _ in recipient_shares]
    for user_id, share_percent in recipient_shares:
        if user_id in seen_user_ids:
            raise ValueError(f"Duplicate split user {user_id}")
        seen_user_ids.add(user_id)
        _validate_percent(share_percent, "share_percent")
        if share_percent <= 0 or share_percent > 100:
            raise ValueError("recipient share_percent must be > 0 and <= 100")
        if user_id == receipt.owner_id:
            raise ValueError("Receipt owner share must use owner_share_percent")

    total_percent = owner_share_percent + sum(
        share_percent for _, share_percent in recipient_shares
    )
    if abs(total_percent - 100.0) > 1e-6:
        raise ValueError("Receipt split percentages must sum to 100")

    members_by_id: dict[int, User] = {}
    if recipient_user_ids:
        if receipt.recipient_id is None:
            raise ValueError("Receipt split recipient shares require recipient_id")

        result = await session.execute(
            select(User)
            .join(recipient_members, recipient_members.c.user_id == User.id)
            .where(recipient_members.c.recipient_id == receipt.recipient_id)
            .where(User.id.in_(recipient_user_ids))
        )
        members_by_id = {member.id: member for member in result.scalars().all()}
        missing_user_ids = [user_id for user_id in recipient_user_ids if user_id not in members_by_id]
        if missing_user_ids:
            raise ValueError(
                "Receipt split users must be current members of the recipient"
            )

    receipt.owner_share_percent = owner_share_percent
    existing_shares = {share.user_id: share for share in receipt.recipient_shares}
    next_shares: list[ReceiptRecipientShare] = []

    for user_id, share_percent in recipient_shares:
        user = members_by_id[user_id]
        share = existing_shares.pop(user_id, None)
        if share is None:
            share = ReceiptRecipientShare(
                receipt_id=receipt_id,
                user_id=user_id,
            )
            session.add(share)
        share.share_percent = share_percent
        share.user_name_snapshot = user.name
        share.user_email_snapshot = user.email
        next_shares.append(share)

    for stale_share in existing_shares.values():
        await session.delete(stale_share)

    receipt.recipient_shares = next_shares

    await session.flush()
    return receipt


async def clear_receipt_split(
    session: AsyncSession,
    receipt_id: int,
) -> "Receipt":
    result = await session.execute(
        select(Receipt)
        .where(Receipt.id == receipt_id)
        .options(selectinload(Receipt.recipient_shares))
    )
    receipt = result.scalar_one_or_none()
    if receipt is None:
        raise ValueError(f"Receipt {receipt_id} not found")

    receipt.owner_share_percent = None
    for stale_share in list(receipt.recipient_shares):
        await session.delete(stale_share)
    receipt.recipient_shares = []

    await session.flush()
    return receipt


async def mark_receipt_paid(
    session: AsyncSession,
    receipt_id: int,
    amount_paid: float | None = None,
) -> "Receipt":
    """Sets is_paid=True, paid_at=now(). Optionally records amount_paid."""
    receipt = await session.get(Receipt, receipt_id)
    if receipt is None:
        raise ValueError(f"Receipt {receipt_id} not found")
    receipt.is_paid = True
    receipt.paid_at = datetime.now(tz=timezone.utc)
    if amount_paid is not None:
        receipt.amount_paid = amount_paid
    await session.flush()
    return receipt


async def mark_receipt_unpaid(
    session: AsyncSession,
    receipt_id: int,
) -> "Receipt":
    """Reverses payment: is_paid=False, paid_at=None."""
    receipt = await session.get(Receipt, receipt_id)
    if receipt is None:
        raise ValueError(f"Receipt {receipt_id} not found")
    receipt.is_paid = False
    receipt.paid_at = None
    await session.flush()
    return receipt


async def delete_receipt(
    session: AsyncSession,
    receipt_id: int,
) -> list[str]:
    """
    Deletes receipt row. DB cascades to ReceiptFile and TaggedReceipt rows.
    Returns all storage_key paths of deleted ReceiptFiles so the caller can
    remove the actual files from disk.
    """
    result = await session.execute(
        select(ReceiptFile.storage_key).where(ReceiptFile.receipt_id == receipt_id)
    )
    storage_keys = list(result.scalars().all())

    receipt = await session.get(Receipt, receipt_id)
    if receipt is not None:
        await session.delete(receipt)
        await session.flush()
    return storage_keys


# ── ReceiptFile Methods ───────────────────────────────────────────────────────

async def attach_file(
    session: AsyncSession,
    receipt_id: int,
    storage_key: str,
    original_filename: str,
    content_type: str | None = None,
    size_bytes: int | None = None,
    sha256: str | None = None,
) -> "ReceiptFile":
    """
    Inserts a ReceiptFile metadata row after the file has been written to disk.
    storage_key must be a server-generated relative key and globally unique.
    original_filename is the sanitized download/display name, not a path.
    """
    file_record = ReceiptFile(
        receipt_id=receipt_id,
        storage_key=storage_key,
        original_filename=original_filename,
        content_type=content_type,
        size_bytes=size_bytes,
        sha256=sha256,
    )
    session.add(file_record)
    await session.flush()
    return file_record


async def get_file_by_id(
    session: AsyncSession,
    file_id: int,
) -> "ReceiptFile | None":
    return await session.get(ReceiptFile, file_id)


async def list_files_for_receipt(
    session: AsyncSession,
    receipt_id: int,
) -> "list[ReceiptFile]":
    result = await session.execute(
        select(ReceiptFile).where(ReceiptFile.receipt_id == receipt_id)
    )
    return list(result.scalars().all())


async def delete_file_record(
    session: AsyncSession,
    file_id: int,
) -> str:
    """
    Deletes the DB row. Returns storage_key so the caller can delete the
    actual file from disk (e.g. os.remove / aiofiles).
    """
    file_record = await session.get(ReceiptFile, file_id)
    if file_record is None:
        raise ValueError(f"ReceiptFile {file_id} not found")
    storage_key: str = str(file_record.storage_key)  # unwrap Mapped[str]
    await session.delete(file_record)
    await session.flush()
    return storage_key


async def get_file_by_storage_key(
    session: AsyncSession,
    storage_key: str,
) -> "ReceiptFile | None":
    """Lookup by server-generated storage key."""
    result = await session.execute(
        select(ReceiptFile).where(ReceiptFile.storage_key == storage_key)
    )
    return result.scalar_one_or_none()


# ── Tag Methods ───────────────────────────────────────────────────────────────

async def get_or_create_tag(
    session: AsyncSession,
    text: str,
    icon: str,
    color: str,
) -> "TagIndex":
    """
    `text` is UNIQUE + indexed. Returns existing tag if text already exists.
    icon/color are only applied on creation, not on lookup.
    """
    result = await session.execute(select(TagIndex).where(TagIndex.text == text))
    tag = result.scalar_one_or_none()
    if tag is None:
        tag = TagIndex(text=text, icon=icon, color=color)
        session.add(tag)
        await session.flush()
    return tag


async def get_tag_by_id(session: AsyncSession, tag_id: int) -> "TagIndex | None":
    return await session.get(TagIndex, tag_id)


async def get_tag_by_text(session: AsyncSession, text: str) -> "TagIndex | None":
    result = await session.execute(select(TagIndex).where(TagIndex.text == text))
    return result.scalar_one_or_none()


async def list_all_tags(session: AsyncSession) -> "list[TagIndex]":
    result = await session.execute(select(TagIndex))
    return list(result.scalars().all())


async def update_tag(
    session: AsyncSession,
    tag_id: int,
    icon: str | None = None,
    color: str | None = None,
) -> "TagIndex":
    """
    Updates icon and/or color. `text` is intentionally NOT updatable
    because it is the unique business key referenced by the UI.
    """
    tag = await session.get(TagIndex, tag_id)
    if tag is None:
        raise ValueError(f"TagIndex {tag_id} not found")
    if icon is not None:
        tag.icon = icon
    if color is not None:
        tag.color = color
    await session.flush()
    return tag


async def delete_tag(session: AsyncSession, tag_id: int) -> None:
    """Cascades to all TaggedReceipt rows for this tag."""
    tag = await session.get(TagIndex, tag_id)
    if tag is not None:
        await session.delete(tag)
        await session.flush()


# ── TaggedReceipt Methods ─────────────────────────────────────────────────────

async def tag_receipt(
    session: AsyncSession,
    receipt_id: int,
    tag_id: int,
) -> "TaggedReceipt":
    """
    Inserts association row. If the (receipt_id, tag_id) pair already exists
    (UniqueConstraint), return the existing row instead of raising.
    """
    result = await session.execute(
        select(TaggedReceipt).where(
            TaggedReceipt.receipt_id == receipt_id,
            TaggedReceipt.tag_id == tag_id,
        )
    )
    existing = result.scalar_one_or_none()
    if existing is not None:
        return existing
    tagged = TaggedReceipt(receipt_id=receipt_id, tag_id=tag_id)
    session.add(tagged)
    await session.flush()
    return tagged


async def untag_receipt(
    session: AsyncSession,
    receipt_id: int,
    tag_id: int,
) -> None:
    result = await session.execute(
        select(TaggedReceipt).where(
            TaggedReceipt.receipt_id == receipt_id,
            TaggedReceipt.tag_id == tag_id,
        )
    )
    tagged = result.scalar_one_or_none()
    if tagged is not None:
        await session.delete(tagged)
        await session.flush()


async def set_receipt_tags(
    session: AsyncSession,
    receipt_id: int,
    tag_ids: list[int],
) -> None:
    """
    Atomic full replace: removes tags not in tag_ids, adds missing ones.
    Preferred over calling tag_receipt/untag_receipt individually for bulk edits.
    """
    result = await session.execute(
        select(TaggedReceipt).where(TaggedReceipt.receipt_id == receipt_id)
    )
    existing = {tr.tag_id: tr for tr in result.scalars().all()}
    desired = set(tag_ids)

    # Remove stale
    for tag_id, tr in existing.items():
        if tag_id not in desired:
            await session.delete(tr)

    # Add missing
    for tag_id in desired:
        if tag_id not in existing:
            session.add(TaggedReceipt(receipt_id=receipt_id, tag_id=tag_id))

    await session.flush()


# ── DB Lifecycle & Utilities ──────────────────────────────────────────────────

async def reset_db() -> None:
    """Drops and recreates all tables for local recovery workflows."""
    async with engine.begin() as conn:  # type: ignore[arg-type]
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)


async def get_session() -> AsyncGenerator[AsyncSession, None]:
    """FastAPI dependency. Use via Depends(get_session)."""
    async with async_session_maker() as session:
        yield session


async def check_db_connection() -> bool:
    """Executes SELECT 1. Returns True on success. Use for /health endpoint."""
    from sqlalchemy import text
    try:
        async with async_session_maker() as session:
            await session.execute(text("SELECT 1"))
        return True
    except Exception:
        return False


if __name__ == "__main__":
    import asyncio
    if input("Drop and recreate database? (y/n): ").lower() == "y":
        asyncio.run(reset_db())
