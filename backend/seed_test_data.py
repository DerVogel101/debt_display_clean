from __future__ import annotations

import asyncio
from datetime import datetime, timedelta, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from backend import db


TEST_USER_SEEDS = [
    {
        "sub": "test|owner",
        "email": "owner.demo@example.com",
        "name": "Owner Demo",
    },
    {
        "sub": "test|alice",
        "email": "alice.demo@example.com",
        "name": "Alice Demo",
    },
    {
        "sub": "test|bob",
        "email": "bob.demo@example.com",
        "name": "Bob Demo",
    },
    {
        "sub": "test|casey",
        "email": "casey.demo@example.com",
        "name": "Casey Demo",
    },
]


async def seed_test_data() -> None:
    """Create idempotent local data for recipient search and shared bills."""
    async with db.engine.begin() as conn:
        await conn.run_sync(db.Base.metadata.create_all)
    await db.ensure_schema_compatible()

    async with db.async_session_maker() as session:
        first_user = await _first_user(session)
        users_by_sub = {}
        for user_seed in TEST_USER_SEEDS:
            user = await db.get_or_create_user(
                session=session,
                sub=user_seed["sub"],
                email=user_seed["email"],
                name=user_seed["name"],
                avatar_url=None,
            )
            users_by_sub[user.sub] = user

        owner = first_user or users_by_sub["test|owner"]
        alice = users_by_sub["test|alice"]
        bob = users_by_sub["test|bob"]
        casey = users_by_sub["test|casey"]
        household_member_ids = _member_ids_excluding_owner(owner.id, [alice.id, bob.id])
        trip_member_ids = _member_ids_excluding_owner(owner.id, [alice.id, casey.id])

        recipient = await _get_or_create_recipient(
            session,
            owner_id=owner.id,
            name="Demo household",
            description="Seeded group for local development",
            member_ids=household_member_ids,
        )

        travel_group = await _get_or_create_recipient(
            session,
            owner_id=owner.id,
            name="Demo trip",
            description="Seeded travel split group",
            member_ids=trip_member_ids,
        )

        rent_tag = await _get_or_update_tag(
            session,
            text="Rent",
            icon="🏠",
            color="#FFB74D",
        )
        utility_tag = await _get_or_update_tag(
            session,
            text="Utilities",
            icon="⚡",
            color="#FFD54F",
        )
        travel_tag = await _get_or_update_tag(
            session,
            text="Travel",
            icon="🚆",
            color="#64B5F6",
        )

        rent_receipt = await _get_or_create_receipt(
            session,
            owner_id=owner.id,
            title="Demo rent top-up",
            amount_owed=427.0,
            recipient_id=recipient.id,
            description="Seeded shared household bill",
            due_date=datetime.now(timezone.utc) + timedelta(days=7),
        )
        await db.set_receipt_tags(session, rent_receipt.id, [rent_tag.id])
        await _set_demo_split(
            session,
            receipt_id=rent_receipt.id,
            amount_owed=427.0,
            owner_share_percent=40.0,
            member_ids=household_member_ids,
            owner_amount_paid=170.8,
            member_paid_fraction=0.25,
        )

        utility_receipt = await _get_or_create_receipt(
            session,
            owner_id=owner.id,
            title="Demo electricity bill",
            amount_owed=248.4,
            recipient_id=recipient.id,
            description="Seeded utility split",
            due_date=datetime.now(timezone.utc) + timedelta(days=5),
        )
        await db.set_receipt_tags(session, utility_receipt.id, [utility_tag.id])
        await _set_demo_split(
            session,
            receipt_id=utility_receipt.id,
            amount_owed=248.4,
            owner_share_percent=50.0,
            member_ids=household_member_ids,
            owner_amount_paid=62.1,
            member_paid_fraction=0.0,
        )

        travel_receipt = await _get_or_create_receipt(
            session,
            owner_id=owner.id,
            title="Demo train tickets",
            amount_owed=176.3,
            recipient_id=travel_group.id,
            description="Seeded trip bill",
            due_date=datetime.now(timezone.utc) + timedelta(days=2),
        )
        await db.set_receipt_tags(session, travel_receipt.id, [travel_tag.id])
        await _set_demo_split(
            session,
            receipt_id=travel_receipt.id,
            amount_owed=176.3,
            owner_share_percent=34.0,
            member_ids=trip_member_ids,
            owner_amount_paid=0.0,
            member_paid_fraction=0.5,
        )

        owner_zero_receipt = await _get_or_create_receipt(
            session,
            owner_id=owner.id,
            title="Demo team lunch reimbursement",
            amount_owed=96.0,
            recipient_id=recipient.id,
            description="Owner tracks the bill but owes no share",
            due_date=datetime.now(timezone.utc) + timedelta(days=3),
        )
        await db.set_receipt_tags(session, owner_zero_receipt.id, [utility_tag.id])
        await _set_demo_split(
            session,
            receipt_id=owner_zero_receipt.id,
            amount_owed=96.0,
            owner_share_percent=0.0,
            member_ids=household_member_ids,
            owner_amount_paid=0.0,
            member_paid_fraction=0.5,
        )

        await session.commit()


async def _first_user(session: AsyncSession) -> db.User | None:
    result = await session.execute(select(db.User).order_by(db.User.id).limit(1))
    return result.scalar_one_or_none()


def _member_ids_excluding_owner(owner_id: int, member_ids: list[int]) -> list[int]:
    return [member_id for member_id in member_ids if member_id != owner_id]


async def _get_or_update_tag(
    session: AsyncSession,
    *,
    text: str,
    icon: str,
    color: str,
) -> db.TagIndex:
    tag = await db.get_or_create_tag(session, text=text, icon=icon, color=color)
    tag.icon = icon
    tag.color = color
    await session.flush()
    return tag


async def _set_demo_split(
    session: AsyncSession,
    *,
    receipt_id: int,
    amount_owed: float,
    owner_share_percent: float,
    member_ids: list[int],
    owner_amount_paid: float = 0.0,
    member_paid_fraction: float = 0.0,
) -> None:
    if not member_ids:
        await db.set_receipt_split(
            session,
            receipt_id=receipt_id,
            owner_share_percent=100.0,
            recipient_shares=[],
        )
        await db.set_receipt_payments(
            session,
            receipt_id=receipt_id,
            payments=[(None, amount_owed)],
        )
        return

    remaining_percent = 100.0 - owner_share_percent
    member_share_percent = remaining_percent / len(member_ids)
    await db.set_receipt_split(
        session,
        receipt_id=receipt_id,
        owner_share_percent=owner_share_percent,
        recipient_shares=[
            (member_id, member_share_percent) for member_id in member_ids
        ],
    )
    member_share_amount = amount_owed * member_share_percent / 100.0
    await db.set_receipt_payments(
        session,
        receipt_id=receipt_id,
        payments=[
            (None, owner_amount_paid),
            *[
                (member_id, member_share_amount * member_paid_fraction)
                for member_id in member_ids
            ],
        ],
    )


async def _get_or_create_recipient(
    session: AsyncSession,
    *,
    owner_id: int,
    name: str,
    description: str,
    member_ids: list[int],
) -> db.Recipient:
    result = await session.execute(
        select(db.Recipient)
        .where(db.Recipient.owner_id == owner_id)
        .where(db.Recipient.name == name)
    )
    recipient = result.scalar_one_or_none()
    if recipient is None:
        recipient = await db.create_recipient(
            session=session,
            owner_id=owner_id,
            name=name,
            description=description,
            member_ids=member_ids,
        )
    return recipient


async def _get_or_create_receipt(
    session: AsyncSession,
    *,
    owner_id: int,
    title: str,
    amount_owed: float,
    recipient_id: int,
    description: str,
    due_date: datetime,
) -> db.Receipt:
    existing = await session.execute(
        select(db.Receipt)
        .where(db.Receipt.owner_id == owner_id)
        .where(db.Receipt.title == title)
    )
    receipt = existing.scalar_one_or_none()
    if receipt is not None:
        return receipt
    return await db.create_receipt(
        session=session,
        owner_id=owner_id,
        title=title,
        amount_owed=amount_owed,
        recipient_id=recipient_id,
        description=description,
        due_date=due_date,
    )


def main() -> None:
    asyncio.run(seed_test_data())


if __name__ == "__main__":
    main()
