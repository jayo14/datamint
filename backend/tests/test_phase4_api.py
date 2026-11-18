"""Integration tests for Phase 4 REST API endpoints: reviews, appeals, vouchers, reconciliation, and notifications."""

from decimal import Decimal

import pytest
from eth_account import Account
from httpx import AsyncClient

from app.core.security import create_access_token
from app.models.enums import CapabilityType, DataType, SubmissionStatus
from app.models.identity import User, UserCapability
from app.models.wallet import Wallet
from app.schemas.campaign import CampaignCreate
from app.schemas.submission import SubmissionDraftCreate
from app.services.campaign_service import CampaignService
from app.services.ledger_service import LedgerService
from app.services.submission_service import SubmissionService


@pytest.mark.asyncio
async def test_review_and_appeals_api_flow(async_client: AsyncClient, db_session):
    """Test REST API endpoints for human review decisions and contributor appeals."""
    campaign_service = CampaignService(db_session)
    submission_service = SubmissionService(db_session)
    ledger_service = LedgerService(db_session)

    # 1. Create reviewer, creator, and contributor users with capabilities
    creator = User(email="creator_api@datamint.ai")
    contributor = User(email="contrib_api@datamint.ai")
    reviewer = User(email="reviewer_api@datamint.ai")
    db_session.add_all([creator, contributor, reviewer])
    await db_session.flush()

    db_session.add_all(
        [
            UserCapability(user_id=creator.id, capability_type=CapabilityType.CREATOR.value),
            UserCapability(
                user_id=contributor.id, capability_type=CapabilityType.CONTRIBUTOR.value
            ),
            UserCapability(user_id=reviewer.id, capability_type=CapabilityType.REVIEWER.value),
        ]
    )
    await db_session.flush()

    reviewer_token = create_access_token(
        str(reviewer.id), capabilities=[CapabilityType.REVIEWER.value]
    )
    contributor_token = create_access_token(
        str(contributor.id), capabilities=[CapabilityType.CONTRIBUTOR.value]
    )
    creator_token = create_access_token(
        str(creator.id), capabilities=[CapabilityType.CREATOR.value]
    )

    # 2. Setup campaign and submission needing review
    campaign = await campaign_service.create_campaign(
        creator_id=creator.id,
        data=CampaignCreate(
            title="API Evaluation Campaign",
            description="Testing REST review",
            data_type=DataType.TEXT,
            target_submissions=5,
            reward_per_submission=Decimal("2.00"),
        ),
    )
    await ledger_service.record_deposit(
        campaign_id=campaign.id,
        amount=Decimal("10.00"),
        reference_id=f"dep_api_{campaign.id}",
        onchain_campaign_id="0x" + "4" * 64,
    )
    await campaign_service.activate_campaign(campaign.id, "0x" + "4" * 64)
    await db_session.flush()

    sub = await submission_service.create_draft(
        contributor_id=contributor.id,
        data=SubmissionDraftCreate(
            campaign_id=campaign.id,
            draft_data={"text": "Ambiguous sample needing review"},
        ),
    )
    sub.status = SubmissionStatus.NEEDS_REVIEW.value
    await db_session.commit()

    # 3. GET /api/v1/reviews/queue
    resp_queue = await async_client.get(
        "/api/v1/reviews/queue",
        headers={"Authorization": f"Bearer {reviewer_token}"},
    )
    assert resp_queue.status_code == 200
    queue_data = resp_queue.json()
    assert queue_data["total"] >= 1
    assert any(item["submission_id"] == str(sub.id) for item in queue_data["items"])

    # 4. POST /api/v1/reviews/submissions/{id}/decide -> REJECTED
    resp_reject = await async_client.post(
        f"/api/v1/reviews/submissions/{sub.id}/decide",
        headers={"Authorization": f"Bearer {reviewer_token}"},
        json={
            "decision": "REJECTED",
            "notes": "Poor detail",
            "rejection_reason": "Lacks required technical terminology",
        },
    )
    assert resp_reject.status_code == 200
    assert resp_reject.json()["decision"] == "REJECTED"

    # 5. POST /api/v1/appeals/submissions/{id} -> Contributor appeals
    resp_appeal = await async_client.post(
        f"/api/v1/appeals/submissions/{sub.id}",
        headers={"Authorization": f"Bearer {contributor_token}"},
        json={
            "reason": "The terminology used adheres to ICD-11 international medical coding standards.",
            "evidence": {"standard": "ICD-11"},
        },
    )
    assert resp_appeal.status_code == 201
    appeal_data = resp_appeal.json()
    assert appeal_data["status"] == "PENDING"
    appeal_id = appeal_data["id"]

    # 6. POST /api/v1/appeals/{id}/resolve -> Reviewer overturns rejection to APPROVED
    resp_resolve = await async_client.post(
        f"/api/v1/appeals/{appeal_id}/resolve",
        headers={"Authorization": f"Bearer {reviewer_token}"},
        json={
            "decision": "APPROVED",
            "reviewer_notes": "Verified ICD-11 taxonomy. Overturning rejection.",
        },
    )
    assert resp_resolve.status_code == 200
    assert resp_resolve.json()["status"] == "OVERTURNED"

    # 7. Contributor links wallet and retrieves signed EIP-712 reward voucher
    wallet_acc = Account.create()
    wallet = Wallet(
        user_id=contributor.id,
        address=wallet_acc.address.lower(),
        chain_id=42220,
        is_primary=True,
    )
    db_session.add(wallet)
    await db_session.commit()

    resp_voucher = await async_client.get(
        f"/api/v1/payouts/submissions/{sub.id}/voucher",
        headers={"Authorization": f"Bearer {contributor_token}"},
    )
    assert resp_voucher.status_code == 200
    voucher_json = resp_voucher.json()
    assert voucher_json["status"] == "AUTHORIZED"
    assert voucher_json["signature"].startswith("0x")
    assert voucher_json["voucher"]["contributor"].lower() == wallet_acc.address.lower()

    # 8. GET /api/v1/reconciliation/campaigns/{id} -> Creator checks ledger health
    resp_recon = await async_client.get(
        f"/api/v1/reconciliation/campaigns/{campaign.id}",
        headers={"Authorization": f"Bearer {creator_token}"},
    )
    assert resp_recon.status_code == 200
    recon_data = resp_recon.json()
    assert recon_data["is_reconciled"] is True
    assert recon_data["invariant_holds"] is True
