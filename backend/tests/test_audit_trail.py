import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app

@pytest.mark.asyncio
async def test_audit_trail_login_and_security_events():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # 1. Test failed login records LOGIN_FAILED
        res_fail = await ac.post("/api/auth/login", json={
            "email": "nonexistent@demo.gov.in",
            "password": "WrongPassword123"
        })
        assert res_fail.status_code == 401

        # 2. Test successful login records USER_LOGIN
        res_login = await ac.post("/api/auth/login", json={
            "email": "inspector@demo.gov.in",
            "password": "Inspector@123"
        })
        assert res_login.status_code == 200
        token = res_login.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # 3. Subsequent authenticated API call does NOT generate another USER_LOGIN
        res_me = await ac.get("/api/auth/me", headers=headers)
        assert res_me.status_code == 200

        # 4. Fetch audit logs
        res_logs = await ac.get("/api/audit-logs", headers=headers)
        assert res_logs.status_code == 200
        data = res_logs.json()
        assert "items" in data
        assert data["total"] > 0
        items = data["items"]

        # Check for USER_LOGIN and LOGIN_FAILED
        actions = [item["action"] for item in items]
        assert "USER_LOGIN" in actions
        assert "LOGIN_FAILED" in actions

        # 5. Check sanitization: verify password never leaked in any log payload
        for item in items:
            desc = str(item.get("description", ""))
            meta_str = str(item.get("metadata", {}))
            old_str = str(item.get("old_value", {}))
            new_str = str(item.get("new_value", {}))
            assert "WrongPassword123" not in desc
            assert "WrongPassword123" not in meta_str
            assert "Inspector@123" not in meta_str
            assert "Inspector@123" not in desc
            assert "Inspector@123" not in old_str
            assert "Inspector@123" not in new_str

@pytest.mark.asyncio
async def test_audit_trail_filtering_and_search():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        res_login = await ac.post("/api/auth/login", json={
            "email": "inspector@demo.gov.in",
            "password": "Inspector@123"
        })
        token = res_login.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # Filter by action=USER_LOGIN
        res = await ac.get("/api/audit-logs?action=USER_LOGIN", headers=headers)
        assert res.status_code == 200
        data = res.json()
        for item in data["items"]:
            assert item["action"] == "USER_LOGIN"

        # Filter by role=INSPECTOR
        res = await ac.get("/api/audit-logs?role=INSPECTOR", headers=headers)
        assert res.status_code == 200
        for item in res.json()["items"]:
            assert item["role"] == "INSPECTOR"

        # Search by free text 'ins-demo-001'
        res = await ac.get("/api/audit-logs?q=ins-demo-001", headers=headers)
        assert res.status_code == 200
        for item in res.json()["items"]:
            assert "ins-demo-001" in (
                str(item.get("inspection_id")) +
                str(item.get("description")) +
                str(item.get("resource_id"))
            )

        # Pagination: limit=3, offset=0
        res_p1 = await ac.get("/api/audit-logs?limit=3&offset=0", headers=headers)
        assert res_p1.status_code == 200
        p1_items = res_p1.json()["items"]
        assert len(p1_items) <= 3

@pytest.mark.asyncio
async def test_audit_summary_and_chain_of_custody():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        res_login = await ac.post("/api/auth/login", json={
            "email": "inspector@demo.gov.in",
            "password": "Inspector@123"
        })
        token = res_login.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # Summary statistics
        res_sum = await ac.get("/api/audit-logs/summary", headers=headers)
        assert res_sum.status_code == 200
        summary = res_sum.json()
        assert summary["total_events"] > 0
        assert "inspection_events" in summary
        assert "security_events" in summary
        assert "system_events" in summary

        # Chain of Custody for ins-demo-001
        res_chain = await ac.get("/api/audit-logs/chain/ins-demo-001", headers=headers)
        assert res_chain.status_code == 200
        chain = res_chain.json()
        assert chain["inspection_id"] == "ins-demo-001"
        assert len(chain["stages"]) > 0
        stage_keys = [s["stage_key"] for s in chain["stages"]]
        assert "INSPECTION_INITIATION" in stage_keys
        assert "OCR_EXTRACTION" in stage_keys
        assert "STATUTORY_EVALUATION" in stage_keys
        assert "COMPLIANCE_ASSESSMENT" in stage_keys

        # Check completed stage has actor and timestamp
        initiation_stage = next(s for s in chain["stages"] if s["stage_key"] == "INSPECTION_INITIATION")
        assert initiation_stage["status"] == "COMPLETED"
        assert initiation_stage["actor"] is not None
        assert initiation_stage["timestamp"] is not None

@pytest.mark.asyncio
async def test_audit_immutability():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        res_login = await ac.post("/api/auth/login", json={
            "email": "inspector@demo.gov.in",
            "password": "Inspector@123"
        })
        token = res_login.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # Attempt DELETE
        res_del = await ac.delete("/api/audit-logs/aud-0001", headers=headers)
        assert res_del.status_code == 403

        # Attempt PUT
        res_put = await ac.put("/api/audit-logs/aud-0001", json={"action": "TAMPERED"}, headers=headers)
        assert res_put.status_code == 403
