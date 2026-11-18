"""Authentication API endpoints (EIP-4361 SIWE)."""

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.schemas.auth import (
    AuthTokenResponse,
    NonceRequest,
    NonceResponse,
    VerifySignatureRequest,
)
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/nonce", response_model=NonceResponse, status_code=status.HTTP_200_OK)
async def generate_nonce(req: NonceRequest, db: AsyncSession = Depends(get_db)) -> NonceResponse:
    """Generate an EIP-4361 nonce challenge for wallet signature."""
    service = AuthService(db)
    return await service.create_nonce(address=req.address, chain_id=req.chain_id)


@router.post("/verify", response_model=AuthTokenResponse, status_code=status.HTTP_200_OK)
async def verify_signature(
    req: VerifySignatureRequest, db: AsyncSession = Depends(get_db)
) -> AuthTokenResponse:
    """Verify signed EIP-4361 message, create or resolve user, and return JWT tokens."""
    service = AuthService(db)
    token_response = await service.verify_signature_and_authenticate(
        message=req.message, signature=req.signature
    )
    await db.commit()
    return token_response
