"""Wallet schemas."""

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


class ConnectWalletRequest(BaseSchema):
    message: str = Field(..., description="EIP-4361 message verifying ownership of the additional wallet")
    signature: str = Field(..., description="Cryptographic signature")
