"""Authentication, session management, and SIWE/password identity service."""

import uuid
from datetime import datetime, timedelta, timezone
from typing import List, Optional, Tuple
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from app.core.config import settings
from app.core.exceptions import (
    DataMintException,
    EntityNotFoundException,
    InvalidSignatureException,
)
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    generate_nonce,
    hash_password,
    recover_signer_address,
    verify_password,
)
from app.models.enums import CapabilityType
from app.models.identity import AuthSession, User, UserCapability, UserProfile
from app.models.wallet import Wallet, WalletNonceChallenge
from app.schemas.auth import AuthTokenResponse, NonceResponse, UserSummary


class AuthService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def register_user(
        self, email: str, password: str, display_name: Optional[str] = None
    ) -> AuthTokenResponse:
        """Register a new user with email and password, provisioning dual capabilities."""
        clean_email = email.lower().strip()

        # Check existing user
        query = select(User).where(User.email == clean_email)
        existing = (await self.db.execute(query)).scalar_one_or_none()
        if existing:
            raise DataMintException(
                detail="User with this email already exists",
                code="EMAIL_ALREADY_EXISTS",
            )

        hashed = hash_password(password)
        new_user = User(
            email=clean_email,
            hashed_password=hashed,
            is_active=True,
            is_verified=False,
        )
        self.db.add(new_user)
        await self.db.flush()

        # Profile
        profile = UserProfile(
            user_id=new_user.id,
            display_name=display_name or clean_email.split("@")[0],
        )
        self.db.add(profile)

        # Dual capabilities (CONTRIBUTOR + CREATOR)
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
        await self.db.flush()

        capabilities = [CapabilityType.CONTRIBUTOR.value, CapabilityType.CREATOR.value]
        return await self._create_auth_response(new_user, capabilities, primary_wallet=None)

    async def login_user(self, email: str, password: str) -> AuthTokenResponse:
        """Authenticate user with email and password."""
        clean_email = email.lower().strip()
        query = (
            select(User)
            .where(User.email == clean_email)
            .options(
                selectinload(User.capabilities),
                selectinload(User.wallets),
            )
        )
        user = (await self.db.execute(query)).scalar_one_or_none()

        if not user or not user.hashed_password:
            raise DataMintException(
                detail="Invalid email or password",
                code="INVALID_CREDENTIALS",
            )

        if not user.is_active:
            raise DataMintException(
                detail="Account is suspended or deactivated",
                code="ACCOUNT_INACTIVE",
            )

        if not verify_password(password, user.hashed_password):
            raise DataMintException(
                detail="Invalid email or password",
                code="INVALID_CREDENTIALS",
            )

        capabilities = [c.capability_type for c in user.capabilities if c.is_enabled]
        primary_wallet = next((w.address for w in user.wallets if w.is_primary), None)

        return await self._create_auth_response(user, capabilities, primary_wallet)

    async def create_nonce(
        self,
        address: str,
        chain_id: int = 42220,
        action: str = "login",
        user_id: Optional[uuid.UUID] = None,
    ) -> NonceResponse:
        """Generate EIP-4361 compliant nonce challenge bound to address, chain, and action."""
        clean_address = address.lower()
        nonce = generate_nonce(16)
        expires_at = datetime.now(timezone.utc) + timedelta(seconds=settings.NONCE_EXPIRE_SECONDS)

        challenge = WalletNonceChallenge(
            address=clean_address,
            nonce=nonce,
            chain_id=chain_id,
            action=action,
            user_id=user_id,
            expires_at=expires_at,
        )
        self.db.add(challenge)
        await self.db.flush()

        message = (
            f"datamint.ai wants you to sign in with your Celo account:\n"
            f"{clean_address}\n\n"
            f"Action: {action}\n"
            f"URI: https://datamint.ai\n"
            f"Version: 1\n"
            f"Chain ID: {chain_id}\n"
            f"Nonce: {nonce}\n"
            f"Issued At: {datetime.now(timezone.utc).isoformat()}"
        )

        return NonceResponse(
            nonce=nonce,
            message=message,
            action=action,
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

        return await self._create_auth_response(user, capabilities, primary_wallet=recovered_address)

    async def refresh_session(self, refresh_token: str) -> AuthTokenResponse:
        """Rotate refresh token and issue new access token."""
        payload = decode_token(refresh_token)
        if payload.get("type") != "refresh":
            raise DataMintException(detail="Invalid token type for refresh", code="INVALID_TOKEN")

        user_id_str = payload.get("sub")
        if not user_id_str:
            raise DataMintException(detail="Missing subject in token", code="INVALID_TOKEN")

        user_id = uuid.UUID(user_id_str)

        # Verify session is active and not revoked
        token_prefix = refresh_token[:64]
        session_query = select(AuthSession).where(
            AuthSession.user_id == user_id,
            AuthSession.refresh_token_hash == token_prefix,
            AuthSession.is_revoked.is_(False),
            AuthSession.expires_at > datetime.now(timezone.utc),
        )
        session = (await self.db.execute(session_query)).scalar_one_or_none()

        if not session:
            raise DataMintException(
                detail="Session expired, revoked, or invalid", code="SESSION_REVOKED"
            )

        # Revoke old session (Rotation)
        session.is_revoked = True

        # Load user
        user_query = (
            select(User)
            .where(User.id == user_id, User.is_active.is_(True))
            .options(
                selectinload(User.capabilities),
                selectinload(User.wallets),
            )
        )
        user = (await self.db.execute(user_query)).scalar_one_or_none()
        if not user:
            raise EntityNotFoundException("User", user_id)

        capabilities = [c.capability_type for c in user.capabilities if c.is_enabled]
        primary_wallet = next((w.address for w in user.wallets if w.is_primary), None)

        return await self._create_auth_response(user, capabilities, primary_wallet)

    async def logout(self, user_id: uuid.UUID, refresh_token: Optional[str] = None) -> None:
        """Revoke user session(s)."""
        if refresh_token:
            token_prefix = refresh_token[:64]
            session_query = select(AuthSession).where(
                AuthSession.user_id == user_id,
                AuthSession.refresh_token_hash == token_prefix,
            )
            session = (await self.db.execute(session_query)).scalar_one_or_none()
            if session:
                session.is_revoked = True
        else:
            # Revoke all active sessions for this user
            sessions_query = select(AuthSession).where(
                AuthSession.user_id == user_id,
                AuthSession.is_revoked.is_(False),
            )
            sessions = (await self.db.execute(sessions_query)).scalars().all()
            for s in sessions:
                s.is_revoked = True

        await self.db.flush()

    async def _create_auth_response(
        self, user: User, capabilities: List[str], primary_wallet: Optional[str]
    ) -> AuthTokenResponse:
        refresh_token = create_refresh_token(str(user.id))
        session = AuthSession(
            user_id=user.id,
            refresh_token_hash=refresh_token[:64],
            expires_at=datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
        )
        self.db.add(session)
        await self.db.flush()

        access_token = create_access_token(
            subject=str(user.id),
            capabilities=capabilities,
            wallet_address=primary_wallet,
        )

        return AuthTokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
            user=UserSummary(
                id=user.id,
                email=user.email,
                primary_wallet=primary_wallet,
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

        new_user = User(is_active=True, is_verified=True)
        self.db.add(new_user)
        await self.db.flush()

        profile = UserProfile(
            user_id=new_user.id,
            display_name=f"{wallet_address[:6]}...{wallet_address[-4:]}",
        )
        self.db.add(profile)

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

        new_wallet = Wallet(
            user_id=new_user.id,
            address=wallet_address.lower(),
            chain_id=chain_id,
            is_primary=True,
        )
        self.db.add(new_wallet)
        await self.db.flush()

        return new_user, [CapabilityType.CONTRIBUTOR.value, CapabilityType.CREATOR.value]
