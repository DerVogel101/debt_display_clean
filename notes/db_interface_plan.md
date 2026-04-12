# `backend/db.py` — Interface Plan
> **Project:** `DerVogel101/debt_display`
> **Stack:** FastAPI · SQLAlchemy async · aiosqlite · SQLite (local file)
> **DB URL:** `sqlite+aiosqlite:///./database.sqlite`
> **File storage:** Local filesystem — `uploads/{owner_id}/{receipt_id}/{uuid}_{filename}`

---

## Models Overview

| Model | Table | Notes |
|---|---|---|
| `User` | `users` | Keyed by Auth0 `sub` claim |
| `Recipient` | `recipients` | Named group of users, owned by one user |
| `Receipt` | `receipts` | Core debt record; links owner → recipient |
| `ReceiptFile` | `receipt_files` | Metadata only; actual bytes live on disk |
| `TagIndex` | `tag_index` | Global tag registry; `text` is UNIQUE |
| `TaggedReceipt` | `tagged_receipts` | M2M join: Receipt ↔ TagIndex |
| *(assoc table)* | `recipient_members` | M2M join: Recipient ↔ User |

---

## Conventions

- All interface methods are `async def` and accept `AsyncSession` as their first argument.
- `db.py` methods are **ownership-neutral** — they do not enforce authorization. The route/service layer raises `403`.
- `session.add()` / `session.flush()` happen inside `db.py`; `commit()` / `rollback()` are owned by the **route layer**.
- Use `selectinload()` for all eager loading — never `joinedload()` with async SQLAlchemy.
- Pagination uses keyset/cursor style: `WHERE id > cursor ORDER BY id LIMIT n` — no `OFFSET`.
- The `recipient_name` snapshot on `Receipt` is maintained by the existing sync `@event.listens_for(Receipt.recipient_id, "set")` listener — do not remove it.
- File deletion: `db.py` deletes the DB row and **returns the `storage_key` path**. The caller (`os.remove()` / `aiofiles`) deletes the actual file from disk.

---

## User Methods

```python
async def get_or_create_user(
    session: AsyncSession,
    sub: str,
    email: str | None,
    name: str | None,
    avatar_url: str | None,
) -> User:
    """Upsert by Auth0 `sub`. Updates profile fields on every login."""

async def get_user_by_sub(session: AsyncSession, sub: str) -> User | None:
    """Primary lookup used after JWT validation."""

async def get_user_by_id(session: AsyncSession, user_id: int) -> User | None:
    """Internal PK lookup."""

async def update_user_profile(
    session: AsyncSession,
    user_id: int,
    email: str | None = None,
    name: str | None = None,
    avatar_url: str | None = None,
) -> User:
    """Partial update of profile fields. Only updates provided (non-None) fields."""

async def delete_user(session: AsyncSession, user_id: int) -> list[str]:
    """
    Deletes the user row. DB cascade removes owned receipts and their file rows.
    Returns all storage_key paths of deleted ReceiptFiles so the caller can
    remove the actual files from disk.
    """
```

---

## Recipient Methods

```python
async def create_recipient(
    session: AsyncSession,
    owner_id: int,
    name: str,
    description: str | None,
    member_ids: list[int],
) -> Recipient:
    """Creates a recipient and adds all listed users as members."""

async def get_recipient_by_id(
    session: AsyncSession,
    recipient_id: int,
) -> Recipient | None:
    """Eager-loads `members` via selectinload."""

async def list_recipients_for_user(
    session: AsyncSession,
    user_id: int,
) -> list[Recipient]:
    """Returns recipients the user owns OR is a member of."""

async def update_recipient(
    session: AsyncSession,
    recipient_id: int,
    name: str | None = None,
    description: str | None = None,
) -> Recipient:
    """Partial update. Only updates provided (non-None) fields."""

async def add_member_to_recipient(
    session: AsyncSession,
    recipient_id: int,
    user_id: int,
) -> None:
    """Appends a user to `recipient_members`. No-op if already a member."""

async def remove_member_from_recipient(
    session: AsyncSession,
    recipient_id: int,
    user_id: int,
) -> None:

async def delete_recipient(session: AsyncSession, recipient_id: int) -> None:
    """
    Deletes recipient row. DB sets Receipt.recipient_id = NULL (SET NULL).
    The receipt_name snapshot on existing receipts is preserved.
    """
```

---

## Receipt Methods

```python
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
) -> Receipt:

async def get_receipt_by_id(
    session: AsyncSession,
    receipt_id: int,
) -> Receipt | None:
    """Eager-loads `recipient`, `files`, and `tags` via selectinload."""

async def list_receipts_for_owner(
    session: AsyncSession,
    owner_id: int,
    is_paid: bool | None = None,
    tag_ids: list[int] | None = None,
    cursor: int | None = None,
    limit: int = 20,
) -> list[Receipt]:
    """
    Cursor-paginated (keyset on `id`). Optionally filter by payment status
    and/or a list of tag IDs (AND logic — receipt must have all listed tags).
    """

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
) -> Receipt:
    """Partial update. Only updates provided (non-None) fields."""

async def mark_receipt_paid(
    session: AsyncSession,
    receipt_id: int,
    amount_paid: float | None = None,
) -> Receipt:
    """Sets is_paid=True, paid_at=now(). Optionally records amount_paid."""

async def mark_receipt_unpaid(
    session: AsyncSession,
    receipt_id: int,
) -> Receipt:
    """Reverses payment: is_paid=False, paid_at=None."""

async def delete_receipt(
    session: AsyncSession,
    receipt_id: int,
) -> list[str]:
    """
    Deletes receipt row. DB cascades to ReceiptFile and TaggedReceipt rows.
    Returns all storage_key paths of deleted ReceiptFiles so the caller can
    remove the actual files from disk.
    """
```

---

## ReceiptFile Methods

> File bytes live on disk. `db.py` only manages metadata rows.
> `storage_key` convention: `uploads/{owner_id}/{receipt_id}/{uuid4}_{original_filename}`

```python
async def attach_file(
    session: AsyncSession,
    receipt_id: int,
    storage_key: str,
    original_filename: str,
    content_type: str | None = None,
    size_bytes: int | None = None,
    sha256: str | None = None,
) -> ReceiptFile:
    """
    Inserts a ReceiptFile metadata row after the file has been written to disk.
    storage_key must be globally unique (UNIQUE constraint in DB).
    """

async def get_file_by_id(
    session: AsyncSession,
    file_id: int,
) -> ReceiptFile | None:

async def list_files_for_receipt(
    session: AsyncSession,
    receipt_id: int,
) -> list[ReceiptFile]:

async def delete_file_record(
    session: AsyncSession,
    file_id: int,
) -> str:
    """
    Deletes the DB row. Returns storage_key so the caller can delete the
    actual file from disk (e.g. os.remove / aiofiles).
    """

async def get_file_by_storage_key(
    session: AsyncSession,
    storage_key: str,
) -> ReceiptFile | None:
    """Deduplication check before writing a file to disk."""
```

---

## Tag Methods

```python
async def get_or_create_tag(
    session: AsyncSession,
    text: str,
    icon: str,
    color: str,
) -> TagIndex:
    """
    `text` is UNIQUE + indexed. Returns existing tag if text already exists.
    icon/color are only applied on creation, not on lookup.
    """

async def get_tag_by_id(session: AsyncSession, tag_id: int) -> TagIndex | None:

async def get_tag_by_text(session: AsyncSession, text: str) -> TagIndex | None:

async def list_all_tags(session: AsyncSession) -> list[TagIndex]:

async def update_tag(
    session: AsyncSession,
    tag_id: int,
    icon: str | None = None,
    color: str | None = None,
) -> TagIndex:
    """
    Updates icon and/or color. `text` is intentionally NOT updatable
    because it is the unique business key referenced by the UI.
    """

async def delete_tag(session: AsyncSession, tag_id: int) -> None:
    """Cascades to all TaggedReceipt rows for this tag."""
```

---

## TaggedReceipt Methods

```python
async def tag_receipt(
    session: AsyncSession,
    receipt_id: int,
    tag_id: int,
) -> TaggedReceipt:
    """
    Inserts association row. If the (receipt_id, tag_id) pair already exists
    (UniqueConstraint), return the existing row instead of raising.
    """

async def untag_receipt(
    session: AsyncSession,
    receipt_id: int,
    tag_id: int,
) -> None:

async def set_receipt_tags(
    session: AsyncSession,
    receipt_id: int,
    tag_ids: list[int],
) -> None:
    """
    Atomic full replace: removes tags not in tag_ids, adds missing ones.
    Preferred over calling tag_receipt/untag_receipt individually for bulk edits.
    """
```

---

## DB Lifecycle & Utilities

```python
async def create_db_and_tables() -> None:
    """
    Creates all tables if they do not exist.
    WARNING: The current implementation also calls drop_all — remove drop_all
    before production use. Only call create_all in normal startup.
    """

async def get_session() -> AsyncGenerator[AsyncSession, None]:
    """FastAPI dependency. Use via Depends(get_session)."""

async def check_db_connection() -> bool:
    """Executes SELECT 1. Returns True on success. Use for /health endpoint."""
```

---

## File Storage Layout

```
uploads/
└── {owner_id}/
    └── {receipt_id}/
        └── {uuid4}_{original_filename}
```

- The `uploads/` root should be configurable via `Settings` (add `UPLOAD_DIR: str = "./uploads"` to `config.py`).
- The route layer is responsible for creating the directory structure (`os.makedirs(..., exist_ok=True)`) before writing.
- `sha256` on `ReceiptFile` enables deduplication: compute hash before write, call `get_file_by_storage_key` or compare hashes to avoid storing duplicates.

---

## Route Layer Responsibilities (out of scope for `db.py`)

These are **not** implemented in `db.py` but must be handled by the caller:

| Responsibility | Where |
|---|---|
| Authorization / ownership checks | Route or dependency |
| Writing file bytes to disk | Route (using `aiofiles`) |
| Deleting file bytes from disk after `delete_file_record()` | Route |
| Collecting `storage_key` paths from `delete_receipt()` / `delete_user()` and removing files | Route |
| `session.commit()` / `session.rollback()` | Route |
| JWT validation and `sub` extraction | Auth dependency |
