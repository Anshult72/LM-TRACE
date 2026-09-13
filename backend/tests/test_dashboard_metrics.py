import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app

@pytest.mark.asyncio
async def test_dashboard_summary_endpoint():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # 1. Login
        login_res = await ac.post("/api/auth/login", json={
            "email": "inspector@demo.gov.in",
            "password": "Inspector@123"
        })
        assert login_res.status_code == 200
        token = login_res.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # 2. Query dashboard summary
        res = await ac.get("/api/dashboard/summary", headers=headers)
        assert res.status_code == 200
        data = res.json()

        # Check required data keys
        assert "total_audited" in data
        assert "compliance_rate" in data
        assert "violations_flagged" in data
        assert "pending_review" in data
        assert "commodity_spread" in data
        assert "rule_health" in data
        assert "action_required" in data
        assert "recent_inspections" in data
        assert "user" in data

        # Check user context
        user = data["user"]
        assert user["role"] == "INSPECTOR"
        assert isinstance(user["full_name"], str)
        assert len(user["full_name"]) > 0

        # Assert types
        assert isinstance(data["total_audited"], int)
        assert isinstance(data["violations_flagged"], int)
        assert isinstance(data["pending_review"], int)
        assert isinstance(data["commodity_spread"], list)
        assert isinstance(data["rule_health"], list)

        # If total_audited is 0, compliance_rate must be None
        if data["total_audited"] == 0:
            assert data["compliance_rate"] is None
            assert data["compliance_rate_subtitle"] == "No finalized inspections yet"
        else:
            assert isinstance(data["compliance_rate"], (int, float))
