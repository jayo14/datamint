"""Protected EIP-712 reward signer service matching DatasetEscrow.sol specification."""

import hashlib
import secrets
import time
import uuid
from datetime import datetime, timezone
from decimal import Decimal
from typing import Optional, Protocol, Tuple

from eth_account import Account
from eth_account.messages import encode_typed_data
from eth_utils import keccak, to_checksum_address
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.config import settings
from app.core.exceptions import (
    DomainRuleViolationException,
    EntityNotFoundException,
    InvalidStateTransitionException,
)
from app.models.campaign import DatasetCampaign
from app.models.enums import CampaignStatus, PayoutStatus, SubmissionStatus
from app.models.financial import PayoutAuthorization
from app.models.submission import Submission
from app.models.wallet import Wallet
from app.services.ledger_service import LedgerService


class SignerProvider(Protocol):
    """Abstraction for cryptographic key storage and signing (e.g., local key, AWS KMS, HashiCorp Vault)."""

    def get_signer_address(self) -> str:
        """Return the public address of the authorized signer."""
        ...

    def sign_reward_voucher(
        self,
        campaign_id_hex: str,
        contributor_address: str,
        amount_wei: int,
        nonce_hex: str,
        deadline_timestamp: int,
    ) -> Tuple[str, str]:
        """Produce EIP-712 signature and structured data digest matching DatasetEscrow.sol.

        Returns (signature_hex, digest_hash_hex).
        """
        ...


class LocalSignerProvider:
    """In-memory private key signer implementing EIP-712 structured data signing."""

    def __init__(
        self,
        private_key: str,
        contract_address: str,
        chain_id: int,
    ):
        self.account = Account.from_key(private_key)
        self.contract_address = to_checksum_address(contract_address)
        self.chain_id = chain_id

    def get_signer_address(self) -> str:
        return self.account.address

    def sign_reward_voucher(
        self,
        campaign_id_hex: str,
        contributor_address: str,
        amount_wei: int,
        nonce_hex: str,
        deadline_timestamp: int,
    ) -> Tuple[str, str]:
        domain_data = {
            "name": "DataMint DatasetEscrow",
            "version": "1",
            "chainId": self.chain_id,
            "verifyingContract": self.contract_address,
        }
        message_types = {
            "RewardAuthorization": [
                {"name": "campaignId", "type": "bytes32"},
                {"name": "contributor", "type": "address"},
                {"name": "amount", "type": "uint256"},
                {"name": "nonce", "type": "bytes32"},
                {"name": "deadline", "type": "uint256"},
            ],
        }
        message_data = {
            "campaignId": campaign_id_hex,
            "contributor": to_checksum_address(contributor_address),
            "amount": amount_wei,
            "nonce": nonce_hex,
            "deadline": deadline_timestamp,
        }

        signable = encode_typed_data(
            domain_data=domain_data,
            message_types=message_types,
            message_data=message_data,
        )
        signed = self.account.sign_message(signable)
        signature_hex = "0x" + signed.signature.hex()

        # Compute digest hash for verification and indexing
        digest_bytes = keccak(bytes.fromhex(signed.signature.hex()))
        digest_hash_hex = "0x" + digest_bytes.hex()

        return signature_hex, digest_hash_hex


def get_default_signer_provider() -> SignerProvider:
    """Factory returning configured EIP-712 signer."""
    return LocalSignerProvider(
        private_key=settings.PLATFORM_SIGNER_PRIVATE_KEY,
        contract_address=settings.ESCROW_CONTRACT_ADDRESS,
        chain_id=settings.CELO_CHAIN_ID,
    )


class PayoutSignerService:
    """Service managing reward authorization generation, off-chain EIP-712 vouchers, and ledger reservations."""

    def __init__(
        self,
        db: AsyncSession,
        ledger_service: Optional[LedgerService] = None,
        signer_provider: Optional[SignerProvider] = None,
    ):
        self.db = db
        self.ledger_service = ledger_service or LedgerService(db)
        self.signer_provider = signer_provider or get_default_signer_provider()

    async def generate_payout_voucher(
        self,
        submission_id: uuid.UUID,
        validity_seconds: int = 7 * 86400,  # 7 days default
    ) -> PayoutAuthorization:
        """Generate and sign an EIP-712 reward authorization voucher for an approved submission."""
        # 1. Load submission with campaign, escrow, contributor, and existing payout authorization
        query = (
            select(Submission)
            .where(Submission.id == submission_id)
            .options(
                selectinload(Submission.campaign).selectinload(DatasetCampaign.escrow),
                selectinload(Submission.contributor),
                selectinload(Submission.payout_authorization),
            )
        )
        submission = (await self.db.execute(query)).scalar_one_or_none()
        if not submission:
            raise EntityNotFoundException("Submission", submission_id)

        # 2. Status verification
        if submission.status != SubmissionStatus.APPROVED.value:
            raise DomainRuleViolationException(
                f"Cannot authorize payout for submission with status '{submission.status}'. "
                f"Submission must be in '{SubmissionStatus.APPROVED.value}' state."
            )

        campaign = submission.campaign
        if campaign.status != CampaignStatus.ACTIVE.value:
            raise DomainRuleViolationException(
                f"Campaign '{campaign.title}' is not ACTIVE (current: {campaign.status})."
            )

        # 3. Idempotency check: if valid voucher already exists, return it
        payout_query = select(PayoutAuthorization).where(PayoutAuthorization.submission_id == submission_id)
        existing_payout = (await self.db.execute(payout_query)).scalar_one_or_none()
        now_utc = datetime.now(timezone.utc)
        if existing_payout:
            if existing_payout.status == PayoutStatus.CLAIMED.value:
                return existing_payout
            if existing_payout.status == PayoutStatus.AUTHORIZED.value and existing_payout.expires_at > now_utc:
                return existing_payout

        # 4. Resolve contributor verified primary wallet
        wallet_query = (
            select(Wallet)
            .where(Wallet.user_id == submission.contributor_id)
            .order_by(Wallet.is_primary.desc(), Wallet.verified_at.desc())
        )
        wallet = (await self.db.execute(wallet_query)).scalars().first()
        if not wallet:
            raise DomainRuleViolationException(
                "Contributor does not have a verified wallet address linked to receive rewards."
            )
        contributor_address = to_checksum_address(wallet.address)

        # 5. Determine reward amount and wei conversion
        reward_cusd = campaign.reward_per_submission
        amount_wei = int(reward_cusd * Decimal(10**18))

        # 6. Reserve payout in double-entry financial ledger
        reference_id = f"payout_sub_{submission.id}"
        await self.ledger_service.reserve_payout(
            campaign_id=campaign.id,
            amount=reward_cusd,
            reference_id=reference_id,
            notes=f"EIP-712 voucher reservation for submission {submission.id}",
        )

        # 7. Format parameters for EIP-712 structured data
        # On-chain campaignId bytes32
        escrow_onchain_id = campaign.escrow.onchain_campaign_id if campaign.escrow else None
        if escrow_onchain_id and escrow_onchain_id.startswith("0x") and len(escrow_onchain_id) == 66:
            onchain_campaign_id = escrow_onchain_id
        else:
            # Deterministic bytes32 from campaign UUID
            cam_digest = hashlib.sha256(str(campaign.id).encode("utf-8")).hexdigest()
            onchain_campaign_id = "0x" + cam_digest

        nonce_hex = "0x" + secrets.token_hex(32)
        deadline_timestamp = int(time.time()) + validity_seconds
        expires_at = datetime.fromtimestamp(deadline_timestamp, timezone.utc)

        # 8. Cryptographically sign voucher
        signature_hex, voucher_hash = self.signer_provider.sign_reward_voucher(
            campaign_id_hex=onchain_campaign_id,
            contributor_address=contributor_address,
            amount_wei=amount_wei,
            nonce_hex=nonce_hex,
            deadline_timestamp=deadline_timestamp,
        )

        # 9. Persist PayoutAuthorization record
        if existing_payout:
            # Update existing expired voucher
            existing_payout.recipient_address = contributor_address
            existing_payout.amount = reward_cusd
            existing_payout.nonce = nonce_hex
            existing_payout.onchain_campaign_id = onchain_campaign_id
            existing_payout.deadline = deadline_timestamp
            existing_payout.voucher_hash = voucher_hash
            existing_payout.signature = signature_hex
            existing_payout.status = PayoutStatus.AUTHORIZED.value
            existing_payout.expires_at = expires_at
            payout_record = existing_payout
        else:
            payout_record = PayoutAuthorization(
                submission_id=submission.id,
                contributor_id=submission.contributor_id,
                amount=reward_cusd,
                recipient_address=contributor_address,
                nonce=nonce_hex,
                onchain_campaign_id=onchain_campaign_id,
                deadline=deadline_timestamp,
                voucher_hash=voucher_hash,
                signature=signature_hex,
                status=PayoutStatus.AUTHORIZED.value,
                expires_at=expires_at,
            )
            self.db.add(payout_record)

        await self.db.flush()
        return payout_record

    async def get_payout_voucher(self, submission_id: uuid.UUID) -> Optional[PayoutAuthorization]:
        """Fetch active payout voucher for a submission."""
        query = select(PayoutAuthorization).where(PayoutAuthorization.submission_id == submission_id)
        return (await self.db.execute(query)).scalar_one_or_none()

    async def record_claim_submission(
        self,
        submission_id: uuid.UUID,
        claim_tx_hash: str,
    ) -> PayoutAuthorization:
        """Record that the contributor has broadcasted the claimReward transaction."""
        query = select(PayoutAuthorization).where(PayoutAuthorization.submission_id == submission_id)
        payout = (await self.db.execute(query)).scalar_one_or_none()
        if not payout:
            raise EntityNotFoundException("PayoutAuthorization for submission", submission_id)

        payout.claim_tx_hash = claim_tx_hash
        payout.claimed_at = datetime.now(timezone.utc)
        await self.db.flush()
        return payout

    async def expire_payout_voucher(self, payout_id: uuid.UUID) -> PayoutAuthorization:
        """Expire a voucher past its deadline, returning reserved funds to available balance."""
        query = (
            select(PayoutAuthorization)
            .where(PayoutAuthorization.id == payout_id)
            .options(selectinload(PayoutAuthorization.submission).selectinload(Submission.campaign))
        )
        payout = (await self.db.execute(query)).scalar_one_or_none()
        if not payout:
            raise EntityNotFoundException("PayoutAuthorization", payout_id)

        if payout.status != PayoutStatus.AUTHORIZED.value:
            raise InvalidStateTransitionException(payout.status, PayoutStatus.EXPIRED.value)

        # Unreserve funds in ledger
        campaign = payout.submission.campaign
        reference_id = f"unres_exp_{payout.id}"
        await self.ledger_service.unreserve_payout(
            campaign_id=campaign.id,
            amount=payout.amount,
            reference_id=reference_id,
            notes=f"Voucher {payout.id} expired past deadline",
        )

        payout.status = PayoutStatus.EXPIRED.value
        await self.db.flush()
        return payout

    async def revoke_payout_voucher(self, payout_id: uuid.UUID, reason: str) -> PayoutAuthorization:
        """Revoke a voucher before execution (e.g. fraudulent activity detected post-approval)."""
        query = (
            select(PayoutAuthorization)
            .where(PayoutAuthorization.id == payout_id)
            .options(selectinload(PayoutAuthorization.submission).selectinload(Submission.campaign))
        )
        payout = (await self.db.execute(query)).scalar_one_or_none()
        if not payout:
            raise EntityNotFoundException("PayoutAuthorization", payout_id)

        if payout.status != PayoutStatus.AUTHORIZED.value:
            raise InvalidStateTransitionException(payout.status, PayoutStatus.REVOKED.value)

        campaign = payout.submission.campaign
        reference_id = f"unres_rev_{payout.id}"
        await self.ledger_service.unreserve_payout(
            campaign_id=campaign.id,
            amount=payout.amount,
            reference_id=reference_id,
            notes=f"Voucher {payout.id} revoked: {reason}",
        )

        payout.status = PayoutStatus.REVOKED.value
        await self.db.flush()
        return payout
