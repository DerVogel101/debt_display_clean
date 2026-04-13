"""
Auth0 JWT verification using PyJWT with RS256 + JWKS.
"""
from typing import Any

from fastapi import HTTPException, status

from backend.config import settings


async def verify_token(token: str) -> dict[str, Any]:
    """
    Verify an Auth0 access token (RS256).
    Returns decoded claims dict on success.
    Raises HTTPException(401) on any failure.
    """
    import jwt  # PyJWT with cryptography extra
    from jwt import PyJWKClient, ExpiredSignatureError, InvalidTokenError

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
        )
        return claims
    except ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token expired",
        )
    except InvalidTokenError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(exc),
        )
