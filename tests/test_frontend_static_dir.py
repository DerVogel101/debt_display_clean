from __future__ import annotations

import subprocess
import sys
import unittest
from pathlib import Path

from fastapi import FastAPI

from backend.config import ENV_FILE, settings
from backend.frontend import FrontendStaticFiles


class FrontendStaticDirResolutionTests(unittest.TestCase):
    def setUp(self) -> None:
        self._original_frontend_static_dir = settings.FRONTEND_STATIC_DIR
        self._workspace_dir = Path(__file__).resolve().parents[1]

    def tearDown(self) -> None:
        settings.FRONTEND_STATIC_DIR = self._original_frontend_static_dir

    def _resolve_frontend_static_dir_from_subprocess(self, start_dir: Path) -> Path:
        command = [
            sys.executable,
            "-c",
            (
                f"import sys; sys.path.insert(0, {str(self._workspace_dir)!r}); "
                "from backend.config import Settings; "
                "print(Settings(FRONTEND_STATIC_DIR='./web').frontend_static_dir_path)"
            ),
        ]
        result = subprocess.run(
            command,
            cwd=start_dir,
            capture_output=True,
            check=True,
            text=True,
        )
        return Path(result.stdout.strip())

    def test_relative_frontend_static_dir_is_resolved_from_backend_env_directory(
        self,
    ) -> None:
        expected_dir = (ENV_FILE.parent / "web").resolve()
        self.assertEqual(
            self._resolve_frontend_static_dir_from_subprocess(self._workspace_dir),
            expected_dir,
        )
        self.assertEqual(
            self._resolve_frontend_static_dir_from_subprocess(ENV_FILE.parent),
            expected_dir,
        )

    def test_absolute_frontend_static_dir_is_preserved(self) -> None:
        expected_dir = (ENV_FILE.parent / "web").resolve()
        settings.FRONTEND_STATIC_DIR = str(expected_dir)

        self.assertEqual(settings.frontend_static_dir_path, expected_dir)

    def test_fastapi_mount_uses_resolved_frontend_static_dir(self) -> None:
        expected_dir = (ENV_FILE.parent / "web").resolve()
        settings.FRONTEND_STATIC_DIR = "./web"

        app = FastAPI()
        app.mount(
            "/",
            FrontendStaticFiles(
                directory=settings.frontend_static_dir_path,
                html=True,
            ),
            name="frontend",
        )

        frontend_mount = next(
            route
            for route in app.routes
            if getattr(route, "name", None) == "frontend"
        )
        self.assertEqual(frontend_mount.app._frontend_directory, expected_dir)
