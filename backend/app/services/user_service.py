"""User profile and capability management service."""

import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.exceptions import EntityNotFoundException
from app.models.identity import User, UserProfile
from app.schemas.user import UserDetailResponse, UserProfileResponse, UserProfileUpdate
from app.schemas.wallet import WalletResponse


class UserService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_user_detail(self, user_id: uuid.UUID) -> UserDetailResponse:
        """Fetch user with profile, capabilities, and verified wallets."""
        query = (
            select(User)
            .where(User.id == user_id)
            .options(
                selectinload(User.profile),
                selectinload(User.capabilities),
                selectinload(User.wallets),
            )
        )
        result = await self.db.execute(query)
        user = result.scalar_one_or_none()
        if not user:
            raise EntityNotFoundException("User", user_id)

        caps = [c.capability_type for c in user.capabilities if c.is_enabled]
        return UserDetailResponse(
            id=user.id,
            email=user.email,
            is_active=user.is_active,
            is_verified=user.is_verified,
            created_at=user.created_at,
            updated_at=user.updated_at,
            profile=UserProfileResponse.model_validate(user.profile) if user.profile else None,
            capabilities=caps,
            wallets=[WalletResponse.model_validate(w) for w in user.wallets],
        )

    async def update_profile(
        self, user_id: uuid.UUID, data: UserProfileUpdate
    ) -> UserProfileResponse:
        """Update or create user profile."""
        query = select(UserProfile).where(UserProfile.user_id == user_id)
        profile = (await self.db.execute(query)).scalar_one_or_none()

        if not profile:
            profile = UserProfile(user_id=user_id)
            self.db.add(profile)

        if data.display_name is not None:
            profile.display_name = data.display_name
        if data.avatar_url is not None:
            profile.avatar_url = data.avatar_url
        if data.bio is not None:
            profile.bio = data.bio
        if data.metadata_json is not None:
            profile.metadata_json = data.metadata_json

        await self.db.flush()
        return UserProfileResponse.model_validate(profile)
