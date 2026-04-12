from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from fastapi import HTTPException, status

app = FastAPI(title="root")

origins = [
    "http://localhost",
    "http://127.0.0.1",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/", StaticFiles(directory="web/", html=True), name="frontend")

api_app = FastAPI(title="api")

@api_app.get("/test")
async def test():
    raise HTTPException(
        status_code=status.HTTP_418_IM_A_TEAPOT,
        detail="You can't test an Teapot"
    )


app.mount("/api", api_app)