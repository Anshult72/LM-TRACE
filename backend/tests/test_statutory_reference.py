import pytest
from fastapi.testclient import TestClient
from app.main import app

@pytest.fixture
def client():
    return TestClient(app)

@pytest.fixture
def inspector_auth_headers(client):
    login_resp = client.post("/api/auth/login", json={
        "email": "inspector@demo.gov.in",
        "password": "Inspector@123"
    })
    assert login_resp.status_code == 200, f"Login failed: {login_resp.text}"
    token = login_resp.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}

@pytest.fixture
def admin_auth_headers(client):
    login_resp = client.post("/api/auth/login", json={
        "email": "admin@demo.gov.in",
        "password": "Admin@123"
    })
    assert login_resp.status_code == 200, f"Admin login failed: {login_resp.text}"
    token = login_resp.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}

def test_statutory_summary(client, inspector_auth_headers):
    resp = client.get("/api/statutory/summary", headers=inspector_auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["total_documents"] >= 8
    assert data["active_rules"] >= 10
    assert data["statutory_families_count"] >= 4
    assert data["amendments_count"] >= 5
    assert data["future_effective_count"] >= 1
    assert data["mapped_to_engine_count"] >= 7

def test_statutory_documents_listing_and_filters(client, inspector_auth_headers):
    # 1. Full list
    resp = client.get("/api/statutory/documents", headers=inspector_auth_headers)
    assert resp.status_code == 200
    docs = resp.json()
    assert len(docs) >= 8

    # 2. Filter by document_type=ACT
    resp_act = client.get("/api/statutory/documents?doc_type=ACT", headers=inspector_auth_headers)
    assert resp_act.status_code == 200
    acts = resp_act.json()
    assert len(acts) >= 1
    assert any("The Legal Metrology Act, 2009" in d["title"] for d in acts)

    # 3. Filter by document_type=GAZETTE_AMENDMENT
    resp_amend = client.get("/api/statutory/documents?doc_type=GAZETTE_AMENDMENT", headers=inspector_auth_headers)
    assert resp_amend.status_code == 200
    amends = resp_amend.json()
    assert len(amends) >= 5
    assert any("779(E)" in (d.get("notification_number") or "") for d in amends)

    # 4. Search by keyword "Jan Vishwas"
    resp_search = client.get("/api/statutory/documents?search=Jan Vishwas", headers=inspector_auth_headers)
    assert resp_search.status_code == 200
    search_results = resp_search.json()
    assert len(search_results) >= 1
    assert "721(E)" in search_results[0]["notification_number"]

    # 5. Verify publication date is separate from effective date
    usp_amend = next(d for d in amends if "779(E)" in (d.get("notification_number") or ""))
    assert usp_amend["publication_date"].startswith("2021-11-02")
    assert usp_amend["effective_date"].startswith("2022-12-01")
    assert usp_amend["publication_date"] != usp_amend["effective_date"]

def test_statutory_future_effective_rules_not_active(client, inspector_auth_headers):
    resp = client.get("/api/statutory/rules?status=NOT_YET_EFFECTIVE", headers=inspector_auth_headers)
    assert resp.status_code == 200
    future_rules = resp.json()
    assert len(future_rules) >= 1
    future_qr = future_rules[0]
    assert future_qr["status"] == "NOT_YET_EFFECTIVE"
    assert future_qr["effective_from"].startswith("2027-07-01")
    # Verify it is not listed under ACTIVE
    resp_active = client.get("/api/statutory/rules?status=ACTIVE", headers=inspector_auth_headers)
    active_ids = [r["id"] for r in resp_active.json()]
    assert future_qr["id"] not in active_ids

def test_statutory_rules_listing_and_rule_engine_mappings(client, inspector_auth_headers):
    resp = client.get("/api/statutory/rules", headers=inspector_auth_headers)
    assert resp.status_code == 200
    rules = resp.json()
    assert len(rules) >= 12

    # Rule 6 mandatory declarations mapped to RULE-006
    rule6 = next((r for r in rules if r["rule_code"] == "STAT-RULE-6"), None)
    assert rule6 is not None
    assert rule6["is_automated"] is True
    assert rule6["mapped_rule_engine_code"] == "RULE-006"

    # Rule 7 Table-I mapped to RULE-007
    rule7 = next((r for r in rules if r["rule_code"] == "STAT-RULE-7"), None)
    assert rule7 is not None
    assert rule7["is_automated"] is True
    assert rule7["mapped_rule_engine_code"] == "RULE-007"

    # Rule 32 Penalties: unautomated legal provision
    rule32 = next((r for r in rules if r["rule_code"] == "STAT-RULE-32"), None)
    assert rule32 is not None
    assert rule32["is_automated"] is False
    assert rule32["mapped_rule_engine_code"] is None

def test_statutory_traceability_endpoint(client, inspector_auth_headers):
    # 1. Trace from automated Rule Engine code RULE-006
    resp = client.get("/api/statutory/traceability/RULE-006", headers=inspector_auth_headers)
    assert resp.status_code == 200
    trace = resp.json()
    assert trace["finding_or_rule_code"] == "RULE-006"
    assert trace["statutory_rule"]["rule_number"] == "Rule 6(1)"
    assert "Legal Metrology (Packaged Commodities) Rules, 2011" in trace["source_document"]["title"]
    assert len(trace["traceability_chain"]) >= 4

    # 2. Trace from RULE-007
    resp7 = client.get("/api/statutory/traceability/RULE-007", headers=inspector_auth_headers)
    assert resp7.status_code == 200
    trace7 = resp7.json()
    assert "Table-I" in trace7["statutory_rule"]["rule_number"]

def test_statutory_families(client, inspector_auth_headers):
    resp = client.get("/api/statutory/families", headers=inspector_auth_headers)
    assert resp.status_code == 200
    families = resp.json()
    assert len(families) >= 4
    family_names = [f["family_name"] for f in families]
    assert "Legal Metrology (Packaged Commodities) Rules" in family_names
    assert "The Legal Metrology Act, 2009" in family_names

def test_statutory_admin_rbac(client, inspector_auth_headers, admin_auth_headers):
    # Inspector (non-admin) should be forbidden (403) from creating statutory document
    doc_payload = {
        "title": "Unauthorized Test Document",
        "document_type": "OFFICIAL_ADVISORY",
        "source_url": "https://consumeraffairs.gov.in",
        "source_authority": "DCA Test"
    }
    resp_unauth = client.post("/api/statutory/documents", json=doc_payload, headers=inspector_auth_headers)
    assert resp_unauth.status_code == 403

    # Admin should succeed (201)
    admin_doc_payload = {
        "id": "doc-admin-test-advisory",
        "title": "Admin Registered Enforcement Advisory",
        "short_title": "Admin Advisory",
        "document_type": "OFFICIAL_ADVISORY",
        "authority": "Department of Consumer Affairs",
        "source_url": "https://consumeraffairs.gov.in/pages/advisories",
        "version": "1.0",
        "rule_family": "Legal Metrology (Packaged Commodities) Rules",
        "summary": "Official test advisory registered by regulatory administrator.",
        "status": "ACTIVE"
    }
    resp_admin = client.post("/api/statutory/documents", json=admin_doc_payload, headers=admin_auth_headers)
    assert resp_admin.status_code == 201
    created = resp_admin.json()
    assert created["id"] == "doc-admin-test-advisory"
