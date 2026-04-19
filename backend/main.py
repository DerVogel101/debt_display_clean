from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

from backend.api import api_app
from backend.config import settings
from backend.frontend import FrontendStaticFiles

app = FastAPI(title="root")
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins_list,
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type", "Authorization"],
)

# API must be mounted before the catch-all static mount.
app.mount("/api", api_app)
app.mount(
    "/",
    FrontendStaticFiles(
        directory=settings.frontend_static_dir_path,
        html=True,
        html_cache_seconds=settings.FRONTEND_HTML_CACHE_SECONDS,
        shell_cache_seconds=settings.FRONTEND_SHELL_CACHE_SECONDS,
    ),
    name="frontend",
)

if __name__ == "__main__":
    uvicorn.run(app, host=settings.BACKEND_HOST, port=settings.BACKEND_PORT)
