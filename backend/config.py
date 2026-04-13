from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # Auth0 – get these from the Auth0 Dashboard
    # AUTH0_DOMAIN  → your-tenant.us.auth0.com   (no https://)
    # AUTH0_AUDIENCE → the identifier you set for your API in Auth0
    AUTH0_DOMAIN: str = ""
    AUTH0_AUDIENCE: str = ""

    # SQLite file path
    DATABASE_URL: str = "sqlite+aiosqlite:///./database.sqlite"

    # File upload root directory
    UPLOAD_DIR: str = "./uploads"

    # ── Server ports ──────────────────────────────────────────────────────────
    # Dev:  Flutter runs on :3000, backend on :3300
    # Prod: set BACKEND_HOST/BACKEND_PORT + FRONTEND_URL in .env / environment
    BACKEND_HOST: str = "0.0.0.0"
    BACKEND_PORT: int = 3300

    # ── CORS ──────────────────────────────────────────────────────────────────
    # Comma-separated list of allowed origins.
    # Dev default covers the Flutter dev server on :3000.
    # Prod: set ALLOWED_ORIGINS=https://app.example.com in .env
    ALLOWED_ORIGINS: str = "http://localhost:3000,http://127.0.0.1:3000"

    model_config = SettingsConfigDict(env_file="../.env", extra="ignore")

    @property
    def allowed_origins_list(self) -> list[str]:
        return [o.strip() for o in self.ALLOWED_ORIGINS.split(",") if o.strip()]


settings = Settings()
