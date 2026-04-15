from __future__ import annotations

import re
from pathlib import Path, PurePosixPath
from uuid import uuid4

from backend.config import settings

_CONTROL_CHARS_RE = re.compile(r"[\x00-\x1f\x7f]")
_INVALID_FILENAME_CHARS_RE = re.compile(r'[<>:"/\\|?*]+')
_WHITESPACE_RE = re.compile(r"\s+")


def sanitize_download_filename(filename: str, default: str = "file") -> str:
    """
    Create a safe display/download filename.
    The sanitized name is never used as part of the stored filesystem path.
    """
    normalized = filename.replace("\\", "/")
    basename = normalized.rsplit("/", 1)[-1]
    basename = _CONTROL_CHARS_RE.sub("", basename)
    basename = _INVALID_FILENAME_CHARS_RE.sub("_", basename)
    basename = _WHITESPACE_RE.sub(" ", basename).strip(" .")

    if not basename:
        return default

    return basename


def generate_storage_key(receipt_id: int) -> str:
    """
    Generate an opaque relative storage key under a receipt-specific directory.
    """
    return f"{receipt_id}/{uuid4().hex}"


def resolve_storage_path(
    storage_key: str,
    upload_root: str | Path | None = None,
) -> Path:
    """
    Resolve a relative storage key to an absolute path under the upload root.
    Rejects absolute paths, traversal segments, and any resolved path that
    escapes the configured upload directory.
    """
    root = Path(upload_root or settings.UPLOAD_DIR).resolve()
    key_path = PurePosixPath(storage_key)

    if key_path.is_absolute():
        raise ValueError("storage_key must be relative")

    if any(part in {"", ".", ".."} for part in key_path.parts):
        raise ValueError("storage_key contains invalid path segments")

    resolved = root.joinpath(*key_path.parts).resolve()

    try:
        resolved.relative_to(root)
    except ValueError as exc:
        raise ValueError("storage_key escapes upload root") from exc

    return resolved
