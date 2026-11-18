"""User management and profile API endpoints."""

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.identity import User
from app.schemas.user import UserDetailResponse, UserProfileResponse, UserProfileUpdate
from app.services.user_service import UserService

router = APIRouter(prefix="/users", tags=["Users"])


@router.get("/me", response_model=UserDetailResponse, status_code=status.HTTP_200_OK)
async def get_my_profile(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> UserDetailResponse:
    """Fetch current user's profile, capabilities, and verified wallets."""
    service = UserService(db)
    return await service.get_user_detail(user_id=current_user.id)


@router.put("/me/profile", response_model=UserProfileResponse, status_code=status.HTTP_200_OK)
async def update_my_profile(
    payload: UserProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> UserProfileResponse:
    """Update profile details for the authenticated user."""
    service = UserService(db)
    profile = await service.update_profile(user_id=current_user.id, data=payload)
    await db.commit()
    return profile
