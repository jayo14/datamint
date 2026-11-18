"""Pydantic schemas for EIP-712 reward vouchers and payout claims."""

import uuid
from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field


class RewardVoucherData(BaseModel):
    """EIP-712 RewardAuthorization struct payload expected by DatasetEscrow.claimReward."""

    model_config = ConfigDict(populate_by_name=True)

    campaign_id: str = Field(..., alias="campaignId", description="bytes32 campaign identifier")
    contributor: str = Field(..., description="Checksummed contributor wallet address")
    amount: str = Field(..., description="cUSD reward amount in wei as a decimal string")
    amount_wei: int = Field(..., description="Integer wei amount")
    nonce: str = Field(..., description="bytes32 unique replay prevention nonce")
    deadline: int = Field(..., description="Unix timestamp expiration deadline")


class PayoutVoucherResponse(BaseModel):
    """Complete EIP-712 voucher envelope returned to client for on-chain submission."""

    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    submission_id: uuid.UUID
    contributor_id: uuid.UUID
    amount: Decimal
    recipient_address: str
    status: str
    expires_at: datetime
    voucher: RewardVoucherData
    signature: str
    contract_address: str
    chain_id: int


class ClaimSubmissionRequest(BaseModel):
    """Payload sent by client after executing claimReward on Celo."""

    claim_tx_hash: str = Field(
        ...,
        min_length=66,
        max_length=66,
        pattern=r"^0x[a-fA-F0-9]{64}$",
        description="Transaction hash of the on-chain claimReward execution",
    )
