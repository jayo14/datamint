"""Wallet management API endpoints."""

from typing import List

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.identity import User
from app.schemas.auth import NonceRequest, NonceResponse
from app.schemas.wallet import LinkWalletRequest, WalletResponse
from app.services.auth_service import AuthService
from app.services.wallet_service import WalletService

router = APIRouter(prefix="/wallets", tags=["Wallets"])


@router.get("/", response_model=List[WalletResponse], status_code=status.HTTP_200_OK)
async def list_wallets(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> List[WalletResponse]:
    """List all verified wallets linked to the authenticated user."""
    service = WalletService(db)
    return await service.list_user_wallets(user_id=current_user.id)


@router.post("/challenge", response_model=NonceResponse, status_code=status.HTTP_200_OK)
async def create_link_challenge(
    req: NonceRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> NonceResponse:
    """Generate an EIP-4361 challenge specifically bound to link_wallet for this user."""
    auth_service = AuthService(db)
    return await auth_service.create_nonce(
        address=req.address,
        chain_id=req.chain_id,
        action="link_wallet",
        user_id=current_user.id,
    )


@router.post("/link", response_model=WalletResponse, status_code=status.HTTP_201_CREATED)
async def link_wallet(
    req: LinkWalletRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> WalletResponse:
    """Verify cryptographic signature and link an additional wallet to this account."""
    service = WalletService(db)
    wallet = await service.link_wallet(
        user_id=current_user.id,
        message=req.message,
        signature=req.signature,
    )
    await db.commit()
    return wallet


@router.delete("/{address}", status_code=status.HTTP_200_OK)
async def unlink_wallet(
    address: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Unlink a wallet, verifying that another auth method or wallet remains."""
    service = WalletService(db)
    await service.unlink_wallet(user_id=current_user.id, wallet_address=address)
    await db.commit()
    return {"status": "unlinked", "address": address.lower()}


@router.put("/{address}/primary", response_model=WalletResponse, status_code=status.HTTP_200_OK)
async def set_primary_wallet(
    address: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> WalletResponse:
    """Designate a linked wallet as the primary address for payouts and identity."""
    service = WalletService(db)
    wallet = await service.set_primary_wallet(user_id=current_user.id, wallet_address=address)
    await db.commit()
    return wallet
