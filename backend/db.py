"""
SQLite database setup via SQLAlchemy async.
Stores a local user record keyed by the Auth0 `sub` claim.
Auth0 owns authentication – we only store what we need for our app.
"""
from datetime import datetime

from collections.abc import AsyncGenerator
from sqlalchemy import (
    String, Integer, ForeignKey, event, DateTime, func,
    BigInteger, UniqueConstraint, Index, Boolean, Table, Column, Text,
)
from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship, Session
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


# ── Helpers ───────────────────────────────────────────────────────────────────
def create_recipient(session: Session, name: str, members: list[User]) -> Recipient:
    r = Recipient(name=name, members=members)
    session.add(r)
    return r


def recipient_for_user(session: Session, user: User) -> Recipient:
    """Convenience: wrap a single user as a one-member recipient."""
    return create_recipient(
        session,
        name=user.name or user.email or str(user.id),
        members=[user],
    )


def create_receipt(
    session: Session,
    owner_id: int,
    recipient: Recipient | None = None,
) -> Receipt:
    receipt = Receipt(
        owner_id=owner_id,
        recipient_id=recipient.id if recipient else None,
        recipient_name=recipient.name if recipient else None,
    )
    session.add(receipt)
    return receipt


# ── DB lifecycle ──────────────────────────────────────────────────────────────
async def create_db_and_tables() -> None:
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)


async def get_session() -> AsyncGenerator[AsyncSession, None]:
    async with async_session_maker() as session:
        yield session


if __name__ == "__main__":
    import asyncio
    if input("Drop and recreate database? (y/n): ").lower() == "y":
        asyncio.run(create_db_and_tables())
