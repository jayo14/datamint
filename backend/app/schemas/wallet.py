"""Wallet schemas for linking, unlinking, and listing verified user wallets."""

import uuid
from datetime import datetime

from pydantic import Field

from app.schemas.common import BaseSchema


class WalletResponse(BaseSchema):
    id: uuid.UUID
    address: str
    chain_id: int
    is_primary: bool
    verified_at: datetime


class LinkWalletRequest(BaseSchema):
    message: str = Field(
        ..., description="EIP-4361 message verifying ownership of the additional wallet"
    )
    signature: str = Field(..., description="Cryptographic signature")


class SetPrimaryWalletRequest(BaseSchema):
    address: str = Field(..., description="Wallet address to set as primary")
