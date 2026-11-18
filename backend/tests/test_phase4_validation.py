"""Phase 4 unit and integration tests for Multi-Modal AI Validation and Policy Decision Engine."""

import secrets
from decimal import Decimal

import pytest

from app.models.enums import DataType, SubmissionStatus, ValidationOutcome
from app.models.identity import User
from app.schemas.campaign import CampaignCreate
from app.schemas.submission import SubmissionDraftCreate
from app.services.campaign_service import CampaignService
from app.services.submission_service import SubmissionService
from app.services.validation.base import FindingData, ProviderValidationResult
from app.services.validation.pipelines import (
    ImageValidationPipeline,
    TextValidationPipeline,
    VoiceValidationPipeline,
)
from app.services.validation.policy_engine import ValidationPolicyEngine
from app.services.validation.providers import MockAIValidationProvider
from app.services.validation.validation_service import ValidationService


@pytest.mark.asyncio
async def test_text_validation_pipeline_heuristics_and_duplicates():
    """Verify text pipeline deterministic checks, length boundaries, and duplicate detection."""
    provider = MockAIValidationProvider()
    pipeline = TextValidationPipeline(provider)

    # 1. Empty text -> BLOCKER
    score, findings, _ = await pipeline.execute("")
    assert score == Decimal("0.00")
    assert any(f.code == "EMPTY_TEXT_SUBMISSION" and f.severity == "BLOCKER" for f in findings)

    # 2. Text too short -> Underflow blocker
    score_short, findings_short, _ = await pipeline.execute("hi")
    assert any(f.code == "TEXT_LENGTH_UNDERFLOW" for f in findings_short)

    # 3. Duplicate detection
    existing_texts = {"this is already submitted text for the campaign."}
    score_dup, findings_dup, _ = await pipeline.execute(
        "This is already submitted text for the campaign.",
        existing_submission_texts=existing_texts,
    )
    assert score_dup == Decimal("0.00")
    assert any(
        f.code == "DUPLICATE_TEXT_DETECTED" and f.severity == "BLOCKER" for f in findings_dup
    )

    # 4. Valid compliant text
    score_valid, findings_valid, _ = await pipeline.execute(
        "Here is a detailed, high-quality human contribution describing local flora and weather conditions."
    )
    assert score_valid >= Decimal("0.85")
    assert not any(f.severity in ("CRITICAL", "BLOCKER") for f in findings_valid)


@pytest.mark.asyncio
async def test_voice_validation_pipeline_format_and_silence():
    """Verify audio magic byte validation, silence detection, and duplicate audio blocking."""
    provider = MockAIValidationProvider()
    pipeline = VoiceValidationPipeline(provider)

    # 1. Corrupt / empty audio
    score_empty, findings_empty, _ = await pipeline.execute(b"", mime_type="audio/wav")
    assert score_empty == Decimal("0.00")
    assert any(f.code == "CORRUPT_OR_EMPTY_AUDIO" for f in findings_empty)

    # 2. Invalid audio magic bytes (e.g. text passed as audio)
    score_bad, findings_bad, _ = await pipeline.execute(
        b"NOT_A_VALID_AUDIO_FILE_DATA_BYTES" * 3, mime_type="audio/wav"
    )
    assert score_bad == Decimal("0.00")
    assert any(f.code == "INVALID_AUDIO_FORMAT" for f in findings_bad)

    # 3. Silence / zero energy
    silent_wav = b"RIFF" + b"\x00" * 4 + b"WAVEfmt " + b"\x00" * 2000
    score_silence, findings_silence, _ = await pipeline.execute(silent_wav, mime_type="audio/wav")
    assert any(f.code == "AUDIO_SILENCE_DETECTED" for f in findings_silence)

    # 4. Valid audio sample
    valid_wav = b"RIFF" + b"\x00" * 4 + b"WAVEfmt " + b"\x11\x22\x33\x44" * 500
    score_valid, findings_valid, _ = await pipeline.execute(valid_wav, mime_type="audio/wav")
    assert score_valid >= Decimal("0.85")


@pytest.mark.asyncio
async def test_image_validation_pipeline_magic_bytes_and_duplicates():
    """Verify image magic bytes, blank image heuristic, and duplicate detection."""
    provider = MockAIValidationProvider()
    pipeline = ImageValidationPipeline(provider)

    # 1. Invalid image format
    score_bad, findings_bad, _ = await pipeline.execute(
        b"INVALID_IMAGE_HEADER_CONTENT_BYTES", mime_type="image/jpeg"
    )
    assert score_bad == Decimal("0.00")
    assert any(f.code == "INVALID_IMAGE_FORMAT" for f in findings_bad)

    # 2. Valid JPEG magic bytes
    valid_jpeg = b"\xff\xd8\xff\xe0\x00\x10JFIF" + bytes(range(256)) * 4
    score_valid, findings_valid, _ = await pipeline.execute(valid_jpeg, mime_type="image/jpeg")
    assert score_valid >= Decimal("0.85")
    assert not any(f.severity in ("CRITICAL", "BLOCKER") for f in findings_valid)


@pytest.mark.asyncio
async def test_policy_decision_engine_rules():
    """Verify policy decisions: auto-approval, rejection, borderline human review, and provider failure escalation."""
    engine = ValidationPolicyEngine(policy_version="1.0")

    # 1. High-confidence valid -> APPROVED
    outcome_ok, _ = engine.evaluate(
        confidence_score=Decimal("0.92"),
        findings=[FindingData(code="OK", severity="INFO", message="Good")],
    )
    assert outcome_ok == ValidationOutcome.APPROVED

    # 2. Hard blocker -> REJECTED
    outcome_block, _ = engine.evaluate(
        confidence_score=Decimal("0.95"),
        findings=[FindingData(code="DUPLICATE", severity="BLOCKER", message="Duplicate")],
    )
    assert outcome_block == ValidationOutcome.REJECTED

    # 3. Low-confidence -> REJECTED
    outcome_low, _ = engine.evaluate(
        confidence_score=Decimal("0.40"),
        findings=[
            FindingData(code="LOW_QUALITY", severity="CRITICAL", message="Very poor quality")
        ],
    )
    assert outcome_low == ValidationOutcome.REJECTED

    # 4. Ambiguous borderline score (0.75) -> HUMAN_REVIEW
    outcome_ambiguous, _ = engine.evaluate(
        confidence_score=Decimal("0.75"),
        findings=[
            FindingData(code="MILD_WARNING", severity="WARNING", message="Borderline accent")
        ],
    )
    assert outcome_ambiguous == ValidationOutcome.HUMAN_REVIEW

    # 5. AI Provider failure -> MUST enter HUMAN_REVIEW (never auto-approve!)
    failed_provider = ProviderValidationResult(
        confidence_score=Decimal("0.00"),
        failure_reason="Upstream provider connection timeout after 3 retries",
    )
    outcome_fail, rationale = engine.evaluate(
        confidence_score=Decimal("0.90"),
        findings=[],
        provider_result=failed_provider,
    )
    assert outcome_fail == ValidationOutcome.HUMAN_REVIEW
    assert "provider failed" in rationale.lower()


@pytest.mark.asyncio
async def test_full_validation_service_orchestration(db_session):
    """Verify end-to-end ValidationService flow with database persistence."""
    campaign_service = CampaignService(db_session)
    submission_service = SubmissionService(db_session)

    # Create creator & active text campaign
    creator = User(email="creator_val@datamint.ai")
    db_session.add(creator)
    await db_session.flush()

    campaign = await campaign_service.create_campaign(
        creator_id=creator.id,
        data=CampaignCreate(
            title="Medical Terminology Prompts",
            description="Collect definitions for rare medical abbreviations",
            data_type=DataType.TEXT,
            target_submissions=10,
            reward_per_submission=Decimal("2.00"),
        ),
    )
    campaign.escrow.total_funded = Decimal("20.00")
    campaign.escrow.total_available = Decimal("20.00")
    await campaign_service.activate_campaign(campaign.id, f"0x{secrets.token_hex(32)}")
    await db_session.flush()

    # Contributor creates submission
    contributor = User(email="contrib_val@datamint.ai")
    db_session.add(contributor)
    await db_session.flush()

    sub = await submission_service.create_draft(
        contributor_id=contributor.id,
        data=SubmissionDraftCreate(
            campaign_id=campaign.id,
            draft_data={
                "text": "Cardiomyopathy refers to a disease of the heart muscle that makes it harder for the heart to pump blood."
            },
        ),
    )
    sub.status = SubmissionStatus.PENDING_VALIDATION.value
    await db_session.flush()

    # Execute validation service
    val_service = ValidationService(db_session)
    updated_sub, run, outcome = await val_service.validate_submission(sub.id)

    assert outcome == ValidationOutcome.APPROVED
    assert updated_sub.status == SubmissionStatus.APPROVED.value
    assert run.score is not None and run.score >= Decimal("0.85")
    assert run.policy_version == "1.0"
    assert len(run.findings) > 0
    assert run.execution_duration_ms is not None
