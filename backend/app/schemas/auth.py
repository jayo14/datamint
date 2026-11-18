"""Authentication and session schemas (EIP-4361 SIWE)."""

import uuid
from datetime import datetime
from typing import List, Optional
from pydantic import Field
from app.schemas.common import BaseSchema


class NonceRequest(BaseSchema):
    address: str = Field(..., description="Ethereum/Celo wallet address (0x...)")
    chain_id: int = Field(default=42220, description="Celo Chain ID")


class NonceResponse(BaseSchema):
    nonce: str
    message: str
    expires_at: datetime


class VerifySignatureRequest(BaseSchema):
    message: str = Field(..., description="Full EIP-4361 signed text message")
    signature: str = Field(..., description="0x-prefixed cryptographic signature")


class UserSummary(BaseSchema):
    id: uuid.UUID
    email: Optional[str] = None
    primary_wallet: str
    capabilities: List[str]


class AuthTokenResponse(BaseSchema):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    user: UserSummary


class RefreshTokenRequest(BaseSchema):
    refresh_token: str
