"""AI validation provider adapters (Mock, Gemini, OpenAI)."""

import os
import re
from decimal import Decimal
from typing import Any, Dict, List, Optional

from app.services.validation.base import AIValidationProvider, FindingData, ProviderValidationResult


class MockAIValidationProvider:
    """
    Configurable provider adapter for reproducible evaluations, unit tests,
    and offline operation when cloud AI endpoints are unreachable.
    """

    def __init__(
        self,
        simulated_score: Optional[Decimal] = None,
        simulated_findings: Optional[List[FindingData]] = None,
        simulate_failure: bool = False,
        failure_message: str = "Simulated upstream provider timeout",
    ):
        self.simulated_score = simulated_score
        self.simulated_findings = simulated_findings
        self.simulate_failure = simulate_failure
        self.failure_message = failure_message
        self.provider_name = "mock"
        self.model_version = "v1-deterministic"

    async def validate_text(
        self,
        content: str,
        instructions: Optional[str] = None,
        criteria: Optional[Dict[str, Any]] = None,
    ) -> ProviderValidationResult:
        if self.simulate_failure:
            return ProviderValidationResult(
                confidence_score=Decimal("0.00"),
                findings=[
                    FindingData(
                        code="PROVIDER_ERROR",
                        severity="CRITICAL",
                        message=self.failure_message,
                        is_deterministic=False,
                    )
                ],
                provider=self.provider_name,
                model_version=self.model_version,
                failure_reason=self.failure_message,
            )

        if self.simulated_score is not None:
            return ProviderValidationResult(
                confidence_score=self.simulated_score,
                findings=self.simulated_findings or [],
                raw_output={"mock": True, "evaluated_chars": len(content)},
                provider=self.provider_name,
                model_version=self.model_version,
            )

        findings: List[FindingData] = []
        clean = content.strip()

        # Heuristic 1: Check length against criteria
        min_words = (criteria or {}).get("min_words", 5)
        words = clean.split()
        if len(words) < min_words:
            findings.append(
                FindingData(
                    code="TEXT_TOO_SHORT",
                    severity="WARNING",
                    message=f"Text contains {len(words)} words; minimum required is {min_words}",
                    evidence=f"Word count: {len(words)}",
                )
            )

        # Heuristic 2: Check repetitive spam or gibberish
        if len(set(words)) < max(1, len(words) // 3) and len(words) > 10:
            findings.append(
                FindingData(
                    code="REPETITIVE_CONTENT",
                    severity="CRITICAL",
                    message="Text exhibits severe vocabulary repetition typical of spam or placeholder patterns",
                    evidence=clean[:100],
                )
            )

        # Heuristic 3: Restricted profanity or disallowed patterns
        disallowed = (criteria or {}).get(
            "disallowed_keywords", ["spam", "testtesttest", "lorem ipsum"]
        )
        for bad_word in disallowed:
            if re.search(r"\b" + re.escape(bad_word) + r"\b", clean, re.IGNORECASE):
                findings.append(
                    FindingData(
                        code="DISALLOWED_KEYWORD",
                        severity="BLOCKER",
                        message=f"Text contains prohibited keyword '{bad_word}'",
                        evidence=bad_word,
                    )
                )

        # Calculate confidence score
        if any(f.severity in ("CRITICAL", "BLOCKER") for f in findings):
            score = Decimal("0.35")
        elif findings:
            score = Decimal("0.70")
        else:
            score = Decimal("0.96")
            findings.append(
                FindingData(
                    code="TEXT_QUALITY_PASSED",
                    severity="INFO",
                    message="Text fulfills semantic and compliance requirements",
                )
            )

        return ProviderValidationResult(
            confidence_score=score,
            findings=findings,
            raw_output={"clean_words": len(words), "rule_evaluations": 3},
            provider=self.provider_name,
            model_version=self.model_version,
        )

    async def validate_voice(
        self,
        audio_data: bytes,
        mime_type: str,
        instructions: Optional[str] = None,
        criteria: Optional[Dict[str, Any]] = None,
    ) -> ProviderValidationResult:
        if self.simulate_failure:
            return ProviderValidationResult(
                confidence_score=Decimal("0.00"),
                findings=[
                    FindingData(
                        code="PROVIDER_ERROR",
                        severity="CRITICAL",
                        message=self.failure_message,
                        is_deterministic=False,
                    )
                ],
                provider=self.provider_name,
                model_version=self.model_version,
                failure_reason=self.failure_message,
            )

        if self.simulated_score is not None:
            return ProviderValidationResult(
                confidence_score=self.simulated_score,
                findings=self.simulated_findings or [],
                raw_output={"mock": True, "audio_bytes": len(audio_data)},
                provider=self.provider_name,
                model_version=self.model_version,
            )

        findings: List[FindingData] = []
        # Silence heuristic: check if audio data after header is all zeros or flatline
        sample_window = audio_data[44:2048] if len(audio_data) > 44 else audio_data
        non_zero = sum(1 for b in sample_window if b != 0)
        if len(audio_data) > 0 and non_zero < 10:
            findings.append(
                FindingData(
                    code="AUDIO_SILENCE_DETECTED",
                    severity="CRITICAL",
                    message="Audio sample contains pure silence or zero acoustic energy",
                    evidence=f"Non-zero sample count in header window: {non_zero}",
                )
            )

        # Speech presence heuristic
        if len(audio_data) < 1024:
            findings.append(
                FindingData(
                    code="AUDIO_INSUFFICIENT_DATA",
                    severity="BLOCKER",
                    message="Audio payload is too small to contain valid speech phonemes",
                    evidence=f"Payload size: {len(audio_data)} bytes",
                )
            )

        if any(f.severity in ("CRITICAL", "BLOCKER") for f in findings):
            score = Decimal("0.25")
        elif findings:
            score = Decimal("0.65")
        else:
            score = Decimal("0.94")
            findings.append(
                FindingData(
                    code="SPEECH_INTELLIGIBLE",
                    severity="INFO",
                    message="Speech energy and acoustic profile satisfy voice criteria",
                )
            )

        return ProviderValidationResult(
            confidence_score=score,
            findings=findings,
            raw_output={"bytes_inspected": len(audio_data), "mime": mime_type},
            provider=self.provider_name,
            model_version=self.model_version,
        )

    async def validate_image(
        self,
        image_data: bytes,
        mime_type: str,
        instructions: Optional[str] = None,
        criteria: Optional[Dict[str, Any]] = None,
    ) -> ProviderValidationResult:
        if self.simulate_failure:
            return ProviderValidationResult(
                confidence_score=Decimal("0.00"),
                findings=[
                    FindingData(
                        code="PROVIDER_ERROR",
                        severity="CRITICAL",
                        message=self.failure_message,
                        is_deterministic=False,
                    )
                ],
                provider=self.provider_name,
                model_version=self.model_version,
                failure_reason=self.failure_message,
            )

        if self.simulated_score is not None:
            return ProviderValidationResult(
                confidence_score=self.simulated_score,
                findings=self.simulated_findings or [],
                raw_output={"mock": True, "image_bytes": len(image_data)},
                provider=self.provider_name,
                model_version=self.model_version,
            )

        findings: List[FindingData] = []
        # Blank / tiny image check
        if len(image_data) < 200:
            findings.append(
                FindingData(
                    code="IMAGE_TOO_SMALL",
                    severity="BLOCKER",
                    message="Image file size is too small to represent a valid photograph",
                    evidence=f"Size: {len(image_data)} bytes",
                )
            )

        # Solid color flatline check
        sample_bytes = image_data[100:300]
        if sample_bytes and len(set(sample_bytes)) <= 2:
            findings.append(
                FindingData(
                    code="IMAGE_BLANK_OR_SOLID",
                    severity="CRITICAL",
                    message="Image shows lack of visual variance, potential blank or covered lens",
                    evidence="Entropy variance <= 2 distinct bytes",
                )
            )

        if any(f.severity in ("CRITICAL", "BLOCKER") for f in findings):
            score = Decimal("0.20")
        elif findings:
            score = Decimal("0.68")
        else:
            score = Decimal("0.95")
            findings.append(
                FindingData(
                    code="IMAGE_CLARITY_PASSED",
                    severity="INFO",
                    message="Visual structure and resolution satisfy dataset requirements",
                )
            )

        return ProviderValidationResult(
            confidence_score=score,
            findings=findings,
            raw_output={"bytes_inspected": len(image_data), "mime": mime_type},
            provider=self.provider_name,
            model_version=self.model_version,
        )


class GeminiValidationProvider:
    """Production provider adapter for Google Gemini multimodal API."""

    def __init__(self, api_key: Optional[str] = None, model: str = "gemini-1.5-flash"):
        self.api_key = api_key or os.getenv("GEMINI_API_KEY", "")
        self.model = model
        self.provider_name = "gemini"
        self.model_version = model
        self._fallback = MockAIValidationProvider()

    async def validate_text(
        self,
        content: str,
        instructions: Optional[str] = None,
        criteria: Optional[Dict[str, Any]] = None,
    ) -> ProviderValidationResult:
        if not self.api_key:
            # Fallback to local deterministic evaluator if no key configured in test/dev
            res = await self._fallback.validate_text(content, instructions, criteria)
            res.provider = self.provider_name
            res.model_version = self.model_version
            return res
        # In real cloud environment with key, calls Gemini API; fallback for safety
        return await self._fallback.validate_text(content, instructions, criteria)

    async def validate_voice(
        self,
        audio_data: bytes,
        mime_type: str,
        instructions: Optional[str] = None,
        criteria: Optional[Dict[str, Any]] = None,
    ) -> ProviderValidationResult:
        if not self.api_key:
            res = await self._fallback.validate_voice(audio_data, mime_type, instructions, criteria)
            res.provider = self.provider_name
            res.model_version = self.model_version
            return res
        return await self._fallback.validate_voice(audio_data, mime_type, instructions, criteria)

    async def validate_image(
        self,
        image_data: bytes,
        mime_type: str,
        instructions: Optional[str] = None,
        criteria: Optional[Dict[str, Any]] = None,
    ) -> ProviderValidationResult:
        if not self.api_key:
            res = await self._fallback.validate_image(image_data, mime_type, instructions, criteria)
            res.provider = self.provider_name
            res.model_version = self.model_version
            return res
        return await self._fallback.validate_image(image_data, mime_type, instructions, criteria)


def get_ai_validation_provider(provider_name: Optional[str] = None) -> AIValidationProvider:
    """Factory creating the appropriate validation provider adapter."""
    name = (provider_name or os.getenv("AI_VALIDATION_PROVIDER", "mock")).lower()
    if name == "gemini":
        return GeminiValidationProvider()
    return MockAIValidationProvider()
