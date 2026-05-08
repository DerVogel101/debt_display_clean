import unittest

from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
from sqlalchemy.pool import StaticPool

from backend.db import Base, Receipt, ReceiptRecipientShare, Recipient, User
from backend.services import list_visible_receipts, summarize_visible_unpaid_receipts


class UnpaidReceiptSummaryTest(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        self.engine = create_async_engine(
            "sqlite+aiosqlite:///:memory:",
            connect_args={"check_same_thread": False},
            poolclass=StaticPool,
        )
        async with self.engine.begin() as connection:
            await connection.run_sync(Base.metadata.create_all)
        self.session_maker = async_sessionmaker(self.engine, expire_on_commit=False)

    async def asyncTearDown(self):
        await self.engine.dispose()

    async def _seed_summary_data(self):
        async with self.session_maker() as session:
            actor = User(sub="actor", email="actor@test.dev", name="Actor")
            owner = User(sub="owner", email="owner@test.dev", name="Owner")
            stranger = User(
                sub="stranger",
                email="stranger@test.dev",
                name="Stranger",
            )
            session.add_all([actor, owner, stranger])
            await session.flush()

            group = Recipient(owner_id=owner.id, name="Visible group", members=[actor])
            session.add(group)
            await session.flush()

            owned_personal = Receipt(
                owner_id=actor.id,
                title="Owned personal",
                amount_owed=100,
                amount_paid=30,
                owner_amount_paid=30,
                currency="EUR",
                is_paid=False,
            )
            owned_split = Receipt(
                owner_id=actor.id,
                title="Owned split",
                amount_owed=200,
                amount_paid=10,
                owner_amount_paid=10,
                owner_share_percent=25,
                currency="EUR",
                is_paid=False,
            )
            member_split = Receipt(
                owner_id=owner.id,
                recipient_id=group.id,
                title="Member split",
                amount_owed=100,
                amount_paid=20,
                currency="EUR",
                is_paid=False,
            )
            fully_paid_inconsistent = Receipt(
                owner_id=actor.id,
                title="Already fully paid",
                amount_owed=50,
                amount_paid=50,
                owner_amount_paid=50,
                currency="EUR",
                is_paid=False,
            )
            zero_owner_share = Receipt(
                owner_id=actor.id,
                title="Zero owner share",
                amount_owed=75,
                amount_paid=0,
                owner_amount_paid=0,
                owner_share_percent=0,
                currency="EUR",
                is_paid=False,
            )
            paid_receipt = Receipt(
                owner_id=actor.id,
                title="Paid hidden",
                amount_owed=999,
                amount_paid=0,
                owner_amount_paid=0,
                currency="EUR",
                is_paid=True,
            )
            unrelated = Receipt(
                owner_id=stranger.id,
                title="Unrelated",
                amount_owed=999,
                amount_paid=0,
                owner_amount_paid=0,
                currency="EUR",
                is_paid=False,
            )
            visible_paid_mocks = [
                Receipt(
                    owner_id=actor.id,
                    title=f"Visible paid mock {index}",
                    amount_owed=10 + index,
                    amount_paid=10 + index,
                    owner_amount_paid=10 + index,
                    currency="EUR",
                    is_paid=True,
                )
                for index in range(1, 6)
            ]
            session.add_all(
                [
                    owned_personal,
                    owned_split,
                    member_split,
                    fully_paid_inconsistent,
                    zero_owner_share,
                    paid_receipt,
                    unrelated,
                    *visible_paid_mocks,
                ]
            )
            await session.flush()

            session.add(
                ReceiptRecipientShare(
                    receipt_id=member_split.id,
                    user_id=actor.id,
                    share_percent=50,
                    amount_paid=20,
                )
            )
            await session.commit()
            return actor.id

    async def test_summary_includes_owner_and_participant_unpaid_shares(self):
        actor_id = await self._seed_summary_data()

        async with self.session_maker() as session:
            summary = await summarize_visible_unpaid_receipts(session, actor_id)

        self.assertAlmostEqual(summary.unpaid_share_total, 140.0)
        self.assertEqual(summary.unpaid_bill_count, 3)

    async def test_summary_excludes_fully_paid_zero_share_paid_and_unrelated(self):
        actor_id = await self._seed_summary_data()

        async with self.session_maker() as session:
            summary = await summarize_visible_unpaid_receipts(session, actor_id)

        self.assertNotEqual(summary.unpaid_share_total, 140.0 + 50 + 75 + 999)
        self.assertEqual(summary.unpaid_bill_count, 3)

    async def test_seed_data_creates_more_than_ten_visible_mock_receipts_for_first_user(self):
        actor_id = await self._seed_summary_data()

        async with self.session_maker() as session:
            first_user = await session.get(User, actor_id)
            receipt_page = await list_visible_receipts(session, actor_id, limit=20)

        self.assertIsNotNone(first_user)
        self.assertEqual(first_user.sub, "actor")
        self.assertGreater(len(receipt_page.receipts), 10)


if __name__ == "__main__":
    unittest.main()
