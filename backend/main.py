import uvicorn
from fastapi import Depends, FastAPI, HTTPException, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from fastapi.staticfiles import StaticFiles
from sqlalchemy.ext.asyncio import AsyncSession

from backend.auth import verify_token
from backend.config import settings
from backend.db import get_or_create_user, get_session
from backend.proto import auth_pb2

app = FastAPI(title="root")

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins_list,
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type", "Authorization"],
)

api_app = FastAPI(title="api")


class ProtobufResponse(Response):
    media_type = "application/x-protobuf"


@api_app.get("/test")
async def test():
    raise HTTPException(
        status_code=status.HTTP_418_IM_A_TEAPOT,
        detail="You can't test an Teapot"
    )


@api_app.post("/auth/login")
async def login(
    request: Request,
    session: AsyncSession = Depends(get_session),
) -> ProtobufResponse:
    body = await request.body()
    proto_req = auth_pb2.LoginRequest()
    proto_req.ParseFromString(body)

    try:
        claims = await verify_token(proto_req.access_token)
    except HTTPException as e:
        print(e)
        resp = auth_pb2.LoginResponse(success=False, message="Invalid or expired token")
        return ProtobufResponse(content=resp.SerializeToString(), status_code=401)

    user = await get_or_create_user(
        session=session,
        sub=claims["sub"],
        email=claims.get("email"),
        name=claims.get("name"),
        avatar_url=claims.get("picture"),
    )
    await session.commit()

    resp = auth_pb2.LoginResponse(
        success=True,
        user_id=str(user.id),
        auth0_sub=user.sub,
        email=user.email or "",
    )
    return ProtobufResponse(content=resp.SerializeToString())


@api_app.post("/auth/verify")
async def verify(request: Request) -> ProtobufResponse:
    body = await request.body()
    proto_req = auth_pb2.TokenVerifyRequest()
    proto_req.ParseFromString(body)

    try:
        claims = await verify_token(proto_req.access_token)
        resp = auth_pb2.TokenVerifyResponse(
            valid=True,
            auth0_sub=claims["sub"],
            email=claims.get("email", ""),
            expires_at=int(claims["exp"]),
        )
    except HTTPException as exc:
        resp = auth_pb2.TokenVerifyResponse(valid=False, message=exc.detail)
        return ProtobufResponse(content=resp.SerializeToString(), status_code=401)

    return ProtobufResponse(content=resp.SerializeToString())


# API must be mounted before the catch-all static mount — Starlette matches
# mounts in registration order, so "/" would swallow "/api/*" if first.
app.mount("/api", api_app)
app.mount("/", StaticFiles(directory="web/", html=True), name="frontend")

if __name__ == "__main__":
    uvicorn.run(app, host=settings.BACKEND_HOST, port=settings.BACKEND_PORT)
