# Authorization TODO

Authorization for receipt, recipient, tag, and file endpoints is intentionally deferred.

## Required before exposing mutable business endpoints

- Add route/service-level authorization checks on every non-auth endpoint.
- Do not rely on `verify_token()` or `require_auth()` alone; they authenticate caller but do not authorize specific actions.
- Bind every receipt mutation to authenticated user in the query itself, not in a separate lookup step.
- Only allow receipt owners to update, mark paid/unpaid, delete, attach files, remove files, tag, or untag a receipt.
- For read access, decide explicitly whether only the owner can read a receipt or whether recipient members can also read it.
- For recipient operations, only allow the recipient owner to update membership, rename, or delete the recipient.
- If recipient members get any receipt access, check membership server-side from DB state, never from client-supplied IDs.
- If file endpoints are added, verify caller is allowed to access the parent receipt before any file read, write, or delete.
- Generate file storage keys server-side and keep filesystem authorization tied to receipt ownership/membership.
- Return `403` for authenticated users without access and `404` when hiding object existence is preferable.

## Suggested implementation shape

- Add owner-scoped service helpers like `get_receipt_for_owner(session, receipt_id, owner_id)`.
- Add recipient membership helpers for any shared-access paths.
- Keep authorization in route/service layer, but make DB helper names hard to misuse.
- Add tests for cross-user access attempts:
  - user A cannot update/delete/tag user B's receipt
  - user A cannot delete file from user B's receipt
  - non-owner recipient member behavior matches intended policy
