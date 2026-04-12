from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # Auth0 – get these from the Auth0 Dashboard
    # AUTH0_DOMAIN  → your-tenant.us.auth0.com   (no https://)
    # AUTH0_AUDIENCE → the identifier you set for your API in Auth0
    AUTH0_DOMAIN: str = ""
    AUTH0_AUDIENCE: str = ""

    # SQLite file path
    DATABASE_URL: str = "sqlite+aiosqlite:///./database.sqlite"

    model_config = SettingsConfigDict(env_file="../.env", extra="ignore")


settings = Settings()