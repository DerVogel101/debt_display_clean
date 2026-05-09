from __future__ import annotations

import unittest
from pathlib import Path

from fastapi import FastAPI
from fastapi.testclient import TestClient

from backend.frontend import FrontendStaticFiles


class FrontendCacheHeadersTests(unittest.TestCase):
    def setUp(self) -> None:
        self._frontend_dir = (
            Path(__file__).resolve().parent
            / "fixtures"
            / "frontend_static"
        )

        app = FastAPI()
        app.mount(
            "/",
            FrontendStaticFiles(
                directory=self._frontend_dir,
                html=True,
                html_cache_seconds=0,
                shell_cache_seconds=60,
            ),
            name="frontend",
        )
        self._client = TestClient(app)

    def tearDown(self) -> None:
        self._client.close()

    def test_index_is_served_with_revalidation_cache_control(self) -> None:
        response = self._client.get("/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.headers.get("Cache-Control"), "no-cache")
        self.assertIn("etag", response.headers)
        self.assertIn("last-modified", response.headers)

    def test_shell_files_use_env_driven_revalidation_window(self) -> None:
        response = self._client.get("/main.dart.js")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.headers.get("Cache-Control"),
            "public, max-age=60, must-revalidate",
        )

        manifest_response = self._client.get("/assets/FontManifest.json")
        self.assertEqual(
            manifest_response.headers.get("Cache-Control"),
            "public, max-age=60, must-revalidate",
        )

    def test_main_dart_js_uses_strict_module_compatible_content_type(self) -> None:
        response = self._client.get("/main.dart.js")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.headers.get("Content-Type"), "text/javascript")

    def test_other_static_assets_keep_default_headers(self) -> None:
        response = self._client.get("/icons/Icon-192.png")

        self.assertEqual(response.status_code, 200)
        self.assertNotIn("Cache-Control", response.headers)

    def test_javascript_modules_use_strict_module_compatible_content_type(
        self,
    ) -> None:
        response = self._client.get("/canvaskit/chromium/canvaskit.js")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.headers.get("Content-Type"), "text/javascript")

    def test_wasm_files_use_wasm_content_type(self) -> None:
        response = self._client.get("/canvaskit/chromium/canvaskit.wasm")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.headers.get("Content-Type"), "application/wasm")
