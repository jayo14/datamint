"""Cryptographic security, JWT tokens, and Ethereum/Celo signature verification."""

import secrets
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

import jwt
from eth_account import Account
from eth_account.messages import encode_defunct

from app.core.config import settings
from app.core.exceptions import InvalidSignatureException


def create_access_token(
    subject: str,
    wallet_address: str,
    capabilities: List[str],
    expires_delta: Optional[timedelta] = None,
) -> str:
    """Generate signed JWT access token."""
    now = datetime.now(timezone.utc)
    if expires_delta:
        expire = now + expires_delta
    else:
        expire = now + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)

    to_encode: Dict[str, Any] = {
        "sub": subject,
        "wallet": wallet_address.lower(),
        "capabilities": capabilities,
        "iat": now.timestamp(),
        "exp": expire.timestamp(),
        "type": "access",
    }
    return jwt.encode(to_encode, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)


def create_refresh_token(subject: str, expires_delta: Optional[timedelta] = None) -> str:
    """Generate signed JWT refresh token."""
    now = datetime.now(timezone.utc)
    if expires_delta:
        expire = now + expires_delta
    else:
        expire = now + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)

    to_encode: Dict[str, Any] = {
        "sub": subject,
        "iat": now.timestamp(),
        "exp": expire.timestamp(),
        "type": "refresh",
    }
    return jwt.encode(to_encode, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)


def decode_token(token: str) -> Dict[str, Any]:
    """Decode and validate JWT token claims."""
    try:
        payload = jwt.decode(
            token,
            settings.JWT_SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM],
        )
        return payload
    except jwt.PyJWTError as e:
        raise InvalidSignatureException(detail=f"Token verification failed: {str(e)}")


def generate_nonce(length: int = 16) -> str:
    """Generate a random cryptographic hex nonce for EIP-4361."""
    return secrets.token_hex(length // 2)


def recover_signer_address(message: str, signature: str) -> str:
    """Recover the Ethereum/Celo address that signed the message."""
    try:
        signable_message = encode_defunct(text=message)
        recovered_address = Account.recover_message(signable_message, signature=signature)
        return str(recovered_address).lower()
    except Exception as e:
        raise InvalidSignatureException(detail=f"Signature recovery failed: {str(e)}")
