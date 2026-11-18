"""Base interfaces and data structures for provider-independent AI validation."""

from dataclasses import dataclass, field
from decimal import Decimal
from typing import Any, Dict, List, Optional, Protocol


@dataclass
class FindingData:
    code: str
    severity: str  # "INFO", "WARNING", "CRITICAL", "BLOCKER"
    message: str
    is_deterministic: bool = False
    evidence: Optional[str] = None
    details: Optional[Dict[str, Any]] = None


@dataclass
class ProviderValidationResult:
    confidence_score: Decimal
    findings: List[FindingData] = field(default_factory=list)
    raw_output: Optional[Dict[str, Any]] = None
    provider: str = "mock"
    model_version: str = "default"
    failure_reason: Optional[str] = None


class AIValidationProvider(Protocol):
    """Abstract provider adapter for multi-modal validation."""

    async def validate_text(
        self,
        content: str,
        instructions: Optional[str] = None,
        criteria: Optional[Dict[str, Any]] = None,
    ) -> ProviderValidationResult: ...

    async def validate_voice(
        self,
        audio_data: bytes,
        mime_type: str,
        instructions: Optional[str] = None,
        criteria: Optional[Dict[str, Any]] = None,
    ) -> ProviderValidationResult: ...

    async def validate_image(
        self,
        image_data: bytes,
        mime_type: str,
        instructions: Optional[str] = None,
        criteria: Optional[Dict[str, Any]] = None,
    ) -> ProviderValidationResult: ...
