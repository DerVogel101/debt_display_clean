"""
Auth0 JWT verification using PyJWT with RS256 + JWKS.
"""
from typing import Any

from fastapi import Depends, HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from backend.config import settings
from backend.db import User, get_session, get_user_by_sub


async def fetch_userinfo(access_token: str) -> dict[str, Any]:
    """
    Best-effort profile fetch from Auth0's /userinfo endpoint.
    Returns an empty dict when enrichment is unavailable so login can still
    succeed with the verified subject claim alone.
    """
    import httpx

    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(
                f"https://{settings.AUTH0_DOMAIN}/userinfo",
                headers={"Authorization": f"Bearer {access_token}"},
            )
            response.raise_for_status()
            payload = response.json()
    except (httpx.HTTPError, ValueError):
        return {}

    return payload if isinstance(payload, dict) else {}


async def verify_token(token: str) -> dict[str, Any]:
    """
    Verify an Auth0 access token (RS256).
    Returns decoded claims dict on success.
    Raises HTTPException(401) on any failure.
    """
    import jwt  # PyJWT with cryptography extra
    from jwt import PyJWKClient, PyJWKClientError, ExpiredSignatureError, InvalidTokenError, PyJWTError

    try:
        jwks_client = PyJWKClient(
            f"https://{settings.AUTH0_DOMAIN}/.well-known/jwks.json",
            cache_keys=True,
        )
        signing_key = jwks_client.get_signing_key_from_jwt(token)
        claims = jwt.decode(
            token,
            signing_key.key,
            algorithms=["RS256"],
            audience=settings.AUTH0_AUDIENCE,
            issuer=f"https://{settings.AUTH0_DOMAIN}/",
            leeway=settings.AUTH0_JWT_LEEWAY_SECONDS,
        )
        return claims
    except ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token expired",
        )
    except (InvalidTokenError, PyJWTError, PyJWKClientError, ValueError) as exc:
        detail = "Token expired" if "expired" in str(exc).lower() else str(exc)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=detail,
        )


def _extract_bearer_token(request: Request) -> str:
    authorization = request.headers.get("Authorization", "").strip()
    scheme, _, token = authorization.partition(" ")

    if scheme.lower() != "bearer" or not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid Authorization header",
        )

    return token.strip()


async def require_auth(request: Request) -> dict[str, Any]:
    """
    FastAPI dependency. Verifies bearer token and stores claims on request.state.
    """
    claims = await verify_token(_extract_bearer_token(request))
    request.state.auth_claims = claims
    return claims


async def get_current_user(
    request: Request,
    session: AsyncSession = Depends(get_session),
) -> User:
    """
    Resolve the authenticated token to a local user row.
    """
    claims = await require_auth(request)
    sub = claims.get("sub")
    if not sub:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token missing subject claim",
        )

    user = await get_user_by_sub(session, sub)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authenticated user is not registered locally",
        )

    request.state.current_user = user
    return user


def get_auth_claims(request: Request) -> dict[str, Any]:
    """
    Read claims populated by require_auth/auth_required.
    """
    claims = getattr(request.state, "auth_claims", None)
    if claims is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required",
        )
    return claims