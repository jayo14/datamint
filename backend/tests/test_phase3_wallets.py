"""Phase 3 tests for Cryptographic Wallet Ownership Verification and Management."""

import pytest
from eth_account import Account
from eth_account.messages import encode_defunct


@pytest.mark.asyncio
async def test_wallet_linking_and_primary_assignment(async_client):
    """Verify wallet challenge generation, signature verification, and primary assignment."""
    # 1. Register base user
    reg_res = await async_client.post(
        "/api/v1/auth/register",
        json={"email": "wallet_user@datamint.ai", "password": "PasswordWallet999!"},
    )
    assert reg_res.status_code == 201
    token = reg_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Generate keypair for wallet 1
    acc1 = Account.create()
    addr1 = acc1.address.lower()

    # Request challenge for linking
    chal_res = await async_client.post(
        "/api/v1/wallets/challenge",
        json={"address": addr1, "chain_id": 42220},
        headers=headers,
    )
    assert chal_res.status_code == 200
    chal_data = chal_res.json()
    assert chal_data["action"] == "link_wallet"

    # Sign challenge
    signable = encode_defunct(text=chal_data["message"])
    sig = Account.sign_message(signable, private_key=acc1.key).signature.hex()
    if not sig.startswith("0x"):
        sig = "0x" + sig

    # Link wallet
    link_res = await async_client.post(
        "/api/v1/wallets/link",
        json={"message": chal_data["message"], "signature": sig},
        headers=headers,
    )
    assert link_res.status_code == 201
    w1_data = link_res.json()
    assert w1_data["address"].lower() == addr1
    assert w1_data["is_primary"] is True  # First wallet defaults to primary

    # 3. Link a second wallet
    acc2 = Account.create()
    addr2 = acc2.address.lower()

    chal2_res = await async_client.post(
        "/api/v1/wallets/challenge",
        json={"address": addr2, "chain_id": 42220},
        headers=headers,
    )
    chal2_data = chal2_res.json()
    sig2 = Account.sign_message(
        encode_defunct(text=chal2_data["message"]), private_key=acc2.key
    ).signature.hex()
    if not sig2.startswith("0x"):
        sig2 = "0x" + sig2

    link2_res = await async_client.post(
        "/api/v1/wallets/link",
        json={"message": chal2_data["message"], "signature": sig2},
        headers=headers,
    )
    assert link2_res.status_code == 201
    assert link2_res.json()["is_primary"] is False

    # 4. Set wallet 2 as primary
    prim_res = await async_client.put(
        f"/api/v1/wallets/{addr2}/primary",
        headers=headers,
    )
    assert prim_res.status_code == 200
    assert prim_res.json()["is_primary"] is True

    # 5. List wallets
    list_res = await async_client.get("/api/v1/wallets/", headers=headers)
    assert list_res.status_code == 200
    wallets = list_res.json()
    assert len(wallets) == 2
    assert wallets[0]["address"].lower() == addr2
    assert wallets[0]["is_primary"] is True

    # 6. Unlink wallet 1
    del_res = await async_client.delete(f"/api/v1/wallets/{addr1}", headers=headers)
    assert del_res.status_code == 200

    list_res_after = await async_client.get("/api/v1/wallets/", headers=headers)
    assert len(list_res_after.json()) == 1


@pytest.mark.asyncio
async def test_prevent_reassigning_wallet_across_accounts(async_client):
    """Verify that a wallet linked to User A cannot be claimed by User B."""
    # Register User A and link wallet
    res_a = await async_client.post(
        "/api/v1/auth/register",
        json={"email": "usera@datamint.ai", "password": "PasswordUserA123!"},
    )
    token_a = res_a.json()["access_token"]
    headers_a = {"Authorization": f"Bearer {token_a}"}

    acc = Account.create()
    addr = acc.address.lower()

    chal_res = await async_client.post(
        "/api/v1/wallets/challenge", json={"address": addr}, headers=headers_a
    )
    msg = chal_res.json()["message"]
    sig = Account.sign_message(encode_defunct(text=msg), private_key=acc.key).signature.hex()
    if not sig.startswith("0x"):
        sig = "0x" + sig

    await async_client.post(
        "/api/v1/wallets/link", json={"message": msg, "signature": sig}, headers=headers_a
    )

    # Register User B and attempt to link the same wallet
    res_b = await async_client.post(
        "/api/v1/auth/register",
        json={"email": "userb@datamint.ai", "password": "PasswordUserB123!"},
    )
    token_b = res_b.json()["access_token"]
    headers_b = {"Authorization": f"Bearer {token_b}"}

    chal_b_res = await async_client.post(
        "/api/v1/wallets/challenge", json={"address": addr}, headers=headers_b
    )
    msg_b = chal_b_res.json()["message"]
    sig_b = Account.sign_message(encode_defunct(text=msg_b), private_key=acc.key).signature.hex()
    if not sig_b.startswith("0x"):
        sig_b = "0x" + sig_b

    link_b_res = await async_client.post(
        "/api/v1/wallets/link", json={"message": msg_b, "signature": sig_b}, headers=headers_b
    )
    assert link_b_res.status_code == 400
    assert "already linked to another DataMint account" in link_b_res.json()["detail"]


@pytest.mark.asyncio
async def test_prevent_unlinking_sole_auth_method(async_client):
    """Verify that a SIWE-only user cannot unlink their sole authentication wallet."""
    acc = Account.create()
    addr = acc.address.lower()

    # Authenticate via SIWE (creates account with no password)
    nonce_res = await async_client.post("/api/v1/auth/nonce", json={"address": addr})
    msg = nonce_res.json()["message"]
    sig = Account.sign_message(encode_defunct(text=msg), private_key=acc.key).signature.hex()
    if not sig.startswith("0x"):
        sig = "0x" + sig

    auth_res = await async_client.post(
        "/api/v1/auth/verify", json={"message": msg, "signature": sig}
    )
    assert auth_res.status_code == 200
    token = auth_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Attempt to unlink the sole wallet
    del_res = await async_client.delete(f"/api/v1/wallets/{addr}", headers=headers)
    assert del_res.status_code == 400
    assert "Cannot unlink your only authentication method" in del_res.json()["detail"]
