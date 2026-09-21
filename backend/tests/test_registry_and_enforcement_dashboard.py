import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app
from app.services.analytics.compliance_analytics import classify_inspection, summarize_inspections


def test_finalized_case_without_checks_is_not_falsely_compliant():
    result = classify_inspection({"status": "FINALIZED", "score": 99.0, "checks": [], "violations": []})
    assert result["outcome"] == "UNVERIFIED"
    assert result["enforcement_ready"] is False


def test_outcome_uses_checks_and_active_findings_not_score_thresholds():
    compliant = classify_inspection({"status": "FINALIZED", "score": 12.0, "checks": [{"result": "PASS"}]})
    violation = classify_inspection({"status": "FINALIZED", "score": 100.0, "checks": [{"result": "POTENTIAL_VIOLATION"}]})
    rejected = classify_inspection({"status": "FINALIZED", "checks": [{"result": "PASS"}], "violations": [{"status": "REJECTED"}]})
    assert compliant["outcome"] == "COMPLIANT"
    assert violation["outcome"] == "POTENTIAL_VIOLATION"
    assert rejected["outcome"] == "COMPLIANT"


def test_rule_and_category_metrics_are_derived_from_persisted_checks():
    summary = summarize_inspections([
        {"product_category": "Food", "checks": [{"rule_code": "RULE-006", "result": "PASS"}]},
        {"product_category": "Food", "checks": [{"rule_code": "RULE-006", "result": "UNVERIFIED"}]},
    ])
    assert summary["rule_stats"]["RULE-006"] == {"total": 2, "pass": 1, "failed": 0, "unresolved": 1}
    assert summary["category_stats"]["Food"]["total"] == 2


@pytest.mark.asyncio
async def test_dashboard_and_registry_expose_operational_drilldowns():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        login = await client.post("/api/auth/login", json={"email": "inspector@demo.gov.in", "password": "Inspector@123"})
        headers = {"Authorization": f"Bearer {login.json()['access_token']}"}

        dashboard = await client.get("/api/dashboard/summary?outcome=UNVERIFIED", headers=headers)
        assert dashboard.status_code == 200
        data = dashboard.json()
        assert "enforcement_queue" in data
        assert "violation_summary" in data
        assert "monthly_trend" in data
        assert data["filters"]["outcome"] == "UNVERIFIED"
        assert all(item["compliance_outcome"] == "UNVERIFIED" for item in data["recent_inspections"])

        registry = await client.get("/api/products/registry/summary", headers=headers)
        assert registry.status_code == 200
        registry_data = registry.json()
        assert registry_data["inspection_count"] >= registry_data["linked_inspection_count"]
        assert "compliance_outcomes" in registry_data
