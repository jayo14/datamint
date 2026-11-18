"""API route dependencies for authentication, user session, and capabilities."""

import uuid
from typing import Callable, List
from fastapi import Depends, Header, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from app.core.database import get_db
from app.core.exceptions import UnauthorizedCapabilityException
from app.core.security import decode_token
from app.models.enums import CapabilityType
from app.models.identity import User


async def get_current_user(
    authorization: str = Header(..., description="Bearer JWT token"),
    db: AsyncSession = Depends(get_db),
) -> User:
    """Validate Bearer JWT and return authenticated User with capabilities loaded."""
    if not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authorization header format. Expected 'Bearer <token>'",
        )

    token = authorization.split(" ")[1]
    payload = decode_token(token)
    user_id_str = payload.get("sub")
    if not user_id_str:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token missing subject identifier",
        )

    try:
        user_uuid = uuid.UUID(user_id_str)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid user UUID in token",
        )

    query = (
        select(User)
        .where(User.id == user_uuid, User.is_active.is_(True))
        .options(selectinload(User.capabilities), selectinload(User.wallets))
    )
    result = await db.execute(query)
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User associated with token not found or deactivated",
        )

    return user


def require_capability(required_capability: CapabilityType) -> Callable:
    """Dependency factory checking whether authenticated user holds the required capability."""
    async def capability_checker(current_user: User = Depends(get_current_user)) -> User:
        user_caps = [c.capability_type for c in current_user.capabilities if c.is_enabled]
        if required_capability.value not in user_caps:
            raise UnauthorizedCapabilityException(required_capability.value)
        return current_user

    return capability_checker
