"""Integration tests for FastAPI endpoints."""

import pytest


@pytest.mark.asyncio
async def test_health_endpoints(async_client):
    """Test health and readiness probes."""
    res_live = await async_client.get("/api/v1/health/healthz")
    assert res_live.status_code == 200
    assert res_live.json() == {"status": "ok", "service": "datamint-api"}

    res_ready = await async_client.get("/api/v1/health/readyz")
    assert res_ready.status_code == 200
    assert res_ready.json()["status"] == "ready"


@pytest.mark.asyncio
async def test_auth_nonce_endpoint(async_client):
    """Test /api/v1/auth/nonce endpoint."""
    res = await async_client.post(
        "/api/v1/auth/nonce",
        json={
            "address": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
            "chain_id": 42220,
        },
    )
    assert res.status_code == 200
    data = res.json()
    assert "nonce" in data
    assert "message" in data
    assert "0x742d35cc6634c0532925a3b844bc454e4438f44e" in data["message"]


@pytest.mark.asyncio
async def test_marketplace_tasks_endpoint(async_client):
    """Test /api/v1/marketplace/tasks endpoint returns paginated response."""
    res = await async_client.get("/api/v1/marketplace/tasks")
    assert res.status_code == 200
    data = res.json()
    assert "items" in data
    assert "total" in data
    assert "page" in data
    assert data["page"] == 1
