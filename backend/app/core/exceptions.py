"""Standard domain exceptions and error handling."""

from typing import Any, Dict, Optional

from fastapi import HTTPException, status


class DataMintException(HTTPException):
    def __init__(
        self,
        status_code: int = status.HTTP_400_BAD_REQUEST,
        detail: str = "An error occurred",
        code: str = "DATAMINT_ERROR",
        extra: Optional[Dict[str, Any]] = None,
    ):
        super().__init__(
            status_code=status_code,
            detail={"code": code, "message": detail, "extra": extra or {}},
        )


class EntityNotFoundException(DataMintException):
    def __init__(self, entity: str, identifier: Any):
        super().__init__(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"{entity} with identifier '{identifier}' not found",
            code="ENTITY_NOT_FOUND",
        )


class FinancialInvariantViolationException(DataMintException):
    def __init__(self, detail: str, extra: Optional[Dict[str, Any]] = None):
        super().__init__(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Financial invariant violated: {detail}",
            code="FINANCIAL_INVARIANT_VIOLATION",
            extra=extra,
        )


class InsufficientFundsException(DataMintException):
    def __init__(self, required: str, available: str):
        super().__init__(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Insufficient available escrow funds: required {required}, available {available}",
            code="INSUFFICIENT_FUNDS",
        )


class InvalidStateTransitionException(DataMintException):
    def __init__(self, current_state: str, attempted_state: str):
        super().__init__(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid transition from state '{current_state}' to '{attempted_state}'",
            code="INVALID_STATE_TRANSITION",
        )


class UnauthorizedCapabilityException(DataMintException):
    def __init__(self, required_capability: str):
        super().__init__(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"User lacks required capability: {required_capability}",
            code="CAPABILITY_REQUIRED",
        )


class InvalidSignatureException(DataMintException):
    def __init__(self, detail: str = "Invalid cryptographic signature"):
        super().__init__(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=detail,
            code="INVALID_SIGNATURE",
        )
