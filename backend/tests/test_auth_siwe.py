"""Test EIP-4361 SIWE challenge generation, signature verification, and replay protection."""

import pytest
from eth_account import Account
from eth_account.messages import encode_defunct

from app.core.exceptions import InvalidSignatureException
from app.services.auth_service import AuthService


@pytest.mark.asyncio
async def test_siwe_challenge_and_verification_flow(db_session):
    """
    Test full SIWE flow:
    1. Generate nonce challenge for address.
    2. Sign message using eth_account.
    3. Verify signature, provision user with dual capabilities, return tokens.
    4. Attempt replay -> fails because nonce is already used.
    """
    auth_service = AuthService(db_session)

    # 1. Generate test wallet account
    account = Account.create()
    wallet_address = account.address.lower()

    # 2. Request nonce challenge
    nonce_res = await auth_service.create_nonce(address=wallet_address, chain_id=42220)
    assert nonce_res.nonce is not None
    assert wallet_address in nonce_res.message

    # 3. Sign message with private key
    signable_msg = encode_defunct(text=nonce_res.message)
    signed_msg = Account.sign_message(signable_msg, private_key=account.key)
    signature_hex = signed_msg.signature.hex()
    if not signature_hex.startswith("0x"):
        signature_hex = "0x" + signature_hex

    # 4. Verify signature and authenticate
    auth_res = await auth_service.verify_signature_and_authenticate(
        message=nonce_res.message, signature=signature_hex
    )
    assert auth_res.access_token is not None
    assert auth_res.refresh_token is not None
    assert auth_res.user.primary_wallet.lower() == wallet_address.lower()
    # Dual capabilities check
    assert "CONTRIBUTOR" in auth_res.user.capabilities
    assert "CREATOR" in auth_res.user.capabilities

    # 5. Replay attempt: submitting the exact same message and signature must fail
    with pytest.raises(InvalidSignatureException):
        await auth_service.verify_signature_and_authenticate(
            message=nonce_res.message, signature=signature_hex
        )
