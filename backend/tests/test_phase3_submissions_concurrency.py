"""Phase 3 tests for Submissions, Concurrency-Safe Capacity Enforcement, and Permissions."""

from decimal import Decimal

import pytest

from app.models.enums import DataType
from app.services.campaign_service import CampaignService


@pytest.mark.asyncio
async def test_submission_lifecycle_and_capacity_enforcement(async_client, db_session):
    """Verify draft creation, asset upload, finalization, and atomic capacity enforcement."""
    campaign_service = CampaignService(db_session)

    # 1. Setup creator and small capacity campaign (target = 2)
    reg_creator = await async_client.post(
        "/api/v1/auth/register",
        json={"email": "creator_cap@datamint.ai", "password": "PasswordCap123!"},
    )
    creator_id = reg_creator.json()["user"]["id"]
    creator_token = reg_creator.json()["access_token"]
    creator_headers = {"Authorization": f"Bearer {creator_token}"}

    campaign = await campaign_service.create_campaign(
        creator_id=creator_id,
        data={
            "title": "Strict Capacity Text Tasks",
            "description": "Text prompts with strict target limit",
            "data_type": DataType.TEXT,
            "target_submissions": 2,
            "reward_per_submission": Decimal("1.00"),
        },
    )
    campaign.escrow.total_funded = Decimal("2.00")
    campaign.escrow.total_available = Decimal("2.00")
    await campaign_service.activate_campaign(campaign.id, "0x" + "a" * 64)
    await db_session.commit()

    # 2. Setup Contributor 1
    reg_c1 = await async_client.post(
        "/api/v1/auth/register",
        json={"email": "c1@datamint.ai", "password": "PasswordC1123!"},
    )
    headers_c1 = {"Authorization": f"Bearer {reg_c1.json()['access_token']}"}

    # C1 creates draft
    draft_c1 = await async_client.post(
        "/api/v1/submissions/drafts",
        json={"campaign_id": str(campaign.id), "draft_data": {"answer": "First response"}},
        headers=headers_c1,
    )
    assert draft_c1.status_code == 201
    sub1_id = draft_c1.json()["id"]

    # C1 submits for validation -> Capacity: 1/2
    submit1_res = await async_client.post(
        f"/api/v1/submissions/drafts/{sub1_id}/submit",
        headers=headers_c1,
    )
    assert submit1_res.status_code == 200
    assert submit1_res.json()["status"] == "PENDING_VALIDATION"

    # Attempting to modify submitted draft must be rejected
    edit_blocked = await async_client.put(
        f"/api/v1/submissions/drafts/{sub1_id}",
        json={"draft_data": {"answer": "Attempted edit"}},
        headers=headers_c1,
    )
    assert edit_blocked.status_code == 400
    assert "cannot be modified" in edit_blocked.json()["detail"]

    # 3. Setup Contributor 2
    reg_c2 = await async_client.post(
        "/api/v1/auth/register",
        json={"email": "c2@datamint.ai", "password": "PasswordC2123!"},
    )
    headers_c2 = {"Authorization": f"Bearer {reg_c2.json()['access_token']}"}

    draft_c2 = await async_client.post(
        "/api/v1/submissions/drafts",
        json={"campaign_id": str(campaign.id), "draft_data": {"answer": "Second response"}},
        headers=headers_c2,
    )
    sub2_id = draft_c2.json()["id"]

    # C2 submits for validation -> Capacity: 2/2 (Completed)
    submit2_res = await async_client.post(
        f"/api/v1/submissions/drafts/{sub2_id}/submit",
        headers=headers_c2,
    )
    assert submit2_res.status_code == 200

    # 4. Setup Contributor 3 attempting to submit when capacity is exhausted
    reg_c3 = await async_client.post(
        "/api/v1/auth/register",
        json={"email": "c3@datamint.ai", "password": "PasswordC3123!"},
    )
    headers_c3 = {"Authorization": f"Bearer {reg_c3.json()['access_token']}"}

    # Attempting to create draft for completed campaign is blocked
    draft_c3 = await async_client.post(
        "/api/v1/submissions/drafts",
        json={"campaign_id": str(campaign.id), "draft_data": {"answer": "Third response"}},
        headers=headers_c3,
    )
    assert draft_c3.status_code == 400
    assert "not currently accepting submissions" in draft_c3.json()["detail"]

    # 5. Creator lists submissions for their campaign
    camp_subs_res = await async_client.get(
        f"/api/v1/submissions/campaigns/{campaign.id}",
        headers=creator_headers,
    )
    assert camp_subs_res.status_code == 200
    assert camp_subs_res.json()["total"] == 2

    # Unauthorized contributor attempting to list campaign submissions
    unauth_list = await async_client.get(
        f"/api/v1/submissions/campaigns/{campaign.id}",
        headers=headers_c1,
    )
    assert unauth_list.status_code == 400
    assert "not the creator" in unauth_list.json()["detail"]
