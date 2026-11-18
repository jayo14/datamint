"""Authentication API endpoints (EIP-4361 SIWE and Email/Password)."""

from typing import Optional

from fastapi import APIRouter, Depends, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.core.database import get_db
from app.core.rate_limit import auth_rate_limiter
from app.models.identity import User
from app.schemas.auth import (
    AuthTokenResponse,
    LogoutRequest,
    NonceRequest,
    NonceResponse,
    RefreshTokenRequest,
    UserLoginRequest,
    UserRegisterRequest,
    VerifySignatureRequest,
)
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=AuthTokenResponse, status_code=status.HTTP_201_CREATED)
async def register(
    req: UserRegisterRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
) -> AuthTokenResponse:
    """Register a new user with email and password."""
    await auth_rate_limiter.check(request, key_prefix="auth:register")
    service = AuthService(db)
    token_response = await service.register_user(
        email=req.email,
        password=req.password,
        display_name=req.display_name,
    )
    await db.commit()
    return token_response


@router.post("/login", response_model=AuthTokenResponse, status_code=status.HTTP_200_OK)
async def login(
    req: UserLoginRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
) -> AuthTokenResponse:
    """Authenticate user with email and password."""
    await auth_rate_limiter.check(request, key_prefix="auth:login")
    service = AuthService(db)
    token_response = await service.login_user(
        email=req.email,
        password=req.password,
    )
    await db.commit()
    return token_response


@router.post("/nonce", response_model=NonceResponse, status_code=status.HTTP_200_OK)
async def generate_nonce(
    req: NonceRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
) -> NonceResponse:
    """Generate an EIP-4361 nonce challenge for wallet signature."""
    await auth_rate_limiter.check(request, key_prefix="auth:nonce")
    service = AuthService(db)
    res = await service.create_nonce(
        address=req.address,
        chain_id=req.chain_id,
        action=req.action,
    )
    await db.commit()
    return res


@router.get("/siwe-challenge", response_model=NonceResponse, status_code=status.HTTP_200_OK)
async def get_siwe_challenge(
    address: str,
    request: Request,
    chain_id: Optional[int] = 42220,
    action: Optional[str] = "login",
    db: AsyncSession = Depends(get_db),
) -> NonceResponse:
    """Generate an EIP-4361 nonce challenge via GET for client convenience."""
    await auth_rate_limiter.check(request, key_prefix="auth:nonce")
    service = AuthService(db)
    res = await service.create_nonce(
        address=address,
        chain_id=chain_id or 42220,
        action=action or "login",
    )
    await db.commit()
    return res


@router.post("/verify", response_model=AuthTokenResponse, status_code=status.HTTP_200_OK)
async def verify_signature(
    req: VerifySignatureRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
) -> AuthTokenResponse:
    """Verify signed EIP-4361 message, create or resolve user, and return JWT tokens."""
    await auth_rate_limiter.check(request, key_prefix="auth:verify")
    service = AuthService(db)
    token_response = await service.verify_signature_and_authenticate(
        message=req.message, signature=req.signature
    )
    await db.commit()
    return token_response


@router.post("/siwe-verify", response_model=AuthTokenResponse, status_code=status.HTTP_200_OK)
async def verify_siwe(
    req: VerifySignatureRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
) -> AuthTokenResponse:
    """Verify signed EIP-4361 message alias."""
    return await verify_signature(req=req, request=request, db=db)


@router.post("/refresh", response_model=AuthTokenResponse, status_code=status.HTTP_200_OK)
async def refresh_token(
    req: RefreshTokenRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
) -> AuthTokenResponse:
    """Refresh session and rotate tokens."""
    await auth_rate_limiter.check(request, key_prefix="auth:refresh")
    service = AuthService(db)
    token_response = await service.refresh_session(refresh_token=req.refresh_token)
    await db.commit()
    return token_response


@router.post("/logout", status_code=status.HTTP_200_OK)
async def logout(
    req: LogoutRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Logout current user and revoke session."""
    service = AuthService(db)
    await service.logout(user_id=current_user.id, refresh_token=req.refresh_token)
    await db.commit()
    return {"status": "logged_out", "detail": "Session successfully revoked"}
