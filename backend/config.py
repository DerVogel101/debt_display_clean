from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


ENV_FILE = Path(__file__).resolve().parent / ".env"
DEFAULT_FRONTEND_STATIC_DIR = Path(__file__).resolve().parent / "web"


class Settings(BaseSettings):
    # Auth0 – get these from the Auth0 Dashboard
    # AUTH0_DOMAIN  → your-tenant.us.auth0.com   (no https://)
    # AUTH0_AUDIENCE → the identifier you set for your API in Auth0
    AUTH0_DOMAIN: str = ""
    AUTH0_AUDIENCE: str = ""
    AUTH0_JWT_LEEWAY_SECONDS: int = 60
    AUTH0_FULL_NAME_CLAIM: str = "https://debt-display.dervogel101.de/fullName"

    # SQLite file path
    DATABASE_URL: str = "sqlite+aiosqlite:///./database.sqlite"

    # File upload root directory
    UPLOAD_DIR: str = "./uploads"
    FILE_UPLOAD_MAX_BYTES: int = 20 * 1024 * 1024

    # Built frontend output directory mounted by FastAPI.
    # Relative paths are resolved from the backend config directory.
    FRONTEND_STATIC_DIR: str = str(DEFAULT_FRONTEND_STATIC_DIR)
    FRONTEND_HTML_CACHE_SECONDS: int = 0
    FRONTEND_SHELL_CACHE_SECONDS: int = 0

    # Local/demo seed data is enabled by default while the app is not production-ready.
    # Disable with GENERATE_TEST_DATA_ON_STARTUP=false before using real data.
    GENERATE_TEST_DATA_ON_STARTUP: bool = False

    # ── Server ports ──────────────────────────────────────────────────────────
    # Dev:  Flutter runs on :3000, backend on :3300
    # Prod: set BACKEND_HOST/BACKEND_PORT in backend/.env or environment
    BACKEND_HOST: str = "0.0.0.0"
    BACKEND_PORT: int = 3300

    # ── CORS ──────────────────────────────────────────────────────────────────
    # Comma-separated list of allowed origins.
    # Dev default covers the Flutter dev server on :3000.
    # Prod: set ALLOWED_ORIGINS=https://app.example.com in backend/.env
    ALLOWED_ORIGINS: str = "http://localhost:3000,http://127.0.0.1:3000"

    model_config = SettingsConfigDict(env_file=ENV_FILE, extra="ignore")

    @property
    def allowed_origins_list(self) -> list[str]:
        return [o.strip() for o in self.ALLOWED_ORIGINS.split(",") if o.strip()]

    @property
    def frontend_static_dir_path(self) -> Path:
        frontend_static_dir = Path(self.FRONTEND_STATIC_DIR)
        if frontend_static_dir.is_absolute():
            return frontend_static_dir.resolve()
        return (ENV_FILE.parent / frontend_static_dir).resolve()


settings = Settings()
