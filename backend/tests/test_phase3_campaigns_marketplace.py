"""Phase 3 tests for Campaign Drafts, Escrow Parameters, and Marketplace Discovery."""

from decimal import Decimal

import pytest

from app.models.enums import DataType
from app.services.campaign_service import CampaignService


@pytest.mark.asyncio
async def test_campaign_draft_lifecycle_and_funding_params(async_client):
    """Verify draft creation, editing, immutability, and on-chain funding parameter generation."""
    # 1. Register creator
    reg_res = await async_client.post(
        "/api/v1/auth/register",
        json={"email": "creator_drafts@datamint.ai", "password": "PasswordCreator123!"},
    )
    token = reg_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Create campaign draft
    create_payload = {
        "title": "Swahili Dialect Audio Dataset",
        "description": "Voice recordings of natural conversations in coastal Swahili dialects",
        "data_type": "VOICE",
        "target_submissions": 50,
        "reward_per_submission": "2.50",
        "category": "Speech Recognition",
        "tags": ["swahili", "african-languages", "nlp"],
        "instructions": "Record 15-30 seconds of conversational audio in a quiet room.",
        "eligibility_criteria": {
            "native_speaker": True,
            "min_age": 18,
            "supported_regions": ["KE", "TZ"],
        },
    }
    create_res = await async_client.post("/api/v1/campaigns/", json=create_payload, headers=headers)
    assert create_res.status_code == 201
    campaign = create_res.json()
    campaign_id = campaign["id"]
    assert campaign["status"] == "DRAFT"
    assert campaign["category"] == "Speech Recognition"
    assert "swahili" in campaign["tags"]

    # 3. Update draft
    update_payload = {
        "title": "Swahili & Sheng Dialect Audio Dataset",
        "tags": ["swahili", "sheng", "african-languages", "nlp"],
        "instructions": "Record 20-30 seconds of conversational speech.",
    }
    up_res = await async_client.put(
        f"/api/v1/campaigns/{campaign_id}", json=update_payload, headers=headers
    )
    assert up_res.status_code == 200
    assert up_res.json()["title"] == "Swahili & Sheng Dialect Audio Dataset"
    assert len(up_res.json()["tags"]) == 4

    # 4. Submit for funding
    funding_res = await async_client.post(
        f"/api/v1/campaigns/{campaign_id}/submit-funding", headers=headers
    )
    assert funding_res.status_code == 200
    funding_data = funding_res.json()
    assert funding_data["onchain_campaign_id"].startswith("0x")
    assert len(funding_data["onchain_campaign_id"]) == 66  # 0x + 64 hex chars
    assert funding_data["target_submissions"] == 50
    # 2.50 cUSD = 2.5 * 10^18 wei = 2500000000000000000
    assert funding_data["reward_per_submission_wei"] == "2500000000000000000"
    # Total budget = 50 * 2.5 = 125 cUSD = 125 * 10^18 wei = 125000000000000000000
    assert funding_data["required_budget_wei"] == "125000000000000000000"

    # 5. Immutability check: cannot edit after transitioning to PENDING_FUNDING
    blocked_up = await async_client.put(
        f"/api/v1/campaigns/{campaign_id}",
        json={"title": "Should Fail"},
        headers=headers,
    )
    assert blocked_up.status_code == 400
    assert "immutable" in blocked_up.json()["detail"].lower()


@pytest.mark.asyncio
async def test_marketplace_search_and_filtering(async_client, db_session):
    """Verify searching and multi-criteria filtering on active marketplace tasks."""
    campaign_service = CampaignService(db_session)

    # Register creator
    reg_res = await async_client.post(
        "/api/v1/auth/register",
        json={"email": "market_creator@datamint.ai", "password": "PasswordMarket123!"},
    )
    creator_id = reg_res.json()["user"]["id"]

    # Seed 3 active campaigns with different properties
    c1 = await campaign_service.create_campaign(
        creator_id=creator_id,
        data={
            "title": "Medical Prescription Handwriting Images",
            "description": "High resolution photos of handwritten prescriptions",
            "data_type": DataType.IMAGE,
            "target_submissions": 100,
            "reward_per_submission": Decimal("5.00"),
            "category": "Healthcare",
        },
    )
    c1.escrow.total_funded = Decimal("500.00")
    c1.escrow.total_available = Decimal("500.00")
    await campaign_service.activate_campaign(c1.id, "0x" + "1" * 64)

    c2 = await campaign_service.create_campaign(
        creator_id=creator_id,
        data={
            "title": "Autonomous Vehicle Road Signs",
            "description": "Street level photos of damaged or occluded road signs",
            "data_type": DataType.IMAGE,
            "target_submissions": 50,
            "reward_per_submission": Decimal("1.50"),
            "category": "Robotics",
        },
    )
    c2.escrow.total_funded = Decimal("75.00")
    c2.escrow.total_available = Decimal("75.00")
    await campaign_service.activate_campaign(c2.id, "0x" + "2" * 64)

    c3 = await campaign_service.create_campaign(
        creator_id=creator_id,
        data={
            "title": "Audio Accent Transcripts",
            "description": "Short recordings of regional English accents",
            "data_type": DataType.VOICE,
            "target_submissions": 20,
            "reward_per_submission": Decimal("0.75"),
            "category": "Audio & Speech",
        },
    )
    c3.escrow.total_funded = Decimal("15.00")
    c3.escrow.total_available = Decimal("15.00")
    await campaign_service.activate_campaign(c3.id, "0x" + "3" * 64)
    await db_session.commit()

    # 1. Search keyword "Prescription"
    res_search = await async_client.get("/api/v1/marketplace/tasks?search=prescription")
    assert res_search.status_code == 200
    assert res_search.json()["total"] == 1
    assert "Prescription" in res_search.json()["items"][0]["title"]

    # 2. Filter by data_type "IMAGE"
    res_type = await async_client.get("/api/v1/marketplace/tasks?data_type=IMAGE")
    assert res_type.status_code == 200
    assert res_type.json()["total"] == 2

    # 3. Filter by category "Robotics"
    res_cat = await async_client.get("/api/v1/marketplace/tasks?category=Robotics")
    assert res_cat.status_code == 200
    assert res_cat.json()["total"] == 1
    assert res_cat.json()["items"][0]["category"] == "Robotics"

    # 4. Filter by reward bounds [1.00, 3.00]
    res_reward = await async_client.get("/api/v1/marketplace/tasks?min_reward=1.00&max_reward=3.00")
    assert res_reward.status_code == 200
    assert res_reward.json()["total"] == 1
    assert Decimal(str(res_reward.json()["items"][0]["reward_per_submission"])) == Decimal("1.50")

    # 5. Sorting by reward_high
    res_sort = await async_client.get("/api/v1/marketplace/tasks?sort_by=reward_high")
    assert res_sort.status_code == 200
    rewards = [Decimal(str(item["reward_per_submission"])) for item in res_sort.json()["items"]]
    assert rewards == sorted(rewards, reverse=True)
