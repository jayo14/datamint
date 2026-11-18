"""AWS KMS secp256k1 EIP-712 Signer and ASN.1 DER to Ethereum (r, s, v) Converter.

This module provides:
1. Cryptographic conversion of AWS KMS ASN.1 DER-encoded ECDSA signatures into
   canonical 65-byte Ethereum recoverable signatures (r, s, v).
2. Canonical low-s malleability normalization (EIP-2 / SECP256K1).
3. Recovery byte (v in {27, 28}) resolution against expected signer public address.
4. KmsSignerProvider implementing the SignerProvider protocol.
5. Strict separation between Voucher Signer (AWS KMS) and Contract Owner (3-of-5 Safe).
"""

from typing import Any, Optional, Tuple
from cryptography.hazmat.primitives.asymmetric.utils import (
    decode_dss_signature,
    encode_dss_signature,
)
from eth_account import Account
from eth_account.messages import encode_typed_data
from eth_utils import keccak, to_checksum_address

# SECP256K1 curve order
SECP256K1_N = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
SECP256K1_HALF_N = SECP256K1_N // 2


def normalize_low_s(s: int) -> int:
    """Enforce canonical low-s rule (EIP-2) to prevent ECDSA signature malleability.

    In Ethereum, s must be in the lower half of the curve order: s <= secp256k1n / 2.
    If s > secp256k1n / 2, replace s with secp256k1n - s.
    """
    if s > SECP256K1_HALF_N:
        return SECP256K1_N - s
    return s


def der_to_eth_signature(
    der_signature: bytes,
    message_digest: bytes,
    expected_address: str,
) -> Tuple[str, int, int, int]:
    """Convert an ASN.1 DER-encoded ECDSA signature to an Ethereum recoverable signature.

    Args:
        der_signature: Raw ASN.1 DER bytes returned by AWS KMS Sign API.
        message_digest: 32-byte keccak256 hash that was signed.
        expected_address: Hex checksum address of the expected signing key.

    Returns:
        (signature_hex, v, r, s) where signature_hex is 0x-prefixed 65-byte hex string (r || s || v).

    Raises:
        ValueError: If DER decoding fails, or public key recovery does not match expected address.
    """
    if len(message_digest) != 32:
        raise ValueError(f"Message digest must be 32 bytes, got {len(message_digest)}")

    # 1. Parse ASN.1 DER sequence: SEQUENCE { INTEGER r, INTEGER s }
    try:
        r, s = decode_dss_signature(der_signature)
    except Exception as exc:
        raise ValueError(f"Failed to decode ASN.1 DER signature: {exc}") from exc

    # 2. Canonical low-s normalization (EIP-2)
    s = normalize_low_s(s)

    # 3. Determine recovery parameter v in {27, 28}
    expected_clean = to_checksum_address(expected_address)
    resolved_v: Optional[int] = None

    for candidate_v in (27, 28):
        try:
            recovered_addr = Account._recover_hash(message_digest, vrs=(candidate_v, r, s))
            if to_checksum_address(recovered_addr) == expected_clean:
                resolved_v = candidate_v
                break
        except Exception:
            continue

    if resolved_v is None:
        raise ValueError(
            f"Could not recover expected address '{expected_clean}' from DER signature. "
            f"Candidate addresses did not match."
        )

    # 4. Pack into 65-byte standard Ethereum format: r (32) || s (32) || v (1)
    sig_bytes = r.to_bytes(32, byteorder="big") + s.to_bytes(32, byteorder="big") + bytes([resolved_v])
    signature_hex = "0x" + sig_bytes.hex()

    return signature_hex, resolved_v, r, s


def eth_to_der_signature(r: int, s: int) -> bytes:
    """Encode integers r and s into an ASN.1 DER sequence (for testing and simulation)."""
    return encode_dss_signature(r, s)


class KmsSignerProvider:
    """AWS KMS EIP-712 signer implementing the SignerProvider protocol.

    Key Management Boundary:
    - This provider manages ONLY the automated Voucher Signer key.
    - It possesses single-purpose kms:Sign permissions on a dedicated SECP256K1 KMS key.
    - It NEVER holds Contract Owner permissions (which are reserved for a 3-of-5 Gnosis Safe).
    """

    def __init__(
        self,
        key_id: str,
        expected_address: str,
        contract_address: str,
        chain_id: int,
        kms_client: Optional[Any] = None,
    ):
        self.key_id = key_id
        self.expected_address = to_checksum_address(expected_address)
        self.contract_address = to_checksum_address(contract_address)
        self.chain_id = chain_id
        self.kms_client = kms_client

    def get_signer_address(self) -> str:
        return self.expected_address

    def compute_eip712_digest(
        self,
        campaign_id_hex: str,
        contributor_address: str,
        amount_wei: int,
        nonce_hex: str,
        deadline_timestamp: int,
    ) -> bytes:
        """Compute EIP-712 32-byte digest matching DatasetEscrow.sol specification."""
        domain_data = {
            "name": "DataMint DatasetEscrow",
            "version": "1",
            "chainId": self.chain_id,
            "verifyingContract": self.contract_address,
        }
        message_types = {
            "RewardAuthorization": [
                {"name": "campaignId", "type": "bytes32"},
                {"name": "contributor", "type": "address"},
                {"name": "amount", "type": "uint256"},
                {"name": "nonce", "type": "bytes32"},
                {"name": "deadline", "type": "uint256"},
            ],
        }
        message_data = {
            "campaignId": campaign_id_hex,
            "contributor": to_checksum_address(contributor_address),
            "amount": amount_wei,
            "nonce": nonce_hex,
            "deadline": deadline_timestamp,
        }

        signable = encode_typed_data(
            domain_data=domain_data,
            message_types=message_types,
            message_data=message_data,
        )
        # EIP-712 digest is keccak256(b"\x19\x01" + domain_separator + struct_hash)
        # Account._sign_hash computes signature on signable.body
        return signable.body

    def sign_reward_voucher(
        self,
        campaign_id_hex: str,
        contributor_address: str,
        amount_wei: int,
        nonce_hex: str,
        deadline_timestamp: int,
    ) -> Tuple[str, str]:
        """Sign reward voucher via AWS KMS and return (signature_hex, digest_hash_hex)."""
        digest_bytes = self.compute_eip712_digest(
            campaign_id_hex=campaign_id_hex,
            contributor_address=contributor_address,
            amount_wei=amount_wei,
            nonce_hex=nonce_hex,
            deadline_timestamp=deadline_timestamp,
        )

        if not self.kms_client:
            raise RuntimeError("AWS KMS client is not configured on this provider.")

        # AWS KMS Sign API call
        response = self.kms_client.sign(
            KeyId=self.key_id,
            Message=digest_bytes,
            MessageType="DIGEST",
            SigningAlgorithm="ECDSA_SHA_256",
        )
        der_signature = response["Signature"]

        # Convert DER to Ethereum (r, s, v)
        signature_hex, _, _, _ = der_to_eth_signature(
            der_signature=der_signature,
            message_digest=digest_bytes,
            expected_address=self.expected_address,
        )

        digest_hash_hex = "0x" + keccak(bytes.fromhex(signature_hex[2:])).hex()
        return signature_hex, digest_hash_hex
