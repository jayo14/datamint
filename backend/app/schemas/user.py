"""User profile and capability schemas."""

import uuid
from datetime import datetime
from typing import List, Optional
from pydantic import Field
from app.schemas.common import BaseSchema
from app.schemas.wallet import WalletResponse


class UserProfileUpdate(BaseSchema):
    display_name: Optional[str] = Field(default=None, max_length=100)
    avatar_url: Optional[str] = Field(default=None, max_length=500)
    bio: Optional[str] = None
    metadata_json: Optional[dict] = None


class UserProfileResponse(BaseSchema):
    id: uuid.UUID
    user_id: uuid.UUID
    display_name: Optional[str] = None
    avatar_url: Optional[str] = None
    bio: Optional[str] = None
    metadata_json: Optional[dict] = None
    updated_at: datetime


class UserDetailResponse(BaseSchema):
    id: uuid.UUID
    email: Optional[str] = None
    is_active: bool
    is_verified: bool
    created_at: datetime
    updated_at: datetime
    profile: Optional[UserProfileResponse] = None
    capabilities: List[str] = []
    wallets: List[WalletResponse] = []
