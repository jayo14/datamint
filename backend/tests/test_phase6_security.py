"""Security tests for Phase 6: IDOR protection, object-level authorization, and conflict-of-interest prevention."""

from decimal import Decimal

import pytest
from httpx import AsyncClient

from app.core.security import create_access_token
from app.models.enums import CapabilityType, DataType, SubmissionStatus
from app.models.identity import User, UserCapability
from app.schemas.campaign import CampaignCreate
from app.schemas.submission import SubmissionDraftCreate
from app.services.campaign_service import CampaignService
from app.services.submission_service import SubmissionService


@pytest.mark.asyncio
async def test_submission_idor_protection(async_client: AsyncClient, db_session):
    """Test that GET /api/v1/submissions/{id} enforces authentication and object-level authorization."""
    campaign_service = CampaignService(db_session)
    submission_service = SubmissionService(db_session)

    # 1. Create creator, contributor A, contributor B, and reviewer
    creator = User(email="creator_sec@datamint.ai")
    contributor_a = User(email="contrib_a_sec@datamint.ai")
    contributor_b = User(email="contrib_b_sec@datamint.ai")
    reviewer = User(email="reviewer_sec@datamint.ai")
    db_session.add_all([creator, contributor_a, contributor_b, reviewer])
    await db_session.flush()

    db_session.add_all(
        [
            UserCapability(user_id=creator.id, capability_type=CapabilityType.CREATOR.value),
            UserCapability(
                user_id=contributor_a.id, capability_type=CapabilityType.CONTRIBUTOR.value
            ),
            UserCapability(
                user_id=contributor_b.id, capability_type=CapabilityType.CONTRIBUTOR.value
            ),
            UserCapability(user_id=reviewer.id, capability_type=CapabilityType.REVIEWER.value),
        ]
    )
    await db_session.commit()

    token_a = create_access_token(
        str(contributor_a.id), capabilities=[CapabilityType.CONTRIBUTOR.value]
    )
    token_b = create_access_token(
        str(contributor_b.id), capabilities=[CapabilityType.CONTRIBUTOR.value]
    )
    token_creator = create_access_token(
        str(creator.id), capabilities=[CapabilityType.CREATOR.value]
    )
    token_reviewer = create_access_token(
        str(reviewer.id), capabilities=[CapabilityType.REVIEWER.value]
    )

    # 2. Creator creates campaign
    campaign = await campaign_service.create_campaign(
        creator_id=creator.id,
        data=CampaignCreate(
            title="Security Audit Campaign",
            description="Testing authorization invariants",
            instructions="Provide valid data",
            data_type=DataType.TEXT,
            reward_per_submission=Decimal("1.5"),
            target_submissions=10,
        ),
    )
    campaign.status = "ACTIVE"
    await db_session.commit()

    # 3. Contributor A creates a submission draft
    submission = await submission_service.create_draft(
        contributor_id=contributor_a.id,
        data=SubmissionDraftCreate(
            campaign_id=campaign.id,
            content_payload={"text": "Sensitive contributor A confidential research"},
        ),
    )
    await db_session.commit()
    sub_id = str(submission.id)

    # A. Unauthenticated access must return 401 Unauthorized
    resp_unauth = await async_client.get(f"/api/v1/submissions/{sub_id}")
    assert resp_unauth.status_code == 401

    # B. Unauthorized third-party (Contributor B) must return 403 Forbidden (IDOR prevented)
    resp_idor = await async_client.get(
        f"/api/v1/submissions/{sub_id}",
        headers={"Authorization": f"Bearer {token_b}"},
    )
    assert resp_idor.status_code == 403
    assert "Access forbidden" in resp_idor.json()["detail"]

    # C. Legitimate author (Contributor A) must succeed (200 OK)
    resp_author = await async_client.get(
        f"/api/v1/submissions/{sub_id}",
        headers={"Authorization": f"Bearer {token_a}"},
    )
    assert resp_author.status_code == 200
    assert resp_author.json()["id"] == sub_id

    # D. Campaign Creator must succeed (200 OK)
    resp_creator = await async_client.get(
        f"/api/v1/submissions/{sub_id}",
        headers={"Authorization": f"Bearer {token_creator}"},
    )
    assert resp_creator.status_code == 200
    assert resp_creator.json()["id"] == sub_id

    # E. Reviewer must succeed (200 OK)
    resp_reviewer = await async_client.get(
        f"/api/v1/submissions/{sub_id}",
        headers={"Authorization": f"Bearer {token_reviewer}"},
    )
    assert resp_reviewer.status_code == 200
    assert resp_reviewer.json()["id"] == sub_id


@pytest.mark.asyncio
async def test_reviewer_self_approval_conflict_of_interest(async_client: AsyncClient, db_session):
    """Test that a reviewer who is also the contributor cannot approve their own submission."""
    campaign_service = CampaignService(db_session)
    submission_service = SubmissionService(db_session)

    # User with both CONTRIBUTOR and REVIEWER capabilities
    hybrid_user = User(email="hybrid_user@datamint.ai")
    creator = User(email="campaign_creator_coi@datamint.ai")
    db_session.add_all([hybrid_user, creator])
    await db_session.flush()

    db_session.add_all(
        [
            UserCapability(user_id=creator.id, capability_type=CapabilityType.CREATOR.value),
            UserCapability(
                user_id=hybrid_user.id, capability_type=CapabilityType.CONTRIBUTOR.value
            ),
            UserCapability(user_id=hybrid_user.id, capability_type=CapabilityType.REVIEWER.value),
        ]
    )
    await db_session.commit()

    token_hybrid = create_access_token(
        str(hybrid_user.id),
        capabilities=[CapabilityType.CONTRIBUTOR.value, CapabilityType.REVIEWER.value],
    )

    campaign = await campaign_service.create_campaign(
        creator_id=creator.id,
        data=CampaignCreate(
            title="COI Test Campaign",
            description="Testing conflict of interest prevention",
            instructions="No self-review allowed",
            data_type=DataType.TEXT,
            reward_per_submission=Decimal("2.0"),
            target_submissions=5,
        ),
    )
    campaign.status = "ACTIVE"
    await db_session.commit()

    submission = await submission_service.create_draft(
        contributor_id=hybrid_user.id,
        data=SubmissionDraftCreate(
            campaign_id=campaign.id,
            content_payload={"text": "Self-review attempt"},
        ),
    )
    submission.status = SubmissionStatus.NEEDS_REVIEW.value
    await db_session.commit()

    # Hybrid user attempts to evaluate and approve their own submission
    resp_decide = await async_client.post(
        f"/api/v1/reviews/submissions/{submission.id}/decide",
        headers={"Authorization": f"Bearer {token_hybrid}"},
        json={
            "decision": "APPROVED",
            "notes": "Self approval attempt should be rejected",
        },
    )
    assert resp_decide.status_code == 403
    assert "cannot evaluate their own submissions" in resp_decide.json()["detail"].lower()


@pytest.mark.asyncio
async def test_security_headers_and_correlation_id(async_client: AsyncClient):
    """Verify presence of OWASP security headers and X-Request-ID propagation."""
    custom_request_id = "test-corr-id-12345"
    resp = await async_client.get(
        "/api/v1/health/healthz", headers={"X-Request-ID": custom_request_id}
    )
    assert resp.status_code == 200
    assert resp.headers.get("X-Request-ID") == custom_request_id
    assert resp.headers.get("X-Content-Type-Options") == "nosniff"
    assert resp.headers.get("X-Frame-Options") == "DENY"
    csp = resp.headers.get("Content-Security-Policy", "")
    assert "default-src 'self'" in csp
    assert "object-src 'none'" in csp
    assert "base-uri 'self'" in csp
    assert "frame-ancestors 'none'" in csp
    assert "form-action 'self'" in csp
    assert resp.headers.get("Referrer-Policy") == "strict-origin-when-cross-origin"


def test_production_config_validation():
    """Verify that Settings rejects insecure default secrets when ENVIRONMENT is production."""
    import pytest

    from app.core.config import Settings

    # Should raise error when ENVIRONMENT is production and default JWT secret is used
    with pytest.raises(ValueError, match="JWT_SECRET_KEY"):
        Settings(
            ENVIRONMENT="production",
            JWT_SECRET_KEY="dev-secret-key-change-in-production-datamint-celo-ai",
            PLATFORM_SIGNER_PRIVATE_KEY="0x" + "a" * 64,
            ESCROW_CONTRACT_ADDRESS="0x1234567890123456789012345678901234567890",
        )

    # Should raise error when PLATFORM_SIGNER_PRIVATE_KEY is default 0x01
    with pytest.raises(ValueError, match="PLATFORM_SIGNER_PRIVATE_KEY"):
        Settings(
            ENVIRONMENT="production",
            JWT_SECRET_KEY="a" * 32,
            PLATFORM_SIGNER_PRIVATE_KEY="0x0000000000000000000000000000000000000000000000000000000000000001",
            ESCROW_CONTRACT_ADDRESS="0x1234567890123456789012345678901234567890",
        )
