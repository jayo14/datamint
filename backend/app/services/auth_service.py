"""Authentication and wallet verification service implementing EIP-4361 SIWE."""

import uuid
from datetime import datetime, timedelta, timezone
from typing import List, Tuple
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from app.core.config import settings
from app.core.exceptions import DataMintException, InvalidSignatureException
from app.core.security import (
    create_access_token,
    create_refresh_token,
    generate_nonce,
    recover_signer_address,
)
from app.models.enums import CapabilityType
from app.models.identity import AuthSession, User, UserCapability, UserProfile
from app.models.wallet import Wallet, WalletNonceChallenge
from app.schemas.auth import AuthTokenResponse, NonceResponse, UserSummary


class AuthService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_nonce(self, address: str, chain_id: int = 42220) -> NonceResponse:
        """Generate EIP-4361 compliant nonce challenge."""
        clean_address = address.lower()
        nonce = generate_nonce(16)
        expires_at = datetime.now(timezone.utc) + timedelta(seconds=settings.NONCE_EXPIRE_SECONDS)

        challenge = WalletNonceChallenge(
            address=clean_address,
            nonce=nonce,
            chain_id=chain_id,
            expires_at=expires_at,
        )
        self.db.add(challenge)
        await self.db.flush()

        # Build EIP-4361 template message
        message = (
            f"datamint.ai wants you to sign in with your Celo account:\n"
            f"{clean_address}\n\n"
            f"URI: https://datamint.ai\n"
            f"Version: 1\n"
            f"Chain ID: {chain_id}\n"
            f"Nonce: {nonce}\n"
            f"Issued At: {datetime.now(timezone.utc).isoformat()}"
        )

        return NonceResponse(
            nonce=nonce,
            message=message,
            expires_at=expires_at,
        )

    async def verify_signature_and_authenticate(
        self, message: str, signature: str
    ) -> AuthTokenResponse:
        """Verify SIWE signature, validate nonce, provision dual-capability user if new, issue JWTs."""
        recovered_address = recover_signer_address(message, signature)

        # Extract nonce from message
        nonce = None
        for line in message.split("\n"):
            if line.startswith("Nonce: "):
                nonce = line.replace("Nonce: ", "").strip()
                break

        if not nonce:
            raise InvalidSignatureException(detail="Message does not contain a valid EIP-4361 nonce")

        # Validate nonce in DB
        challenge_query = select(WalletNonceChallenge).where(
            WalletNonceChallenge.nonce == nonce,
            WalletNonceChallenge.is_used.is_(False),
            WalletNonceChallenge.expires_at > datetime.now(timezone.utc),
        )
        result = await self.db.execute(challenge_query)
        challenge = result.scalar_one_or_none()

        if not challenge:
            raise InvalidSignatureException(detail="Nonce is invalid, expired, or already used")

        if challenge.address.lower() != recovered_address.lower():
            raise InvalidSignatureException(
                detail="Signer address does not match challenge target address"
            )

        # Mark challenge used
        challenge.is_used = True

        # Find or create user by wallet address
        user, capabilities = await self._find_or_create_user(recovered_address, challenge.chain_id)

        # Create session
        refresh_token = create_refresh_token(str(user.id))
        session = AuthSession(
            user_id=user.id,
            refresh_token_hash=refresh_token[:64],  # hash/store key prefix
            expires_at=datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
        )
        self.db.add(session)
        await self.db.flush()

        access_token = create_access_token(
            subject=str(user.id),
            wallet_address=recovered_address,
            capabilities=capabilities,
        )

        return AuthTokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
            user=UserSummary(
                id=user.id,
                email=user.email,
                primary_wallet=recovered_address,
                capabilities=capabilities,
            ),
        )

    async def _find_or_create_user(
        self, wallet_address: str, chain_id: int
    ) -> Tuple[User, List[str]]:
        """Resolve user by wallet or provision a new user with dual capabilities (CONTRIBUTOR + CREATOR)."""
        wallet_query = (
            select(Wallet)
            .where(Wallet.address == wallet_address.lower())
            .options(selectinload(Wallet.user).selectinload(User.capabilities))
        )
        wallet = (await self.db.execute(wallet_query)).scalar_one_or_none()

        if wallet:
            user = wallet.user
            caps = [c.capability_type for c in user.capabilities if c.is_enabled]
            return user, caps

        # Create new user
        new_user = User()
        self.db.add(new_user)
        await self.db.flush()

        # Create profile
        profile = UserProfile(
            user_id=new_user.id,
            display_name=f"{wallet_address[:6]}...{wallet_address[-4:]}",
        )
        self.db.add(profile)

        # Dual-capabilities: automatically grant BOTH CONTRIBUTOR and CREATOR capabilities
        cap_contributor = UserCapability(
            user_id=new_user.id,
            capability_type=CapabilityType.CONTRIBUTOR.value,
            is_enabled=True,
        )
        cap_creator = UserCapability(
            user_id=new_user.id,
            capability_type=CapabilityType.CREATOR.value,
            is_enabled=True,
        )
        self.db.add_all([cap_contributor, cap_creator])

        # Register wallet
        new_wallet = Wallet(
            user_id=new_user.id,
            address=wallet_address.lower(),
            chain_id=chain_id,
            is_primary=True,
        )
        self.db.add(new_wallet)
        await self.db.flush()

        return new_user, [CapabilityType.CONTRIBUTOR.value, CapabilityType.CREATOR.value]
