"""Tests for AWS KMS DER to Ethereum (r, s, v) conversion and EIP-712 signing."""

import pytest
from eth_account import Account
from eth_utils import keccak, to_checksum_address

from app.services.kms_signer import (
    SECP256K1_HALF_N,
    SECP256K1_N,
    KmsSignerProvider,
    der_to_eth_signature,
    eth_to_der_signature,
    normalize_low_s,
)


def test_normalize_low_s():
    """Verify that high s values are flipped to canonical lower half (EIP-2)."""
    low_s = 1000
    assert normalize_low_s(low_s) == low_s

    high_s = SECP256K1_HALF_N + 500
    normalized = normalize_low_s(high_s)
    assert normalized < SECP256K1_HALF_N
    assert normalized == SECP256K1_N - high_s


def test_der_to_eth_signature_roundtrip():
    """Generate signature using known private key, convert to DER, then back to Ethereum format."""
    acct = Account.create()
    message_digest = keccak(text="DataMint test message for KMS signing")

    # Sign using eth_account to get canonical r, s, v
    signed = acct.unsafe_sign_hash(message_digest)
    r = signed.r
    s = signed.s
    expected_v = signed.v

    # Encode to ASN.1 DER format as AWS KMS would return
    der_bytes = eth_to_der_signature(r, s)

    # Convert DER back using our converter
    sig_hex, recovered_v, rec_r, rec_s = der_to_eth_signature(
        der_signature=der_bytes,
        message_digest=message_digest,
        expected_address=acct.address,
    )

    assert rec_r == r
    assert rec_s == s
    assert recovered_v == expected_v
    assert recovered_v in (27, 28)

    # Verify that the reconstructed signature recovers the expected address
    recovered_address = Account._recover_hash(message_digest, vrs=(recovered_v, rec_r, rec_s))
    assert to_checksum_address(recovered_address) == to_checksum_address(acct.address)


def test_der_conversion_enforces_low_s():
    """Test that if a KMS key generates high-s signature, converter normalizes to low-s."""
    acct = Account.create()
    message_digest = keccak(text="Testing high-s malleability normalization")

    signed = acct.unsafe_sign_hash(message_digest)
    r = signed.r
    # Deliberately construct a malleable high-s
    high_s = SECP256K1_N - signed.s
    assert high_s > SECP256K1_HALF_N

    der_high_s = eth_to_der_signature(r, high_s)

    sig_hex, rec_v, rec_r, rec_s = der_to_eth_signature(
        der_signature=der_high_s,
        message_digest=message_digest,
        expected_address=acct.address,
    )

    assert rec_s <= SECP256K1_HALF_N
    assert rec_s == signed.s
    recovered_address = Account._recover_hash(message_digest, vrs=(rec_v, rec_r, rec_s))
    assert to_checksum_address(recovered_address) == to_checksum_address(acct.address)


def test_der_conversion_mismatched_address_raises():
    """Test that supplying a mismatched address raises ValueError."""
    acct = Account.create()
    wrong_acct = Account.create()
    message_digest = keccak(text="Some test digest")

    signed = acct.unsafe_sign_hash(message_digest)
    der_bytes = eth_to_der_signature(signed.r, signed.s)

    with pytest.raises(ValueError, match="Could not recover expected address"):
        der_to_eth_signature(
            der_signature=der_bytes,
            message_digest=message_digest,
            expected_address=wrong_acct.address,
        )


def test_kms_signer_provider_eip712_mock():
    """Test KmsSignerProvider with simulated KMS client generating EIP-712 vouchers."""
    acct = Account.create()

    class MockKmsClient:
        def sign(self, KeyId, Message, MessageType, SigningAlgorithm):  # noqa: N803
            assert MessageType == "DIGEST"
            assert SigningAlgorithm == "ECDSA_SHA_256"
            # Simulate AWS KMS signing the digest
            signed = acct.unsafe_sign_hash(Message)
            return {"Signature": eth_to_der_signature(signed.r, signed.s)}

    provider = KmsSignerProvider(
        key_id="arn:aws:kms:us-east-1:123456789012:key/test-voucher-key",
        expected_address=acct.address,
        contract_address="0x1111111111111111111111111111111111111111",
        chain_id=11142220,  # Celo Sepolia
        kms_client=MockKmsClient(),
    )

    assert provider.get_signer_address() == to_checksum_address(acct.address)

    sig_hex, digest_hash_hex = provider.sign_reward_voucher(
        campaign_id_hex="0x" + "aa" * 32,
        contributor_address="0x2222222222222222222222222222222222222222",
        amount_wei=10**18,
        nonce_hex="0x" + "bb" * 32,
        deadline_timestamp=1800000000,
    )

    assert sig_hex.startswith("0x")
    assert len(sig_hex) == 2 + 130  # 65 bytes = 130 hex chars
    assert digest_hash_hex.startswith("0x")
    assert len(digest_hash_hex) == 66
