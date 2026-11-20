"""Tests for EIP-712 reward voucher signing, recovery, and financial ledger reservation."""

import secrets
from decimal import Decimal

import pytest
from eth_account import Account
from eth_account.messages import encode_typed_data

from app.core.exceptions import DomainRuleViolationException
from app.models.enums import DataType, PayoutStatus, SubmissionStatus
from app.models.identity import User
from app.models.wallet import Wallet
from app.schemas.campaign import CampaignCreate
from app.schemas.submission import SubmissionDraftCreate
from app.services.campaign_service import CampaignService
from app.services.ledger_service import LedgerService
from app.services.payout_signer import LocalSignerProvider, PayoutSignerService
from app.services.submission_service import SubmissionService


@pytest.mark.asyncio
async def test_eip712_voucher_generation_and_cryptographic_recovery(db_session):
    """Test generating a reward voucher, verifying EIP-712 signature recovery, and ledger reservation."""
    campaign_service = CampaignService(db_session)
    submission_service = SubmissionService(db_session)
    ledger_service = LedgerService(db_session)

    # Generate test platform signer account
    test_signer = Account.create()
    test_contract = "0x" + "c0de" * 10
    signer_provider = LocalSignerProvider(
        private_key=test_signer.key.hex(),
        contract_address=test_contract,
        chain_id=42220,
    )
    payout_service = PayoutSignerService(
        db=db_session,
        ledger_service=ledger_service,
        signer_provider=signer_provider,
    )

    creator = User(email="creator_payout@datamint.ai")
    contributor = User(email="contrib_payout@datamint.ai")
    db_session.add_all([creator, contributor])
    await db_session.flush()

    # Link verified contributor wallet
    contrib_wallet = Account.create()
    wallet = Wallet(
        user_id=contributor.id,
        address=contrib_wallet.address.lower(),
        chain_id=42220,
        is_primary=True,
    )
    db_session.add(wallet)
    await db_session.flush()

    # Create & fund campaign
    campaign = await campaign_service.create_campaign(
        creator_id=creator.id,
        data=CampaignCreate(
            title="Audio Transcription Dataset",
            description="Short audio clips",
            data_type=DataType.VOICE,
            target_submissions=10,
            reward_per_submission=Decimal("3.50"),
        ),
    )
    campaign.escrow.total_funded = Decimal("35.00")
    campaign.escrow.total_available = Decimal("35.00")
    await campaign_service.activate_campaign(campaign.id, f"0x{secrets.token_hex(32)}")
    await db_session.flush()

    # Create submission
    sub = await submission_service.create_draft(
        contributor_id=contributor.id,
        data=SubmissionDraftCreate(
            campaign_id=campaign.id,
            draft_data={"duration": 12.5},
        ),
    )

    # 1. Attempt to generate voucher on non-approved submission -> fails
    with pytest.raises(DomainRuleViolationException):
        await payout_service.generate_payout_voucher(sub.id)

    # Mark submission approved
    sub.status = SubmissionStatus.APPROVED.value
    await db_session.flush()

    # 2. Generate EIP-712 payout authorization
    payout = await payout_service.generate_payout_voucher(sub.id)
    assert payout is not None
    assert payout.status == PayoutStatus.AUTHORIZED.value
    assert payout.amount == Decimal("3.50")
    assert payout.recipient_address == contrib_wallet.address
    assert payout.nonce.startswith("0x") and len(payout.nonce) == 66
    assert payout.signature.startswith("0x") and len(payout.signature) == 132

    # 3. Verify ledger state transition: 3.50 moved from available to reserved
    escrow = await ledger_service.get_escrow(campaign.id)
    assert escrow.total_funded == Decimal("35.00")
    assert escrow.total_available == Decimal("31.50")
    assert escrow.total_reserved == Decimal("3.50")
    assert escrow.total_claimed == Decimal("0.00")
    assert escrow.check_invariant() is True

    # 4. Independent EIP-712 recovery test: reconstruct structured data and recover signer
    domain_data = {
        "name": "DataMint DatasetEscrow",
        "version": "1",
        "chainId": 42220,
        "verifyingContract": test_contract,
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
        "campaignId": payout.onchain_campaign_id,
        "contributor": contrib_wallet.address,
        "amount": int(Decimal("3.50") * Decimal(10**18)),
        "nonce": payout.nonce,
        "deadline": payout.deadline,
    }
    signable = encode_typed_data(
        domain_data=domain_data, message_types=message_types, message_data=message_data
    )
    recovered_address = Account.recover_message(
        signable,
        signature=bytes.fromhex(payout.signature[2:]),
    )
    assert recovered_address == test_signer.address


@pytest.mark.asyncio
async def test_voucher_idempotency_and_revocation(db_session):
    """Test idempotent re-fetching and revoking unspent vouchers."""
    campaign_service = CampaignService(db_session)
    submission_service = SubmissionService(db_session)
    ledger_service = LedgerService(db_session)

    test_signer = Account.create()
    test_contract = "0x" + "feed" * 10
    signer_provider = LocalSignerProvider(
        private_key=test_signer.key.hex(),
        contract_address=test_contract,
        chain_id=42220,
    )
    payout_service = PayoutSignerService(
        db=db_session,
        ledger_service=ledger_service,
        signer_provider=signer_provider,
    )

    creator = User(email="creator_revok@datamint.ai")
    contributor = User(email="contrib_revok@datamint.ai")
    db_session.add_all([creator, contributor])
    await db_session.flush()

    contrib_wallet = Account.create()
    wallet = Wallet(
        user_id=contributor.id,
        address=contrib_wallet.address.lower(),
        chain_id=42220,
        is_primary=True,
    )
    db_session.add(wallet)
    await db_session.flush()

    campaign = await campaign_service.create_campaign(
        creator_id=creator.id,
        data=CampaignCreate(
            title="Text Translation",
            description="Translate prompts",
            data_type=DataType.TEXT,
            target_submissions=5,
            reward_per_submission=Decimal("5.00"),
        ),
    )
    campaign.escrow.total_funded = Decimal("25.00")
    campaign.escrow.total_available = Decimal("25.00")
    await campaign_service.activate_campaign(campaign.id, f"0x{secrets.token_hex(32)}")
    await db_session.flush()

    sub = await submission_service.create_draft(
        contributor_id=contributor.id,
        data=SubmissionDraftCreate(
            campaign_id=campaign.id,
            draft_data={"translation": "Bonjour le monde"},
        ),
    )
    sub.status = SubmissionStatus.APPROVED.value
    await db_session.flush()

    # Generate voucher
    v1 = await payout_service.generate_payout_voucher(sub.id)

    # Calling again returns same voucher (idempotent, does not double-reserve)
    v2 = await payout_service.generate_payout_voucher(sub.id)
    assert v1.id == v2.id
    assert v1.nonce == v2.nonce

    escrow_after_gen = await ledger_service.get_escrow(campaign.id)
    assert escrow_after_gen.total_reserved == Decimal("5.00")
    assert escrow_after_gen.total_available == Decimal("20.00")

    # Revoke voucher (e.g. fraudulent activity detected post-approval)
    revoked = await payout_service.revoke_payout_voucher(
        payout_id=v1.id,
        reason="Discovered synthetic bot submission during audit",
    )
    assert revoked.status == PayoutStatus.REVOKED.value

    # Funds returned from reserved back to available!
    escrow_after_rev = await ledger_service.get_escrow(campaign.id)
    assert escrow_after_rev.total_reserved == Decimal("0.00")
    assert escrow_after_rev.total_available == Decimal("25.00")
    assert escrow_after_rev.check_invariant() is True


@pytest.mark.asyncio
async def test_payout_fails_without_verified_wallet_or_insufficient_funds(db_session):
    """Test domain rule enforcement when wallet is missing or escrow capacity is exhausted."""
    campaign_service = CampaignService(db_session)
    submission_service = SubmissionService(db_session)
    ledger_service = LedgerService(db_session)

    test_signer = Account.create()
    signer_provider = LocalSignerProvider(
        private_key=test_signer.key.hex(),
        contract_address="0x" + "4" * 40,
        chain_id=42220,
    )
    payout_service = PayoutSignerService(
        db=db_session,
        ledger_service=ledger_service,
        signer_provider=signer_provider,
    )

    creator = User(email="creator_walletless@datamint.ai")
    contributor = User(email="contrib_walletless@datamint.ai")
    db_session.add_all([creator, contributor])
    await db_session.flush()

    campaign = await campaign_service.create_campaign(
        creator_id=creator.id,
        data=CampaignCreate(
            title="Short Audio",
            description="Voice samples",
            data_type=DataType.VOICE,
            target_submissions=2,
            reward_per_submission=Decimal("10.00"),
        ),
    )
    campaign.escrow.total_funded = Decimal("10.00")
    campaign.escrow.total_available = Decimal("10.00")
    await campaign_service.activate_campaign(campaign.id, f"0x{secrets.token_hex(32)}")
    await db_session.flush()

    sub = await submission_service.create_draft(
        contributor_id=contributor.id,
        data=SubmissionDraftCreate(
            campaign_id=campaign.id,
            draft_data={"audio": "sample.wav"},
        ),
    )
    sub.status = SubmissionStatus.APPROVED.value
    await db_session.flush()

    # 1. Contributor has no linked wallet -> DomainRuleViolationException
    with pytest.raises(DomainRuleViolationException) as excinfo:
        await payout_service.generate_payout_voucher(sub.id)
    assert "verified wallet" in str(excinfo.value.detail).lower()

    # Link wallet
    contrib_wallet = Account.create()
    wallet = Wallet(
        user_id=contributor.id,
        address=contrib_wallet.address.lower(),
        chain_id=42220,
        is_primary=True,
    )
    db_session.add(wallet)
    await db_session.flush()

    # 2. First voucher consumes 10.00 available -> succeeds
    payout1 = await payout_service.generate_payout_voucher(sub.id)
    assert payout1.status == PayoutStatus.AUTHORIZED.value

    # 3. Create second approved submission when available capacity is now 0.00
    sub2 = await submission_service.create_draft(
        contributor_id=contributor.id,
        data=SubmissionDraftCreate(
            campaign_id=campaign.id,
            draft_data={"audio": "sample2.wav"},
        ),
    )
    sub2.status = SubmissionStatus.APPROVED.value
    await db_session.flush()

    from app.core.exceptions import InsufficientFundsException

    with pytest.raises(InsufficientFundsException):
        await payout_service.generate_payout_voucher(sub2.id)
