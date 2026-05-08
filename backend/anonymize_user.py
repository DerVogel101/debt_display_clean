from __future__ import annotations

import argparse
import asyncio
from pathlib import Path

from backend import db
from backend.config import settings
from backend.storage import resolve_storage_path


def _delete_managed_files(storage_keys: list[str]) -> int:
    upload_root = Path(settings.UPLOAD_DIR).resolve()
    deleted = 0
    for storage_key in storage_keys:
        try:
            path = resolve_storage_path(storage_key, upload_root)
        except ValueError:
            continue
        if path.exists():
            path.unlink()
            deleted += 1
    return deleted


async def _run(sub: str) -> int:
    async with db.engine.begin() as conn:  # type: ignore[arg-type]
        await conn.run_sync(db.Base.metadata.create_all)
    await db.ensure_schema_compatible()

    async with db.async_session_maker() as session:
        try:
            result = await db.delete_user_by_sub(session, sub)
            await session.commit()
        except ValueError as exc:
            await session.rollback()
            print(str(exc))
            return 1

    files_deleted = _delete_managed_files(result.storage_keys)
    print(f"user_id={result.user_id}")
    print(f"old_sub={result.old_sub}")
    print(f"new_sub={result.new_sub}")
    print(f"receipts_deleted={result.receipts_deleted}")
    print(f"owned_groups_deleted={result.owned_groups_deleted}")
    print(f"files_deleted={files_deleted}")
    print(f"retained_memberships={result.retained_memberships}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Anonymize a user by Auth0 sub for GDPR erasure."
    )
    parser.add_argument("sub", help="Auth0 subject from the users.sub field")
    args = parser.parse_args()
    return asyncio.run(_run(args.sub))


if __name__ == "__main__":
    raise SystemExit(main())
