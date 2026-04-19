from __future__ import annotations

from pathlib import Path
from stat import S_ISREG
from typing import Final

from fastapi.staticfiles import StaticFiles
from starlette.responses import Response
from starlette.types import Scope


_APP_SHELL_FILES: Final[frozenset[str]] = frozenset(
    {
        "flutter_bootstrap.js",
        "flutter.js",
        "main.dart.js",
        "manifest.json",
        "version.json",
        "flutter_service_worker.js",
        "assets/AssetManifest.bin",
        "assets/AssetManifest.bin.json",
        "assets/FontManifest.json",
    }
)


def build_revalidating_cache_control(max_age_seconds: int) -> str:
    if max_age_seconds <= 0:
        return "no-cache"
    return f"public, max-age={max_age_seconds}, must-revalidate"


class FrontendStaticFiles(StaticFiles):
    def __init__(
        self,
        *,
        directory: str | Path,
        html: bool = False,
        html_cache_seconds: int = 0,
        shell_cache_seconds: int = 0,
    ) -> None:
        self._frontend_directory = Path(directory).resolve()
        self._html_cache_control = build_revalidating_cache_control(
            html_cache_seconds
        )
        self._shell_cache_control = build_revalidating_cache_control(
            shell_cache_seconds
        )
        super().__init__(directory=str(self._frontend_directory), html=html)

    def file_response(
        self,
        full_path: str | Path,
        stat_result,
        scope: Scope,
        status_code: int = 200,
    ) -> Response:
        response = super().file_response(full_path, stat_result, scope, status_code)
        cache_control = self._cache_control_for(Path(full_path), stat_result)
        if cache_control is not None:
            response.headers["Cache-Control"] = cache_control
        return response

    def _cache_control_for(self, full_path: Path, stat_result) -> str | None:
        if not S_ISREG(stat_result.st_mode):
            return None

        try:
            relative_path = full_path.resolve().relative_to(
                self._frontend_directory
            ).as_posix()
        except ValueError:
            return None

        if relative_path == "index.html":
            return self._html_cache_control
        if relative_path in _APP_SHELL_FILES:
            return self._shell_cache_control
        return None
