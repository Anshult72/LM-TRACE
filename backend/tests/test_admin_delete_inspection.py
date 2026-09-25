import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app

@pytest.mark.asyncio
async def test_admin_only_delete_inspection_rbac_and_cleanup():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # 1. Login as Inspector
        insp_login = await client.post("/api/auth/login", json={
            "email": "inspector@demo.gov.in",
            "password": "Inspector@123"
        })
        assert insp_login.status_code == 200
        insp_token = insp_login.json()["access_token"]
        insp_headers = {"Authorization": f"Bearer {insp_token}"}

        # 2. Login as Supervisor
        sup_login = await client.post("/api/auth/login", json={
            "email": "supervisor@demo.gov.in",
            "password": "Supervisor@123"
        })
        assert sup_login.status_code == 200
        sup_token = sup_login.json()["access_token"]
        sup_headers = {"Authorization": f"Bearer {sup_token}"}

        # 3. Login as Admin
        admin_login = await client.post("/api/auth/login", json={
            "email": "admin@demo.gov.in",
            "password": "Admin@123"
        })
        assert admin_login.status_code == 200
        admin_token = admin_login.json()["access_token"]
        admin_headers = {"Authorization": f"Bearer {admin_token}"}

        # 4. Create an inspection as Inspector
        create_res = await client.post("/api/inspections", headers=insp_headers, json={
            "location": "Lucknow Retail Hub",
            "seller_name": "Test Seller Ltd",
            "inspection_type": "PHYSICAL",
            "product_category": "Packaged Food",
            "notes": "Testing RBAC deletion controls"
        })
        assert create_res.status_code == 200
        inspection_id = create_res.json()["id"]
        assert inspection_id is not None

        # 5. UNAUTHENTICATED REQUEST: Delete must be rejected (401)
        unauth_del = await client.delete(f"/api/inspections/{inspection_id}")
        assert unauth_del.status_code == 401

        # 6. INSPECTOR REQUEST: Delete must return 403 Forbidden
        insp_del = await client.delete(f"/api/inspections/{inspection_id}", headers=insp_headers)
        assert insp_del.status_code == 403
        assert insp_del.json()["detail"]["code"] == "FORBIDDEN"

        # 7. INSPECTOR FORGED ROLE IN BODY: Must still return 403 Forbidden (backend ignores untrusted payload)
        forged_del = await client.request(
            "DELETE",
            f"/api/inspections/{inspection_id}",
            headers=insp_headers,
            json={"role": "ADMIN"}
        )
        assert forged_del.status_code == 403

        # 8. SUPERVISOR REQUEST: Delete must return 403 Forbidden
        sup_del = await client.delete(f"/api/inspections/{inspection_id}", headers=sup_headers)
        assert sup_del.status_code == 403
        assert sup_del.json()["detail"]["code"] == "FORBIDDEN"

        # Verify inspection is UNTOUCHED
        verify_res = await client.get(f"/api/inspections/{inspection_id}", headers=insp_headers)
        assert verify_res.status_code == 200

        # 9. ADMIN REQUEST ON NON-EXISTENT INSPECTION: 404 Not Found
        non_existent_del = await client.delete("/api/inspections/ins-does-not-exist", headers=admin_headers)
        assert non_existent_del.status_code == 404

        # 10. ADMIN REQUEST ON VALID INSPECTION: 200 OK
        admin_del = await client.delete(f"/api/inspections/{inspection_id}", headers=admin_headers)
        assert admin_del.status_code == 200
        del_data = admin_del.json()
        assert del_data["success"] is True
        assert del_data["deleted_id"] == inspection_id

        # 11. VERIFY INSPECTION IS GONE
        after_get = await client.get(f"/api/inspections/{inspection_id}", headers=admin_headers)
        assert after_get.status_code == 404

        # Verify not present in list
        list_res = await client.get("/api/inspections", headers=admin_headers)
        assert list_res.status_code == 200
        assert not any(item["id"] == inspection_id for item in list_res.json())

        # 12. VERIFY AUDIT LOG RECORD
        audit_res = await client.get(f"/api/audit-logs?inspection_id={inspection_id}", headers=admin_headers)
        assert audit_res.status_code == 200
        logs = audit_res.json()
        items = logs.get("items", []) if isinstance(logs, dict) else logs
        assert any(item.get("action") == "INSPECTION_DELETED" for item in items)
