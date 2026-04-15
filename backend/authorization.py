from __future__ import annotations

from enum import Enum
from typing import Any

from fastapi import Depends, HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from backend.auth import get_current_user
from backend.db import User, get_session
from backend import services


class ResourceType(str, Enum):
    RECEIPT = "receipt"
    FILE = "file"
    RECIPIENT = "recipient"


class AccessPolicy(str, Enum):
    READ = "read"
    MUTATE = "mutate"
    DELETE = "delete"
    MANAGE_MEMBERS = "manage_members"


async def _authorize_receipt(
    session: AsyncSession,
    actor: User,
    resource_id: int,
    policy: AccessPolicy,
) -> Any:
    if policy == AccessPolicy.READ:
        return await services.get_visible_receipt(session, actor.id, resource_id)
    if policy in {AccessPolicy.MUTATE, AccessPolicy.DELETE}:
        return await services.get_owned_receipt(session, actor.id, resource_id)
    raise RuntimeError(f"Unsupported receipt policy: {policy}")


async def _authorize_file(
    session: AsyncSession,
    actor: User,
    resource_id: int,
    policy: AccessPolicy,
) -> Any:
    if policy == AccessPolicy.READ:
        return await services.get_file_for_actor(session, actor.id, resource_id)
    if policy in {AccessPolicy.MUTATE, AccessPolicy.DELETE}:
        return await services.get_file_for_owner(session, actor.id, resource_id)
    raise RuntimeError(f"Unsupported file policy: {policy}")


async def _authorize_recipient(
    session: AsyncSession,
    actor: User,
    resource_id: int,
    policy: AccessPolicy,
) -> Any:
    if policy == AccessPolicy.READ:
        return await services.get_visible_recipient(session, actor.id, resource_id)
    if policy in {AccessPolicy.MUTATE, AccessPolicy.DELETE, AccessPolicy.MANAGE_MEMBERS}:
        return await services.get_owned_recipient(session, actor.id, resource_id)
    raise RuntimeError(f"Unsupported recipient policy: {policy}")


_RESOURCE_HANDLERS = {
    ResourceType.RECEIPT: _authorize_receipt,
    ResourceType.FILE: _authorize_file,
    ResourceType.RECIPIENT: _authorize_recipient,
}


def _resource_state_key(resource_type: ResourceType) -> str:
    return f"authorized_{resource_type.value}"


def _coerce_resource_id(raw_id: Any, field_name: str) -> int:
    try:
        resource_id = int(raw_id)
    except (TypeError, ValueError) as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Invalid {field_name}",
        ) from exc

    if resource_id <= 0:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Invalid {field_name}",
        )

    return resource_id


async def _authorize_by_id(
    request: Request,
    session: AsyncSession,
    current_user: User,
    resource_type: ResourceType,
    resource_id: int,
    policy: AccessPolicy,
) -> Any:
    handler = _RESOURCE_HANDLERS[resource_type]

    try:
        resource = await handler(session, current_user, resource_id, policy)
    except services.ResourceNotFoundError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(exc),
        ) from exc
    except services.AuthorizationError as exc:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=str(exc),
        ) from exc

    setattr(request.state, _resource_state_key(resource_type), resource)
    return resource


async def authorize_resource_from_message(
    request: Request,
    session: AsyncSession,
    current_user: User,
    resource_type: ResourceType,
    field_name: str,
    message: Any,
    policy: AccessPolicy,
) -> Any:
    """
    Authorize a resource whose identifier is stored on a parsed protobuf
    request message rather than in the route path.
    """
    resource_id = _coerce_resource_id(getattr(message, field_name, None), field_name)
    return await _authorize_by_id(
        request=request,
        session=session,
        current_user=current_user,
        resource_type=resource_type,
        resource_id=resource_id,
        policy=policy,
    )


def authorize_resource(
    resource_type: ResourceType,
    param_name: str,
    policy: AccessPolicy,
):
    """
    FastAPI dependency factory that authorizes a resource from route params and
    stores the authorized object on request.state.
    """

    async def dependency(
        request: Request,
        session: AsyncSession = Depends(get_session),
        current_user: User = Depends(get_current_user),
    ) -> Any:
        raw_id = request.path_params.get(param_name)
        if raw_id is None:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Missing route parameter: {param_name}",
            )

        resource_id = _coerce_resource_id(raw_id, param_name)
        return await _authorize_by_id(
            request=request,
            session=session,
            current_user=current_user,
            resource_type=resource_type,
            resource_id=resource_id,
            policy=policy,
        )

    return dependency
