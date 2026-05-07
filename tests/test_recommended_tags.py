import unittest

from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
from sqlalchemy.pool import StaticPool

from backend.db import (
    Base,
    Receipt,
    Recipient,
    TagIndex,
    TaggedReceipt,
    User,
    list_visible_recommended_tags,
)


class RecommendedTagsTest(unittest.IsolatedAsyncioTestCase):
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

    async def _seed_recommendation_data(self):
        async with self.session_maker() as session:
            actor = User(sub="actor", email="actor@test.dev", name="Actor")
            member_owner = User(
                sub="member-owner",
                email="owner@test.dev",
                name="Owner",
            )
            stranger = User(
                sub="stranger",
                email="stranger@test.dev",
                name="Stranger",
            )
            session.add_all([actor, member_owner, stranger])
            await session.flush()

            group = Recipient(
                owner_id=member_owner.id,
                name="Visible group",
                members=[actor],
            )
            session.add(group)
            await session.flush()

            owned_receipt = Receipt(
                owner_id=actor.id,
                title="Owned visible",
                amount_owed=10,
                currency="EUR",
            )
            member_receipt = Receipt(
                owner_id=member_owner.id,
                recipient_id=group.id,
                title="Group visible",
                amount_owed=20,
                currency="EUR",
            )
            stranger_receipt = Receipt(
                owner_id=stranger.id,
                title="Hidden",
                amount_owed=30,
                currency="EUR",
            )
            session.add_all([owned_receipt, member_receipt, stranger_receipt])
            await session.flush()

            alpha = TagIndex(icon="A", text="Alpha", color="#111111")
            beta = TagIndex(icon="B", text="beta", color="#222222")
            zeta = TagIndex(icon="Z", text="Zeta", color="#333333")
            hidden = TagIndex(icon="H", text="Hidden", color="#444444")
            unused = TagIndex(icon="U", text="Unused", color="#555555")
            session.add_all([alpha, beta, zeta, hidden, unused])
            await session.flush()

            session.add_all(
                [
                    TaggedReceipt(receipt_id=owned_receipt.id, tag_id=alpha.id),
                    TaggedReceipt(receipt_id=member_receipt.id, tag_id=alpha.id),
                    TaggedReceipt(receipt_id=member_receipt.id, tag_id=beta.id),
                    TaggedReceipt(receipt_id=owned_receipt.id, tag_id=zeta.id),
                    TaggedReceipt(receipt_id=stranger_receipt.id, tag_id=hidden.id),
                    TaggedReceipt(receipt_id=stranger_receipt.id, tag_id=alpha.id),
                ]
            )
            await session.commit()
            return actor.id

    async def test_recommended_tags_include_only_visible_receipts(self):
        actor_id = await self._seed_recommendation_data()

        async with self.session_maker() as session:
            tags = await list_visible_recommended_tags(session, actor_id)

        texts = [tag.text for tag in tags]
        self.assertIn("Alpha", texts)
        self.assertIn("beta", texts)
        self.assertIn("Zeta", texts)

    async def test_recommended_tags_exclude_unrelated_and_unused_tags(self):
        actor_id = await self._seed_recommendation_data()

        async with self.session_maker() as session:
            tags = await list_visible_recommended_tags(session, actor_id)

        texts = [tag.text for tag in tags]
        self.assertNotIn("Hidden", texts)
        self.assertNotIn("Unused", texts)

    async def test_recommended_tags_sort_by_visible_usage_then_text(self):
        actor_id = await self._seed_recommendation_data()

        async with self.session_maker() as session:
            tags = await list_visible_recommended_tags(session, actor_id)

        self.assertEqual(["Alpha", "beta", "Zeta"], [tag.text for tag in tags])


if __name__ == "__main__":
    unittest.main()
