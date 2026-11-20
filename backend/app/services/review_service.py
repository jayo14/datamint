"""Human review and appeals workflow management service."""

import uuid
from datetime import datetime, timedelta, timezone
from typing import List, Optional, Tuple

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.exceptions import (
    ConflictOfInterestException,
    DomainRuleViolationException,
    EntityNotFoundException,
    InvalidStateTransitionException,
)
from app.models.enums import AppealStatus, ReviewDecision, ReviewType, SubmissionStatus
from app.models.notification import Notification
from app.models.submission import Appeal, Review, Submission, ValidationRun
from app.schemas.review import (
    AppealCreateRequest,
    AppealResolveRequest,
    ReviewDecisionRequest,
    ReviewQueueItemResponse,
)


class ReviewService:
    """Service managing human review queues, manual reviewer evaluations, and contributor appeals."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_review_queue(
        self,
        page: int = 1,
        page_size: int = 20,
        status_filter: Optional[str] = None,
    ) -> Tuple[List[ReviewQueueItemResponse], int]:
        """Fetch paginated submissions waiting for human review or under appeal."""
        allowed_statuses = [
            SubmissionStatus.NEEDS_REVIEW.value,
            SubmissionStatus.UNDER_APPEAL.value,
        ]
        if status_filter and status_filter in allowed_statuses:
            status_clause = [status_filter]
        else:
            status_clause = allowed_statuses

        # Count total
        count_query = select(func.count(Submission.id)).where(Submission.status.in_(status_clause))
        total = (await self.db.execute(count_query)).scalar_one()

        # Query items
        offset = (page - 1) * page_size
        items_query = (
            select(Submission)
            .where(Submission.status.in_(status_clause))
            .options(
                selectinload(Submission.campaign),
                selectinload(Submission.validation_runs).selectinload(ValidationRun.findings),
            )
            .order_by(Submission.created_at.asc())
            .offset(offset)
            .limit(page_size)
        )
        submissions = (await self.db.execute(items_query)).scalars().all()

        results: List[ReviewQueueItemResponse] = []
        for sub in submissions:
            latest_run = sub.validation_runs[-1] if sub.validation_runs else None
            findings_count = len(latest_run.findings) if latest_run and latest_run.findings else 0
            results.append(
                ReviewQueueItemResponse(
                    submission_id=sub.id,
                    campaign_id=sub.campaign_id,
                    campaign_title=sub.campaign.title if sub.campaign else "Unknown Campaign",
                    data_type=sub.campaign.data_type if sub.campaign else "UNKNOWN",
                    contributor_id=sub.contributor_id,
                    status=sub.status,
                    created_at=sub.created_at,
                    latest_score=latest_run.score if latest_run else None,
                    validation_runs_count=len(sub.validation_runs),
                    findings_count=findings_count,
                )
            )

        return results, total

    async def get_submission_review_details(self, submission_id: uuid.UUID) -> Submission:
        """Retrieve full submission graph needed for reviewer evaluation."""
        query = (
            select(Submission)
            .where(Submission.id == submission_id)
            .options(
                selectinload(Submission.campaign),
                selectinload(Submission.contributor),
                selectinload(Submission.assets),
                selectinload(Submission.validation_runs).selectinload(ValidationRun.findings),
                selectinload(Submission.reviews),
                selectinload(Submission.appeals),
            )
        )
        submission = (await self.db.execute(query)).scalar_one_or_none()
        if not submission:
            raise EntityNotFoundException("Submission", submission_id)
        return submission

    async def submit_review_decision(
        self,
        submission_id: uuid.UUID,
        reviewer_id: uuid.UUID,
        request: ReviewDecisionRequest,
    ) -> Review:
        """Submit a reviewer evaluation on a submission pending review."""
        query = (
            select(Submission)
            .where(Submission.id == submission_id)
            .options(selectinload(Submission.campaign))
        )
        submission = (await self.db.execute(query)).scalar_one_or_none()
        if not submission:
            raise EntityNotFoundException("Submission", submission_id)

        # Conflict of interest check: Contributor cannot review their own submission
        if submission.contributor_id == reviewer_id:
            raise ConflictOfInterestException("Reviewers cannot evaluate their own submissions.")

        if submission.status not in [
            SubmissionStatus.NEEDS_REVIEW.value,
            SubmissionStatus.UNDER_APPEAL.value,
        ]:
            raise InvalidStateTransitionException(
                current_state=submission.status,
                attempted_state=request.decision.value,
            )

        # Record review
        review = Review(
            submission_id=submission.id,
            reviewer_id=reviewer_id,
            review_type=ReviewType.MANUAL_VALIDATION.value,
            decision=request.decision.value,
            notes=request.notes,
            rejection_reason=request.rejection_reason
            if request.decision == ReviewDecision.REJECTED
            else None,
        )
        self.db.add(review)

        # Update submission status
        if request.decision == ReviewDecision.APPROVED:
            submission.status = SubmissionStatus.APPROVED.value
            event_type = "SUBMISSION_APPROVED"
        else:
            submission.status = SubmissionStatus.REJECTED.value
            event_type = "SUBMISSION_REJECTED"

        # Emit in-app notification to contributor
        campaign_title = submission.campaign.title if submission.campaign else "campaign"
        notif = Notification(
            user_id=submission.contributor_id,
            event_type=event_type,
            title=f"Submission {request.decision.value}",
            message=f"Your submission for {campaign_title} has been evaluated by a reviewer: {request.decision.value}.",
            data_json={
                "submission_id": str(submission.id),
                "decision": request.decision.value,
                "notes": request.notes,
                "rejection_reason": request.rejection_reason,
            },
        )
        self.db.add(notif)

        await self.db.flush()
        return review

    async def submit_appeal(
        self,
        submission_id: uuid.UUID,
        contributor_id: uuid.UUID,
        request: AppealCreateRequest,
    ) -> Appeal:
        """Allow contributor to appeal an unfair or inaccurate rejection."""
        query = (
            select(Submission)
            .where(Submission.id == submission_id)
            .options(selectinload(Submission.campaign))
        )
        submission = (await self.db.execute(query)).scalar_one_or_none()
        if not submission:
            raise EntityNotFoundException("Submission", submission_id)

        # Verify contributor identity
        if submission.contributor_id != contributor_id:
            raise ConflictOfInterestException("Only the submission author can submit an appeal.")

        # Can only appeal rejected submissions
        if submission.status != SubmissionStatus.REJECTED.value:
            raise DomainRuleViolationException(
                f"Cannot appeal a submission with status '{submission.status}'. Only REJECTED submissions can be appealed."
            )

        # Enforce campaign-specific appeal deadlines
        campaign = submission.campaign
        if campaign:
            now_utc = datetime.now(timezone.utc)
            if campaign.deadline:
                camp_deadline = campaign.deadline
                if camp_deadline.tzinfo is None:
                    camp_deadline = camp_deadline.replace(tzinfo=timezone.utc)
                if now_utc > camp_deadline:
                    raise DomainRuleViolationException(
                        "The campaign deadline has passed; appeals are no longer accepted."
                    )

            criteria = campaign.eligibility_criteria or {}
            appeal_window_days = int(criteria.get("appeal_window_days", 7))
            ref_time = submission.updated_at or submission.created_at
            if ref_time:
                if ref_time.tzinfo is None:
                    ref_time = ref_time.replace(tzinfo=timezone.utc)
                cutoff = ref_time + timedelta(days=appeal_window_days)
                if now_utc > cutoff:
                    raise DomainRuleViolationException(
                        f"The appeal deadline of {appeal_window_days} days for this rejection has passed."
                    )

        # Prevent duplicate pending appeals
        existing_appeal_query = select(Appeal).where(
            Appeal.submission_id == submission_id,
            Appeal.status == AppealStatus.PENDING.value,
        )
        existing_appeal = (await self.db.execute(existing_appeal_query)).scalar_one_or_none()
        if existing_appeal:
            raise DomainRuleViolationException(
                "An active appeal is already pending for this submission."
            )

        appeal = Appeal(
            submission_id=submission_id,
            contributor_id=contributor_id,
            reason=request.reason,
            evidence=request.evidence,
            status=AppealStatus.PENDING.value,
        )
        self.db.add(appeal)

        submission.status = SubmissionStatus.UNDER_APPEAL.value

        # Queue notification for appeal submission
        notif = Notification(
            user_id=contributor_id,
            event_type="APPEAL_SUBMITTED",
            title="Appeal Submitted",
            message=f"Your appeal for submission {submission.id} has been received and queued for review.",
            data_json={
                "submission_id": str(submission.id),
                "reason": request.reason,
            },
        )
        self.db.add(notif)

        await self.db.flush()
        return appeal

    async def resolve_appeal(
        self,
        appeal_id: uuid.UUID,
        reviewer_id: uuid.UUID,
        request: AppealResolveRequest,
    ) -> Appeal:
        """Resolve a contributor appeal by upholding or overturning the rejection."""
        query = (
            select(Appeal)
            .where(Appeal.id == appeal_id)
            .options(selectinload(Appeal.submission).selectinload(Submission.campaign))
        )
        appeal = (await self.db.execute(query)).scalar_one_or_none()
        if not appeal:
            raise EntityNotFoundException("Appeal", appeal_id)

        # Conflict of interest check: Contributor cannot resolve their own appeal
        if appeal.contributor_id == reviewer_id:
            raise ConflictOfInterestException(
                "Reviewers cannot resolve appeals on their own submissions."
            )

        if appeal.status != AppealStatus.PENDING.value:
            raise DomainRuleViolationException(
                f"Appeal is already resolved with status '{appeal.status}'."
            )

        submission = appeal.submission

        # Resolve appeal
        if request.decision == ReviewDecision.APPROVED:
            # Overturn rejection -> submission becomes APPROVED
            appeal.status = AppealStatus.OVERTURNED.value
            submission.status = SubmissionStatus.APPROVED.value
        else:
            # Uphold rejection -> submission remains REJECTED
            appeal.status = AppealStatus.UPHELD.value
            submission.status = SubmissionStatus.REJECTED.value

        appeal.reviewer_id = reviewer_id
        appeal.reviewer_notes = request.reviewer_notes
        appeal.resolved_at = datetime.now(timezone.utc)

        # Also log a formal Review record for the appeal decision
        review = Review(
            submission_id=submission.id,
            reviewer_id=reviewer_id,
            review_type=ReviewType.APPEAL.value,
            decision=request.decision.value,
            notes=request.reviewer_notes,
            rejection_reason=request.reviewer_notes
            if request.decision == ReviewDecision.REJECTED
            else None,
        )
        self.db.add(review)

        # Emit in-app notification to contributor
        notif = Notification(
            user_id=appeal.contributor_id,
            event_type="APPEAL_RESOLVED",
            title=f"Appeal {appeal.status}",
            message=f"Your appeal for submission {submission.id} has been resolved: {appeal.status}.",
            data_json={
                "submission_id": str(submission.id),
                "appeal_id": str(appeal.id),
                "status": appeal.status,
                "notes": request.reviewer_notes,
            },
        )
        self.db.add(notif)

        await self.db.flush()
        return appeal
