"""Cryptographic wallet linking, unlinking, and verification service."""

import uuid
from datetime import datetime, timezone
from typing import List

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import (
    DataMintException,
    InvalidSignatureException,
)
from app.core.security import recover_signer_address
from app.models.identity import User
from app.models.wallet import Wallet, WalletNonceChallenge
from app.schemas.wallet import WalletResponse


class WalletService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def list_user_wallets(self, user_id: uuid.UUID) -> List[WalletResponse]:
        query = (
            select(Wallet)
            .where(Wallet.user_id == user_id)
            .order_by(Wallet.is_primary.desc(), Wallet.verified_at.asc())
        )
        result = await self.db.execute(query)
        return [WalletResponse.model_validate(w) for w in result.scalars().all()]

    async def link_wallet(self, user_id: uuid.UUID, message: str, signature: str) -> WalletResponse:
        """Verify signature against challenge and link wallet to user account."""
        recovered_address = recover_signer_address(message, signature)

        # Extract nonce from message
        nonce = None
        for line in message.split("\n"):
            if line.startswith("Nonce: "):
                nonce = line.replace("Nonce: ", "").strip()
                break

        if not nonce:
            raise InvalidSignatureException(
                detail="Message does not contain a valid EIP-4361 nonce"
            )

        # Validate nonce
        challenge_query = select(WalletNonceChallenge).where(
            WalletNonceChallenge.nonce == nonce,
            WalletNonceChallenge.is_used.is_(False),
            WalletNonceChallenge.expires_at > datetime.now(timezone.utc),
        )
        challenge = (await self.db.execute(challenge_query)).scalar_one_or_none()
        if not challenge:
            raise InvalidSignatureException(detail="Nonce is invalid, expired, or already used")

        if challenge.address.lower() != recovered_address.lower():
            raise InvalidSignatureException(
                detail="Signer address does not match challenge target address"
            )

        if challenge.action != "link_wallet":
            raise DataMintException(detail="Challenge was not issued for wallet linking")

        if challenge.user_id and challenge.user_id != user_id:
            raise DataMintException(detail="Challenge was not issued for this user")

        # Mark challenge used
        challenge.is_used = True

        # Check if wallet is already owned by someone else (prevent reassignment)
        existing_wallet_query = select(Wallet).where(Wallet.address == recovered_address.lower())
        existing = (await self.db.execute(existing_wallet_query)).scalar_one_or_none()
        if existing:
            if existing.user_id == user_id:
                return WalletResponse.model_validate(existing)
            raise DataMintException(
                detail="Wallet is already linked to another DataMint account",
                code="WALLET_ALREADY_LINKED",
            )

        # Determine if this should be primary (if user has no other wallets)
        user_wallets_query = select(Wallet).where(Wallet.user_id == user_id)
        has_wallets = (await self.db.execute(user_wallets_query)).scalars().first() is not None
        is_primary = not has_wallets

        wallet = Wallet(
            user_id=user_id,
            address=recovered_address.lower(),
            chain_id=challenge.chain_id,
            is_primary=is_primary,
        )
        self.db.add(wallet)
        await self.db.flush()

        return WalletResponse.model_validate(wallet)

    async def unlink_wallet(self, user_id: uuid.UUID, wallet_address: str) -> None:
        """Unlink a wallet, ensuring the user retains at least one authentication method."""
        clean_address = wallet_address.lower()

        # Find wallet
        query = select(Wallet).where(
            Wallet.user_id == user_id,
            Wallet.address == clean_address,
        )
        wallet = (await self.db.execute(query)).scalar_one_or_none()
        if not wallet:
            raise DataMintException(detail="Wallet not found on this account")

        # Verify user has email/password or another wallet before unlinking
        user_query = select(User).where(User.id == user_id)
        user = (await self.db.execute(user_query)).scalar_one()

        other_wallets_query = select(Wallet).where(
            Wallet.user_id == user_id,
            Wallet.id != wallet.id,
        )
        other_wallets = (await self.db.execute(other_wallets_query)).scalars().all()

        if not other_wallets and not user.hashed_password:
            raise DataMintException(
                detail="Cannot unlink your only authentication method. Set a password or link another wallet first.",
                code="LAST_AUTH_METHOD",
            )

        was_primary = wallet.is_primary
        await self.db.delete(wallet)
        await self.db.flush()

        # If deleted wallet was primary, designate another wallet as primary
        if was_primary and other_wallets:
            other_wallets[0].is_primary = True
            await self.db.flush()

    async def set_primary_wallet(self, user_id: uuid.UUID, wallet_address: str) -> WalletResponse:
        """Designate a linked wallet as primary."""
        clean_address = wallet_address.lower()

        # Unset existing primary
        await self.db.execute(
            update(Wallet).where(Wallet.user_id == user_id).values(is_primary=False)
        )

        # Set target as primary
        query = select(Wallet).where(
            Wallet.user_id == user_id,
            Wallet.address == clean_address,
        )
        wallet = (await self.db.execute(query)).scalar_one_or_none()
        if not wallet:
            raise DataMintException(detail="Wallet not found on this account")

        wallet.is_primary = True
        await self.db.flush()
        return WalletResponse.model_validate(wallet)
