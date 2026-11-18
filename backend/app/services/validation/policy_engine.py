"""Validation policy and decision engine converting findings into business outcomes."""

from decimal import Decimal
from typing import Any, Dict, List, Optional, Tuple

from app.models.enums import ValidationOutcome
from app.services.validation.base import FindingData, ProviderValidationResult


class ValidationPolicyEngine:
    """
    Decides whether a submission is APPROVED, REJECTED, or requires HUMAN_REVIEW
    based on confidence scores, finding severities, campaign-specific rules, and policy version.
    """

    DEFAULT_POLICY_VERSION = "1.0"
    DEFAULT_APPROVAL_THRESHOLD = Decimal("0.85")
    DEFAULT_REJECTION_THRESHOLD = Decimal("0.60")

    def __init__(self, policy_version: str = DEFAULT_POLICY_VERSION):
        self.policy_version = policy_version

    def evaluate(
        self,
        confidence_score: Decimal,
        findings: List[FindingData],
        provider_result: Optional[ProviderValidationResult] = None,
        campaign_rules: Optional[Dict[str, Any]] = None,
    ) -> Tuple[ValidationOutcome, str]:
        """
        Evaluate validation findings and return (ValidationOutcome, rationale).
        """
        rules = campaign_rules or {}
        approval_threshold = Decimal(
            str(rules.get("approval_threshold", self.DEFAULT_APPROVAL_THRESHOLD))
        )
        rejection_threshold = Decimal(
            str(rules.get("rejection_threshold", self.DEFAULT_REJECTION_THRESHOLD))
        )
        force_human_review = bool(rules.get("force_human_review", False))

        # Rule 1: AI Provider failure must NEVER automatically approve -> HUMAN_REVIEW
        if provider_result and provider_result.failure_reason:
            return (
                ValidationOutcome.HUMAN_REVIEW,
                f"AI provider failed during execution ({provider_result.failure_reason}); escalated for human inspection",
            )

        # Rule 2: Hard BLOCKER findings directly result in REJECTED
        blockers = [f for f in findings if f.severity == "BLOCKER"]
        if blockers:
            reasons = "; ".join(b.message for b in blockers)
            return (
                ValidationOutcome.REJECTED,
                f"Submission failed hard deterministic checks: {reasons}",
            )

        # Rule 3: Campaign explicitly mandates human review for all submissions
        if force_human_review:
            return (
                ValidationOutcome.HUMAN_REVIEW,
                "Campaign policy requires manual review for all contributions",
            )

        # Rule 4: Critical severity findings
        criticals = [f for f in findings if f.severity == "CRITICAL"]
        if criticals:
            if confidence_score < rejection_threshold:
                reasons = "; ".join(c.message for c in criticals)
                return (
                    ValidationOutcome.REJECTED,
                    f"Submission rejected due to critical quality defects: {reasons}",
                )
            else:
                return (
                    ValidationOutcome.HUMAN_REVIEW,
                    "Critical quality findings detected with moderate confidence; routed for human review",
                )

        # Rule 5: High-confidence approval
        if confidence_score >= approval_threshold:
            # Check if there are any unresolved warnings on mandatory criteria
            warnings = [f for f in findings if f.severity == "WARNING"]
            if warnings and rules.get("strict_mode", False):
                return (
                    ValidationOutcome.HUMAN_REVIEW,
                    f"High confidence ({confidence_score}) but warnings present in strict mode: routed to reviewer",
                )
            return (
                ValidationOutcome.APPROVED,
                f"High-confidence validation passed (confidence: {confidence_score:.2f}) with zero critical defects",
            )

        # Rule 6: Low-confidence rejection
        if confidence_score < rejection_threshold:
            return (
                ValidationOutcome.REJECTED,
                f"Confidence score {confidence_score:.2f} is below minimum acceptable threshold {rejection_threshold:.2f}",
            )

        # Rule 7: Ambiguous / borderline zone (rejection_threshold <= score < approval_threshold)
        return (
            ValidationOutcome.HUMAN_REVIEW,
            f"Borderline confidence score ({confidence_score:.2f}); manual human review required to resolve ambiguity",
        )
