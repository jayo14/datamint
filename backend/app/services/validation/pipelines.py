"""Modality-specific validation pipelines (Text, Voice, Image)."""

import hashlib
from decimal import Decimal
from typing import Any, Dict, List, Optional, Set, Tuple

from app.services.validation.base import AIValidationProvider, FindingData, ProviderValidationResult


class TextValidationPipeline:
    """Pipeline for text dataset submissions combining deterministic heuristics and AI validation."""

    def __init__(self, provider: AIValidationProvider):
        self.provider = provider

    async def execute(
        self,
        text_content: str,
        instructions: Optional[str] = None,
        criteria: Optional[Dict[str, Any]] = None,
        existing_submission_texts: Optional[Set[str]] = None,
    ) -> Tuple[Decimal, List[FindingData], ProviderValidationResult]:
        deterministic_findings: List[FindingData] = []
        clean = text_content.strip()

        # 1. Deterministic check: Empty / whitespace
        if not clean:
            deterministic_findings.append(
                FindingData(
                    code="EMPTY_TEXT_SUBMISSION",
                    severity="BLOCKER",
                    message="Submission text is completely empty or whitespace only",
                    is_deterministic=True,
                )
            )

        # 2. Deterministic check: Character and word bounds
        min_chars = (criteria or {}).get("min_chars", 10)
        max_chars = (criteria or {}).get("max_chars", 10000)
        if len(clean) < min_chars:
            deterministic_findings.append(
                FindingData(
                    code="TEXT_LENGTH_UNDERFLOW",
                    severity="BLOCKER",
                    message=f"Text length {len(clean)} characters is less than required minimum {min_chars}",
                    is_deterministic=True,
                    evidence=f"Length: {len(clean)}",
                )
            )
        elif len(clean) > max_chars:
            deterministic_findings.append(
                FindingData(
                    code="TEXT_LENGTH_OVERFLOW",
                    severity="WARNING",
                    message=f"Text length {len(clean)} characters exceeds recommended maximum {max_chars}",
                    is_deterministic=True,
                    evidence=f"Length: {len(clean)}",
                )
            )

        # 3. Deterministic check: Duplicate text detection
        if existing_submission_texts:
            text_hash = hashlib.sha256(clean.lower().encode()).hexdigest()
            if text_hash in existing_submission_texts or clean.lower() in existing_submission_texts:
                deterministic_findings.append(
                    FindingData(
                        code="DUPLICATE_TEXT_DETECTED",
                        severity="BLOCKER",
                        message="Identical text content has already been submitted to this campaign",
                        is_deterministic=True,
                        evidence=f"Digest: {text_hash[:16]}...",
                    )
                )

        # If hard blockers found, return low score immediately
        if any(f.severity == "BLOCKER" for f in deterministic_findings):
            return (
                Decimal("0.00"),
                deterministic_findings,
                ProviderValidationResult(
                    confidence_score=Decimal("0.00"),
                    findings=deterministic_findings,
                    provider="deterministic",
                    model_version="pipeline-v1",
                ),
            )

        # 4. Invoke AI provider for semantic / instruction compliance
        ai_res = await self.provider.validate_text(
            clean, instructions=instructions, criteria=criteria
        )
        combined_findings = deterministic_findings + ai_res.findings

        # Calculate final combined score
        score = ai_res.confidence_score
        if any(f.severity in ("CRITICAL", "BLOCKER") for f in combined_findings):
            score = min(score, Decimal("0.30"))
        elif any(f.severity == "WARNING" for f in combined_findings):
            score = min(score, Decimal("0.75"))

        return score, combined_findings, ai_res


class VoiceValidationPipeline:
    """Pipeline for audio/voice dataset submissions."""

    def __init__(self, provider: AIValidationProvider):
        self.provider = provider

    async def execute(
        self,
        audio_bytes: bytes,
        mime_type: str,
        instructions: Optional[str] = None,
        criteria: Optional[Dict[str, Any]] = None,
        existing_audio_checksums: Optional[Set[str]] = None,
    ) -> Tuple[Decimal, List[FindingData], ProviderValidationResult]:
        deterministic_findings: List[FindingData] = []

        # 1. Deterministic check: Payload presence
        if not audio_bytes or len(audio_bytes) < 64:
            deterministic_findings.append(
                FindingData(
                    code="CORRUPT_OR_EMPTY_AUDIO",
                    severity="BLOCKER",
                    message="Audio file is empty or corrupted (under 64 bytes)",
                    is_deterministic=True,
                )
            )

        # 2. Deterministic check: Audio magic numbers / decodability
        is_valid_format = False
        if audio_bytes.startswith(b"RIFF") and b"WAVE" in audio_bytes[:16]:
            is_valid_format = True
        elif audio_bytes.startswith(b"ID3") or audio_bytes[:2] in (
            b"\xff\xfb",
            b"\xff\xf3",
            b"\xff\xf2",
        ):
            is_valid_format = True  # MP3
        elif audio_bytes.startswith(b"OggS"):
            is_valid_format = True  # OGG
        elif audio_bytes.startswith(b"\x1aE\xdf\xa3"):
            is_valid_format = True  # WebM / Matroska
        elif len(audio_bytes) >= 8 and audio_bytes[4:8] in (b"ftyp", b"moov"):
            is_valid_format = True  # M4A / MP4

        if not is_valid_format and len(audio_bytes) >= 64:
            deterministic_findings.append(
                FindingData(
                    code="INVALID_AUDIO_FORMAT",
                    severity="BLOCKER",
                    message=f"File binary header does not match expected audio signature for MIME '{mime_type}'",
                    is_deterministic=True,
                    evidence=f"Header: {audio_bytes[:8].hex()}",
                )
            )

        # 3. Deterministic check: Duplicate audio detection
        checksum = hashlib.sha256(audio_bytes).hexdigest()
        if existing_audio_checksums and checksum in existing_audio_checksums:
            deterministic_findings.append(
                FindingData(
                    code="DUPLICATE_AUDIO_DETECTED",
                    severity="BLOCKER",
                    message="Identical audio recording has already been submitted to this campaign",
                    is_deterministic=True,
                    evidence=f"SHA-256: {checksum[:16]}...",
                )
            )

        if any(f.severity == "BLOCKER" for f in deterministic_findings):
            return (
                Decimal("0.00"),
                deterministic_findings,
                ProviderValidationResult(
                    confidence_score=Decimal("0.00"),
                    findings=deterministic_findings,
                    provider="deterministic",
                    model_version="pipeline-v1",
                ),
            )

        # 4. Invoke AI provider for acoustic & voice evaluations
        ai_res = await self.provider.validate_voice(audio_bytes, mime_type, instructions, criteria)
        combined_findings = deterministic_findings + ai_res.findings

        score = ai_res.confidence_score
        if any(f.severity in ("CRITICAL", "BLOCKER") for f in combined_findings):
            score = min(score, Decimal("0.25"))
        elif any(f.severity == "WARNING" for f in combined_findings):
            score = min(score, Decimal("0.70"))

        return score, combined_findings, ai_res


class ImageValidationPipeline:
    """Pipeline for image dataset submissions."""

    def __init__(self, provider: AIValidationProvider):
        self.provider = provider

    async def execute(
        self,
        image_bytes: bytes,
        mime_type: str,
        instructions: Optional[str] = None,
        criteria: Optional[Dict[str, Any]] = None,
        existing_image_checksums: Optional[Set[str]] = None,
    ) -> Tuple[Decimal, List[FindingData], ProviderValidationResult]:
        deterministic_findings: List[FindingData] = []

        # 1. Deterministic check: Payload presence
        if not image_bytes or len(image_bytes) < 32:
            deterministic_findings.append(
                FindingData(
                    code="CORRUPT_OR_EMPTY_IMAGE",
                    severity="BLOCKER",
                    message="Image file is empty or corrupted (under 32 bytes)",
                    is_deterministic=True,
                )
            )

        # 2. Deterministic check: Image magic numbers
        is_valid_format = False
        if image_bytes.startswith(b"\xff\xd8\xff"):
            is_valid_format = True  # JPEG
        elif image_bytes.startswith(b"\x89PNG\r\n\x1a\n"):
            is_valid_format = True  # PNG
        elif image_bytes.startswith(b"RIFF") and b"WEBP" in image_bytes[:16]:
            is_valid_format = True  # WebP

        if not is_valid_format and len(image_bytes) >= 32:
            deterministic_findings.append(
                FindingData(
                    code="INVALID_IMAGE_FORMAT",
                    severity="BLOCKER",
                    message=f"File binary header does not match expected image magic bytes for MIME '{mime_type}'",
                    is_deterministic=True,
                    evidence=f"Header: {image_bytes[:8].hex()}",
                )
            )

        # 3. Deterministic check: Duplicate image detection
        checksum = hashlib.sha256(image_bytes).hexdigest()
        if existing_image_checksums and checksum in existing_image_checksums:
            deterministic_findings.append(
                FindingData(
                    code="DUPLICATE_IMAGE_DETECTED",
                    severity="BLOCKER",
                    message="Identical image has already been submitted to this campaign",
                    is_deterministic=True,
                    evidence=f"SHA-256: {checksum[:16]}...",
                )
            )

        if any(f.severity == "BLOCKER" for f in deterministic_findings):
            return (
                Decimal("0.00"),
                deterministic_findings,
                ProviderValidationResult(
                    confidence_score=Decimal("0.00"),
                    findings=deterministic_findings,
                    provider="deterministic",
                    model_version="pipeline-v1",
                ),
            )

        # 4. Invoke AI provider for visual clarity and relevance
        ai_res = await self.provider.validate_image(image_bytes, mime_type, instructions, criteria)
        combined_findings = deterministic_findings + ai_res.findings

        score = ai_res.confidence_score
        if any(f.severity in ("CRITICAL", "BLOCKER") for f in combined_findings):
            score = min(score, Decimal("0.20"))
        elif any(f.severity == "WARNING" for f in combined_findings):
            score = min(score, Decimal("0.70"))

        return score, combined_findings, ai_res
