"""Tests for human review queue, manual review decisions, and contributor appeals."""

import secrets
from datetime import datetime, timedelta, timezone
from decimal import Decimal

import pytest

from app.core.exceptions import (
    ConflictOfInterestException,
    DomainRuleViolationException,
)
from app.models.enums import (
    AppealStatus,
    DataType,
    ReviewDecision,
    ReviewType,
    SubmissionStatus,
)
from app.models.identity import User
from app.schemas.campaign import CampaignCreate
from app.schemas.review import (
    AppealCreateRequest,
    AppealResolveRequest,
    ReviewDecisionRequest,
)
from app.schemas.submission import SubmissionDraftCreate
from app.services.campaign_service import CampaignService
from app.services.review_service import ReviewService
from app.services.submission_service import SubmissionService


@pytest.mark.asyncio
async def test_review_queue_and_conflict_of_interest(db_session):
    """Test review queue filtering and self-review blocking."""
    campaign_service = CampaignService(db_session)
    submission_service = SubmissionService(db_session)
    review_service = ReviewService(db_session)

    creator = User(email="creator_rev@datamint.ai")
    contributor = User(email="contrib_rev@datamint.ai")
    reviewer = User(email="reviewer_rev@datamint.ai")
    db_session.add_all([creator, contributor, reviewer])
    await db_session.flush()

    campaign = await campaign_service.create_campaign(
        creator_id=creator.id,
        data=CampaignCreate(
            title="Image Labeling Task",
            description="Label objects in kitchen photos",
            data_type=DataType.IMAGE,
            target_submissions=10,
            reward_per_submission=Decimal("1.50"),
        ),
    )
    campaign.escrow.total_funded = Decimal("15.00")
    campaign.escrow.total_available = Decimal("15.00")
    await campaign_service.activate_campaign(campaign.id, f"0x{secrets.token_hex(32)}")
    await db_session.flush()

    sub = await submission_service.create_draft(
        contributor_id=contributor.id,
        data=SubmissionDraftCreate(
            campaign_id=campaign.id,
            draft_data={"labels": ["knife", "cutting board"]},
        ),
    )
    sub.status = SubmissionStatus.NEEDS_REVIEW.value
    await db_session.flush()

    # 1. Verify submission shows up in review queue
    items, total = await review_service.get_review_queue()
    assert total >= 1
    found = next((i for i in items if i.submission_id == sub.id), None)
    assert found is not None
    assert found.status == SubmissionStatus.NEEDS_REVIEW.value
    assert found.campaign_title == "Image Labeling Task"

    # 2. Conflict of interest: Contributor tries to review their own submission
    with pytest.raises(ConflictOfInterestException):
        await review_service.submit_review_decision(
            submission_id=sub.id,
            reviewer_id=contributor.id,
            request=ReviewDecisionRequest(
                decision=ReviewDecision.APPROVED,
                notes="Approving my own work!",
            ),
        )

    # 3. Third-party reviewer approves submission
    review = await review_service.submit_review_decision(
        submission_id=sub.id,
        reviewer_id=reviewer.id,
        request=ReviewDecisionRequest(
            decision=ReviewDecision.APPROVED,
            notes="Labels match kitchen items accurately.",
        ),
    )
    assert review.decision == ReviewDecision.APPROVED.value
    assert review.review_type == ReviewType.MANUAL_VALIDATION.value
    assert sub.status == SubmissionStatus.APPROVED.value


@pytest.mark.asyncio
async def test_rejection_and_appeals_workflow(db_session):
    """Test rejection, contributor appeal creation, prevention of duplicates, and overturn resolution."""
    campaign_service = CampaignService(db_session)
    submission_service = SubmissionService(db_session)
    review_service = ReviewService(db_session)

    creator = User(email="creator_app@datamint.ai")
    contributor = User(email="contrib_app@datamint.ai")
    reviewer1 = User(email="rev1_app@datamint.ai")
    reviewer2 = User(email="rev2_app@datamint.ai")
    db_session.add_all([creator, contributor, reviewer1, reviewer2])
    await db_session.flush()

    campaign = await campaign_service.create_campaign(
        creator_id=creator.id,
        data=CampaignCreate(
            title="Voice Commands",
            description="Record home commands",
            data_type=DataType.VOICE,
            target_submissions=5,
            reward_per_submission=Decimal("2.00"),
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
            draft_data={"command": "turn on lights"},
        ),
    )
    sub.status = SubmissionStatus.NEEDS_REVIEW.value
    await db_session.flush()

    # Reviewer 1 rejects submission
    rejection_review = await review_service.submit_review_decision(
        submission_id=sub.id,
        reviewer_id=reviewer1.id,
        request=ReviewDecisionRequest(
            decision=ReviewDecision.REJECTED,
            notes="Background noise too high",
            rejection_reason="Excessive background noise",
        ),
    )
    assert sub.status == SubmissionStatus.REJECTED.value
    assert rejection_review.rejection_reason == "Excessive background noise"

    # Non-author tries to appeal -> blocked
    with pytest.raises(ConflictOfInterestException):
        await review_service.submit_appeal(
            submission_id=sub.id,
            contributor_id=creator.id,
            request=AppealCreateRequest(reason="This was actually quiet in a studio setting."),
        )

    # Contributor appeals
    appeal = await review_service.submit_appeal(
        submission_id=sub.id,
        contributor_id=contributor.id,
        request=AppealCreateRequest(
            reason="This was recorded in an anechoic chamber. The perceived noise is a compressor artifact.",
            evidence={"spectrogram_url": "https://example.com/spec.png"},
        ),
    )
    assert appeal.status == AppealStatus.PENDING.value
    assert sub.status == SubmissionStatus.UNDER_APPEAL.value

    # Duplicate appeal while pending -> blocked
    with pytest.raises(DomainRuleViolationException):
        await review_service.submit_appeal(
            submission_id=sub.id,
            contributor_id=contributor.id,
            request=AppealCreateRequest(reason="Second appeal attempt should fail."),
        )

    # Contributor cannot resolve their own appeal
    with pytest.raises(ConflictOfInterestException):
        await review_service.resolve_appeal(
            appeal_id=appeal.id,
            reviewer_id=contributor.id,
            request=AppealResolveRequest(
                decision=ReviewDecision.APPROVED,
                reviewer_notes="Self-approval attempt",
            ),
        )

    # Reviewer 2 resolves appeal by overturning rejection
    resolved_appeal = await review_service.resolve_appeal(
        appeal_id=appeal.id,
        reviewer_id=reviewer2.id,
        request=AppealResolveRequest(
            decision=ReviewDecision.APPROVED,
            reviewer_notes="Verified acoustic recording conditions. Overturning rejection.",
        ),
    )
    assert resolved_appeal.status == AppealStatus.OVERTURNED.value
    assert resolved_appeal.reviewer_id == reviewer2.id
    assert resolved_appeal.resolved_at is not None
    assert sub.status == SubmissionStatus.APPROVED.value


@pytest.mark.asyncio
async def test_appeal_deadline_enforcement(db_session):
    """Verify that appeals submitted past the campaign window or deadline are rejected."""
    campaign_service = CampaignService(db_session)
    submission_service = SubmissionService(db_session)
    review_service = ReviewService(db_session)

    creator = User(email="creator_deadline@datamint.ai")
    contributor = User(email="contrib_deadline@datamint.ai")
    reviewer = User(email="reviewer_deadline@datamint.ai")
    db_session.add_all([creator, contributor, reviewer])
    await db_session.flush()

    campaign = await campaign_service.create_campaign(
        creator_id=creator.id,
        data=CampaignCreate(
            title="Time-Bound Campaign",
            description="Strict appeal window",
            data_type=DataType.TEXT,
            target_submissions=10,
            reward_per_submission=Decimal("2.00"),
            eligibility_criteria={"appeal_window_days": 3},
        ),
    )
    campaign.escrow.total_funded = Decimal("20.00")
    campaign.escrow.total_available = Decimal("20.00")
    await campaign_service.activate_campaign(campaign.id, f"0x{secrets.token_hex(32)}")
    await db_session.flush()

    sub = await submission_service.create_draft(
        contributor_id=contributor.id,
        data=SubmissionDraftCreate(
            campaign_id=campaign.id,
            draft_data={"text": "Initial text entry"},
        ),
    )
    sub.status = SubmissionStatus.NEEDS_REVIEW.value
    await db_session.flush()

    # Reject submission
    await review_service.submit_review_decision(
        submission_id=sub.id,
        reviewer_id=reviewer.id,
        request=ReviewDecisionRequest(
            decision=ReviewDecision.REJECTED,
            notes="Does not meet criteria",
            rejection_reason="Off-topic content",
        ),
    )

    # 1. Backdate rejection beyond the 3-day window
    sub.updated_at = datetime.now(timezone.utc) - timedelta(days=5)
    await db_session.flush()

    with pytest.raises(DomainRuleViolationException) as excinfo:
        await review_service.submit_appeal(
            submission_id=sub.id,
            contributor_id=contributor.id,
            request=AppealCreateRequest(reason="Trying to appeal late."),
        )
    assert "appeal deadline" in str(excinfo.value.detail).lower()

    # 2. Reset updated_at within 3-day window, but expire campaign deadline
    sub.updated_at = datetime.now(timezone.utc) - timedelta(hours=2)
    campaign.deadline = datetime.now(timezone.utc) - timedelta(hours=1)
    await db_session.flush()

    with pytest.raises(DomainRuleViolationException) as excinfo_camp:
        await review_service.submit_appeal(
            submission_id=sub.id,
            contributor_id=contributor.id,
            request=AppealCreateRequest(reason="Appeal after campaign closed."),
        )
    assert "campaign deadline has passed" in str(excinfo_camp.value.detail).lower()
