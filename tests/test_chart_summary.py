from __future__ import annotations

import unittest
from datetime import datetime, timezone

from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
from sqlalchemy.pool import StaticPool

from backend.db import (
    Base,
    Receipt,
    ReceiptRecipientShare,
    Recipient,
    TagIndex,
    TaggedReceipt,
    User,
)
from backend.services import summarize_visible_receipt_charts


class ReceiptChartSummaryTest(unittest.IsolatedAsyncioTestCase):
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

    async def _seed_chart_data(self):
        async with self.session_maker() as session:
            actor = User(sub="actor", email="actor@test.dev", name="Actor")
            group_owner = User(sub="owner", email="owner@test.dev", name="Owner")
            stranger = User(
                sub="stranger",
                email="stranger@test.dev",
                name="Stranger",
            )
            session.add_all([actor, group_owner, stranger])
            await session.flush()

            group = Recipient(
                owner_id=group_owner.id,
                name="Visible group",
                members=[actor],
            )
            session.add(group)
            await session.flush()

            tags = [
                TagIndex(icon="A", text="Alpha", color="#111111"),
                TagIndex(icon="B", text="Beta", color="#222222"),
                TagIndex(icon="C", text="Gamma", color="#333333"),
                TagIndex(icon="D", text="Delta", color="#444444"),
                TagIndex(icon="E", text="Epsilon", color="#555555"),
                TagIndex(icon="Z", text="Zeta", color="#666666"),
                TagIndex(icon="H", text="Hidden", color="#777777"),
            ]
            session.add_all(tags)
            await session.flush()
            tags_by_text = {tag.text: tag for tag in tags}

            paid = Receipt(
                owner_id=actor.id,
                title="Paid",
                amount_owed=100,
                amount_paid=100,
                owner_amount_paid=100,
                currency="EUR",
                is_paid=True,
                created_at=datetime(2026, 5, 1, tzinfo=timezone.utc),
            )
            open_receipt = Receipt(
                owner_id=actor.id,
                title="Open",
                amount_owed=100,
                amount_paid=40,
                owner_amount_paid=40,
                currency="EUR",
                is_paid=False,
                due_date=datetime(2026, 5, 20, tzinfo=timezone.utc),
                created_at=datetime(2026, 5, 2, tzinfo=timezone.utc),
            )
            overdue_member = Receipt(
                owner_id=group_owner.id,
                recipient_id=group.id,
                title="Overdue member",
                amount_owed=200,
                amount_paid=10,
                currency="EUR",
                is_paid=False,
                due_date=datetime(2026, 5, 1, tzinfo=timezone.utc),
                created_at=datetime(2026, 5, 3, tzinfo=timezone.utc),
            )
            old_receipt = Receipt(
                owner_id=actor.id,
                title="Old",
                amount_owed=50,
                amount_paid=0,
                owner_amount_paid=0,
                currency="EUR",
                is_paid=False,
                created_at=datetime(2026, 4, 1, tzinfo=timezone.utc),
            )
            hidden = Receipt(
                owner_id=stranger.id,
                title="Hidden",
                amount_owed=999,
                amount_paid=999,
                owner_amount_paid=999,
                currency="EUR",
                is_paid=True,
                created_at=datetime(2026, 5, 1, tzinfo=timezone.utc),
            )
            session.add_all([paid, open_receipt, overdue_member, old_receipt, hidden])
            await session.flush()
            session.add(
                ReceiptRecipientShare(
                    receipt_id=overdue_member.id,
                    user_id=actor.id,
                    share_percent=25,
                    amount_paid=10,
                )
            )

            tag_links = [
                (paid, "Alpha"),
                (open_receipt, "Alpha"),
                (open_receipt, "Beta"),
                (overdue_member, "Beta"),
                (old_receipt, "Gamma"),
                (paid, "Delta"),
                (paid, "Epsilon"),
                (paid, "Zeta"),
                (hidden, "Hidden"),
            ]
            for receipt, tag_text in tag_links:
                session.add(
                    TaggedReceipt(
                        receipt_id=receipt.id,
                        tag_id=tags_by_text[tag_text].id,
                    )
                )
            await session.commit()
            return actor.id, tags_by_text

    async def test_summary_uses_disjoint_paid_open_and_overdue_values(self):
        actor_id, _ = await self._seed_chart_data()

        async with self.session_maker() as session:
            summary = await summarize_visible_receipt_charts(
                session,
                actor_id,
                now=datetime(2026, 5, 9, tzinfo=timezone.utc),
            )

        self.assertAlmostEqual(summary.totals.paid_share, 150)
        self.assertAlmostEqual(summary.totals.open_share, 110)
        self.assertAlmostEqual(summary.totals.overdue_open_share, 40)

    async def test_summary_filters_by_created_date(self):
        actor_id, _ = await self._seed_chart_data()

        async with self.session_maker() as session:
            summary = await summarize_visible_receipt_charts(
                session,
                actor_id,
                created_at_from=datetime(2026, 5, 2, tzinfo=timezone.utc),
                created_at_to=datetime(2026, 5, 4, tzinfo=timezone.utc),
                now=datetime(2026, 5, 9, tzinfo=timezone.utc),
            )

        self.assertAlmostEqual(summary.totals.paid_share, 50)
        self.assertAlmostEqual(summary.totals.open_share, 60)
        self.assertAlmostEqual(summary.totals.overdue_open_share, 40)

    async def test_summary_excludes_hidden_receipts_and_tags(self):
        actor_id, _ = await self._seed_chart_data()

        async with self.session_maker() as session:
            summary = await summarize_visible_receipt_charts(session, actor_id)

        self.assertNotIn("Hidden", [tag.text for tag in summary.available_tags])
        self.assertNotAlmostEqual(summary.totals.paid_share, 1149)

    async def test_summary_defaults_to_top_five_visible_tags(self):
        actor_id, tags = await self._seed_chart_data()

        async with self.session_maker() as session:
            summary = await summarize_visible_receipt_charts(
                session,
                actor_id,
                tag_limit=5,
            )

        self.assertEqual(
            ["Alpha", "Beta", "Delta", "Epsilon", "Gamma"],
            [tag.text for tag in summary.available_tags[:5]],
        )
        self.assertEqual(
            [
                tags["Alpha"].id,
                tags["Beta"].id,
                tags["Delta"].id,
                tags["Epsilon"].id,
                tags["Gamma"].id,
            ],
            summary.default_tag_ids,
        )

    async def test_summary_uses_selected_tags_for_buckets(self):
        actor_id, tags = await self._seed_chart_data()

        async with self.session_maker() as session:
            summary = await summarize_visible_receipt_charts(
                session,
                actor_id,
                tag_ids=[tags["Beta"].id],
                now=datetime(2026, 5, 9, tzinfo=timezone.utc),
            )

        self.assertEqual(["Beta"], [bucket.tag.text for bucket in summary.tag_buckets])
        self.assertAlmostEqual(summary.tag_buckets[0].paid_share, 50)
        self.assertAlmostEqual(summary.tag_buckets[0].open_share, 60)
        self.assertAlmostEqual(summary.tag_buckets[0].overdue_open_share, 40)


if __name__ == "__main__":
    unittest.main()
