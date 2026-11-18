"""Authentication and session schemas (EIP-4361 SIWE and Password Auth)."""

import uuid
from datetime import datetime
from typing import List, Optional
from pydantic import EmailStr, Field
from app.schemas.common import BaseSchema


class UserRegisterRequest(BaseSchema):
    email: EmailStr = Field(..., description="User email address")
    password: str = Field(..., min_length=8, description="User password (min 8 characters)")
    display_name: Optional[str] = Field(default=None, max_length=100)


class UserLoginRequest(BaseSchema):
    email: EmailStr = Field(..., description="User email address")
    password: str = Field(..., description="User password")


class NonceRequest(BaseSchema):
    address: str = Field(..., description="Ethereum/Celo wallet address (0x...)")
    chain_id: int = Field(default=42220, description="Celo Chain ID")
    action: str = Field(default="login", description="Intended action (login, link_wallet)")


class NonceResponse(BaseSchema):
    nonce: str
    message: str
    action: str
    expires_at: datetime


class VerifySignatureRequest(BaseSchema):
    message: str = Field(..., description="Full EIP-4361 signed text message")
    signature: str = Field(..., description="0x-prefixed cryptographic signature")


class UserSummary(BaseSchema):
    id: uuid.UUID
    email: Optional[str] = None
    primary_wallet: Optional[str] = None
    capabilities: List[str] = []


class AuthTokenResponse(BaseSchema):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    user: UserSummary


class RefreshTokenRequest(BaseSchema):
    refresh_token: str


class LogoutRequest(BaseSchema):
    refresh_token: Optional[str] = None
