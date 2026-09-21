import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app

@pytest.mark.asyncio
async def test_rbac_and_logout_lifecycle():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # 1. Login as Inspector
        insp_login = await client.post("/api/auth/login", json={
            "email": "inspector@demo.gov.in",
            "password": "Inspector@123"
        })
        assert insp_login.status_code == 200
        insp_data = insp_login.json()
        assert insp_data["user"]["role"] == "INSPECTOR"
        insp_token = insp_data["access_token"]
        insp_headers = {"Authorization": f"Bearer {insp_token}"}

        # 2. Login as Supervisor
        sup_login = await client.post("/api/auth/login", json={
            "email": "supervisor@demo.gov.in",
            "password": "Supervisor@123"
        })
        assert sup_login.status_code == 200
        sup_data = sup_login.json()
        assert sup_data["user"]["role"] == "SUPERVISOR"
        sup_token = sup_data["access_token"]
        sup_headers = {"Authorization": f"Bearer {sup_token}"}

        # 3. Login as Admin
        admin_login = await client.post("/api/auth/login", json={
            "email": "admin@demo.gov.in",
            "password": "Admin@123"
        })
        assert admin_login.status_code == 200
        admin_data = admin_login.json()
        assert admin_data["user"]["role"] == "ADMIN"
        admin_token = admin_data["access_token"]
        admin_headers = {"Authorization": f"Bearer {admin_token}"}

        # --- RBAC TESTS: INSPECTOR ---
        # Inspector CANNOT access Supervisor Dashboard (403)
        res = await client.get("/api/dashboard/supervisor", headers=insp_headers)
        assert res.status_code == 403

        # Inspector CANNOT access Admin Dashboard (403)
        res = await client.get("/api/dashboard/admin", headers=insp_headers)
        assert res.status_code == 403

        # Inspector CANNOT access System Settings (403)
        res = await client.get("/api/settings", headers=insp_headers)
        assert res.status_code == 403

        # --- RBAC TESTS: SUPERVISOR ---
        # Supervisor CAN access Supervisor Dashboard (200)
        res = await client.get("/api/dashboard/supervisor", headers=sup_headers)
        assert res.status_code == 200

        # Supervisor CAN access Audit Logs (200)
        res = await client.get("/api/audit-logs", headers=sup_headers)
        assert res.status_code == 200

        # Supervisor CANNOT access Admin Dashboard (403)
        res = await client.get("/api/dashboard/admin", headers=sup_headers)
        assert res.status_code == 403

        # Supervisor CANNOT access System Settings (403)
        res = await client.get("/api/settings", headers=sup_headers)
        assert res.status_code == 403

        # --- RBAC TESTS: ADMIN ---
        # Admin CAN access Supervisor Dashboard (200)
        res = await client.get("/api/dashboard/supervisor", headers=admin_headers)
        assert res.status_code == 200

        # Admin CAN access Admin Dashboard (200)
        res = await client.get("/api/dashboard/admin", headers=admin_headers)
        assert res.status_code == 200

        # Admin CAN access Audit Logs (200)
        res = await client.get("/api/audit-logs", headers=admin_headers)
        assert res.status_code == 200

        # Admin CAN access System Settings (200)
        res = await client.get("/api/settings", headers=admin_headers)
        assert res.status_code == 200

        # --- LOGOUT TESTS ---
        # Calling logout without token -> 401
        res = await client.post("/api/auth/logout")
        assert res.status_code == 401

        # Calling logout with token -> 200 & success message
        res = await client.post("/api/auth/logout", headers=insp_headers)
        assert res.status_code == 200
        assert res.json()["status"] == "LOGGED_OUT"

        # Verify that USER_LOGOUT audit event was recorded
        logs_res = await client.get("/api/audit-logs?action=USER_LOGOUT", headers=admin_headers)
        assert logs_res.status_code == 200
        logs = logs_res.json()
        items = logs.get("items", []) if isinstance(logs, dict) else logs
        assert any(item.get("action") == "USER_LOGOUT" for item in items)
