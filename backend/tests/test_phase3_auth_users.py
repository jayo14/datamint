"""Phase 3 tests for User Authentication, Session Management, and Profile endpoints."""

import pytest
from sqlalchemy import select

from app.core.security import verify_password
from app.models.enums import CapabilityType
from app.models.identity import User


@pytest.mark.asyncio
async def test_user_registration_and_login_flow(async_client, db_session):
    """Verify registration, password hashing, dual capability assignment, and login."""
    # 1. Register new user
    register_payload = {
        "email": "alice@datamint.ai",
        "password": "SecurePassword123!",
        "display_name": "Alice In Chains",
    }
    res = await async_client.post("/api/v1/auth/register", json=register_payload)
    assert res.status_code == 201
    reg_data = res.json()
    assert "access_token" in reg_data
    assert "refresh_token" in reg_data
    assert reg_data["user"]["email"] == "alice@datamint.ai"
    assert CapabilityType.CONTRIBUTOR.value in reg_data["user"]["capabilities"]
    assert CapabilityType.CREATOR.value in reg_data["user"]["capabilities"]

    # 2. Verify database state & password hashing
    query = select(User).where(User.email == "alice@datamint.ai")
    user = (await db_session.execute(query)).scalar_one_or_none()
    assert user is not None
    assert user.hashed_password != "SecurePassword123!"
    assert verify_password("SecurePassword123!", user.hashed_password) is True

    # 3. Successful Login
    login_payload = {
        "email": "alice@datamint.ai",
        "password": "SecurePassword123!",
    }
    res_login = await async_client.post("/api/v1/auth/login", json=login_payload)
    assert res_login.status_code == 200
    login_data = res_login.json()
    assert "access_token" in login_data
    assert "refresh_token" in login_data

    # 4. Invalid Password Login
    bad_login = {
        "email": "alice@datamint.ai",
        "password": "WrongPassword999!",
    }
    res_bad = await async_client.post("/api/v1/auth/login", json=bad_login)
    assert res_bad.status_code == 400


@pytest.mark.asyncio
async def test_duplicate_email_registration_rejected(async_client):
    """Verify that registering an already registered email is rejected."""
    payload = {
        "email": "bob@datamint.ai",
        "password": "StrongPassword456!",
        "display_name": "Bob The Builder",
    }
    res1 = await async_client.post("/api/v1/auth/register", json=payload)
    assert res1.status_code == 201

    res2 = await async_client.post("/api/v1/auth/register", json=payload)
    assert res2.status_code == 400
    assert "already exists" in res2.json()["detail"]


@pytest.mark.asyncio
async def test_session_refresh_token_rotation(async_client):
    """Verify session refresh and refresh token rotation."""
    register_payload = {
        "email": "charlie@datamint.ai",
        "password": "PasswordCharlie789!",
    }
    res_reg = await async_client.post("/api/v1/auth/register", json=register_payload)
    assert res_reg.status_code == 201
    refresh_token_1 = res_reg.json()["refresh_token"]

    # Refresh session
    res_ref = await async_client.post(
        "/api/v1/auth/refresh", json={"refresh_token": refresh_token_1}
    )
    assert res_ref.status_code == 200
    ref_data = res_ref.json()
    refresh_token_2 = ref_data["refresh_token"]
    assert refresh_token_2 != refresh_token_1

    # Attempting to reuse old refresh token should fail
    res_reuse = await async_client.post(
        "/api/v1/auth/refresh", json={"refresh_token": refresh_token_1}
    )
    assert res_reuse.status_code == 400


@pytest.mark.asyncio
async def test_user_profile_management(async_client):
    """Verify getting and updating profile details."""
    register_payload = {
        "email": "dana@datamint.ai",
        "password": "DanaSecurePass321!",
        "display_name": "Dana Initial",
    }
    res_reg = await async_client.post("/api/v1/auth/register", json=register_payload)
    token = res_reg.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Fetch profile
    res_me = await async_client.get("/api/v1/users/me", headers=headers)
    assert res_me.status_code == 200
    me_data = res_me.json()
    assert me_data["email"] == "dana@datamint.ai"
    assert me_data["profile"]["display_name"] == "Dana Initial"

    # Update profile
    update_payload = {
        "display_name": "Dana Updated",
        "bio": "Audio and speech dataset specialist.",
        "avatar_url": "https://datamint.ai/avatars/dana.png",
    }
    res_update = await async_client.put(
        "/api/v1/users/me/profile", json=update_payload, headers=headers
    )
    assert res_update.status_code == 200
    up_data = res_update.json()
    assert up_data["display_name"] == "Dana Updated"
    assert up_data["bio"] == "Audio and speech dataset specialist."
    assert up_data["avatar_url"] == "https://datamint.ai/avatars/dana.png"
