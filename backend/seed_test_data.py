from __future__ import annotations

import asyncio
from datetime import datetime, timedelta, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

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
        food_tag = await _get_or_update_tag(
            session,
            text="Food",
            icon="🍽️",
            color="#81C784",
        )

        demo_receipt_seeds = [
            {
                "title": "Demo rent top-up",
                "amount_owed": 427.0,
                "recipient": recipient,
                "description": "Seeded shared household bill",
                "due_in_days": 7,
                "tag_ids": [rent_tag.id],
                "owner_share_percent": 40.0,
                "member_ids": household_member_ids,
                "owner_amount_paid": 170.8,
                "member_paid_fraction": 0.25,
            },
            {
                "title": "Demo electricity bill",
                "amount_owed": 248.4,
                "recipient": recipient,
                "description": "Seeded utility split",
                "due_in_days": 5,
                "tag_ids": [utility_tag.id],
                "owner_share_percent": 50.0,
                "member_ids": household_member_ids,
                "owner_amount_paid": 62.1,
                "member_paid_fraction": 0.0,
            },
            {
                "title": "Demo train tickets",
                "amount_owed": 176.3,
                "recipient": travel_group,
                "description": "Seeded trip bill",
                "due_in_days": 2,
                "tag_ids": [travel_tag.id],
                "owner_share_percent": 34.0,
                "member_ids": trip_member_ids,
                "owner_amount_paid": 0.0,
                "member_paid_fraction": 0.5,
            },
            {
                "title": "Demo team lunch reimbursement",
                "amount_owed": 96.0,
                "recipient": recipient,
                "description": "Owner tracks the bill but owes no share",
                "due_in_days": 3,
                "tag_ids": [utility_tag.id],
                "owner_share_percent": 0.0,
                "member_ids": household_member_ids,
                "owner_amount_paid": 0.0,
                "member_paid_fraction": 0.5,
            },
            {
                "title": "Demo grocery run",
                "amount_owed": 142.75,
                "recipient": recipient,
                "description": "Seeded household groceries",
                "due_in_days": 1,
                "tag_ids": [food_tag.id],
                "owner_share_percent": 50.0,
                "member_ids": household_member_ids,
                "owner_amount_paid": 35.0,
                "member_paid_fraction": 0.0,
            },
            {
                "title": "Demo internet plan",
                "amount_owed": 64.9,
                "recipient": recipient,
                "description": "Seeded monthly internet split",
                "due_in_days": 9,
                "tag_ids": [utility_tag.id],
                "owner_share_percent": 50.0,
                "member_ids": household_member_ids,
                "owner_amount_paid": 0.0,
                "member_paid_fraction": 0.0,
            },
            {
                "title": "Demo water bill",
                "amount_owed": 88.2,
                "recipient": recipient,
                "description": "Seeded household utility",
                "due_in_days": 11,
                "tag_ids": [utility_tag.id],
                "owner_share_percent": 50.0,
                "member_ids": household_member_ids,
                "owner_amount_paid": 20.0,
                "member_paid_fraction": 0.25,
            },
            {
                "title": "Demo parking fees",
                "amount_owed": 39.5,
                "recipient": travel_group,
                "description": "Seeded trip parking split",
                "due_in_days": 4,
                "tag_ids": [travel_tag.id],
                "owner_share_percent": 34.0,
                "member_ids": trip_member_ids,
                "owner_amount_paid": 13.43,
                "member_paid_fraction": 1.0,
            },
            {
                "title": "Demo hostel deposit",
                "amount_owed": 312.0,
                "recipient": travel_group,
                "description": "Seeded shared accommodation",
                "due_in_days": 14,
                "tag_ids": [travel_tag.id],
                "owner_share_percent": 34.0,
                "member_ids": trip_member_ids,
                "owner_amount_paid": 50.0,
                "member_paid_fraction": 0.0,
            },
            {
                "title": "Demo cafe meetup",
                "amount_owed": 54.8,
                "recipient": travel_group,
                "description": "Seeded travel meal split",
                "due_in_days": 6,
                "tag_ids": [food_tag.id, travel_tag.id],
                "owner_share_percent": 34.0,
                "member_ids": trip_member_ids,
                "owner_amount_paid": 18.63,
                "member_paid_fraction": 0.5,
            },
            {
                "title": "Demo cleaning supplies",
                "amount_owed": 73.35,
                "recipient": recipient,
                "description": "Seeded household supplies",
                "due_in_days": 12,
                "tag_ids": [food_tag.id],
                "owner_share_percent": 50.0,
                "member_ids": household_member_ids,
                "owner_amount_paid": 0.0,
                "member_paid_fraction": 0.0,
            },
            {
                "title": "Demo appliance repair",
                "amount_owed": 219.99,
                "recipient": recipient,
                "description": "Seeded shared repair bill",
                "due_in_days": 16,
                "tag_ids": [utility_tag.id],
                "owner_share_percent": 50.0,
                "member_ids": household_member_ids,
                "owner_amount_paid": 40.0,
                "member_paid_fraction": 0.2,
            },
        ]

        for receipt_seed in demo_receipt_seeds:
            receipt = await _get_or_create_receipt(
                session,
                owner_id=owner.id,
                title=receipt_seed["title"],
                amount_owed=receipt_seed["amount_owed"],
                recipient_id=receipt_seed["recipient"].id,
                description=receipt_seed["description"],
                due_date=(
                    datetime.now(timezone.utc)
                    + timedelta(days=receipt_seed["due_in_days"])
                ),
            )
            await db.set_receipt_tags(session, receipt.id, receipt_seed["tag_ids"])
            await _set_demo_split(
                session,
                receipt_id=receipt.id,
                amount_owed=receipt_seed["amount_owed"],
                owner_share_percent=receipt_seed["owner_share_percent"],
                member_ids=receipt_seed["member_ids"],
                owner_amount_paid=receipt_seed["owner_amount_paid"],
                member_paid_fraction=receipt_seed["member_paid_fraction"],
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
        .options(selectinload(db.Recipient.members))
    )
    recipient = result.scalar_one_or_none()
    members = await _active_users_for_member_ids(session, member_ids)
    if recipient is None:
        recipient = db.Recipient(
            owner_id=owner_id,
            name=name,
            description=description,
        )
        recipient.members = members
        session.add(recipient)
        await session.flush()
    else:
        recipient.description = description
        recipient.members = members
        await session.flush()
    return recipient


async def _active_users_for_member_ids(
    session: AsyncSession,
    member_ids: list[int],
) -> list[db.User]:
    if not member_ids:
        return []

    result = await session.execute(select(db.User).where(db.User.id.in_(member_ids)))
    users_by_id = {user.id: user for user in result.scalars().all()}
    missing_user_ids = [
        member_id for member_id in member_ids if member_id not in users_by_id
    ]
    if missing_user_ids:
        raise ValueError(f"Seed recipient member users not found: {missing_user_ids}")

    deleted_user_ids = [
        member_id for member_id in member_ids if users_by_id[member_id].deleted
    ]
    if deleted_user_ids:
        raise ValueError(
            f"Deleted users cannot be added to demo recipient groups: {deleted_user_ids}"
        )

    return [users_by_id[member_id] for member_id in member_ids]


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
