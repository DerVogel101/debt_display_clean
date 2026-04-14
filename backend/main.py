from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import uvicorn

from backend.api import api_app
from backend.config import settings

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
app.mount("/", StaticFiles(directory="web/", html=True), name="frontend")
