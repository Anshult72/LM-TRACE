from datetime import datetime
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, Query

from app.core.security import get_current_user_payload, require_role
from app.repositories import get_repository
from app.services.analytics.compliance_analytics import classify_inspection, summarize_inspections

router = APIRouter(prefix="/api/dashboard", tags=["Dashboard"])


def _date_value(item: Dict[str, Any]) -> str:
    return str(item.get("inspection_date") or item.get("created_at") or "")


def _filter_cases(inspections: List[Dict[str, Any]], date_from: Optional[str], date_to: Optional[str], category: Optional[str], outcome: Optional[str]) -> List[Dict[str, Any]]:
    filtered = []
    for item in inspections:
        date = _date_value(item)[:10]
        if isinstance(date_from, str) and date and date < date_from:
            continue
        if isinstance(date_to, str) and date and date > date_to:
            continue
        item_category = str(item.get("product_category") or item.get("category") or "Uncategorised")
        if isinstance(category, str) and category.lower() not in item_category.lower():
            continue
        assessment = classify_inspection(item)
        if isinstance(outcome, str) and assessment["outcome"] != outcome.upper():
            continue
        enriched = dict(item)
        enriched.update({
            "compliance_outcome": assessment["outcome"],
            "active_violation_count": assessment["active_violation_count"],
            "unresolved_check_count": assessment["unresolved_check_count"],
            "enforcement_ready": assessment["enforcement_ready"],
        })
        filtered.append(enriched)
    return sorted(filtered, key=_date_value, reverse=True)


def _month_key(value: str) -> str:
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00")).strftime("%Y-%m")
    except (TypeError, ValueError):
        return "Unknown"


async def _product_change_alert(repo) -> Optional[Dict[str, Any]]:
    for product in await repo.list_products():
        versions = await repo.get_label_versions(product.get("id"))
        if len(versions) > 1:
            latest = versions[-1]
            return {
                "product_id": product.get("id"), "product_name": product.get("name") or "Packaged Commodity",
                "brand": product.get("brand"), "category": product.get("category"), "version_count": len(versions),
                "latest_version": latest.get("label_version"), "latest_capture_date": latest.get("captured_at"),
                "source_inspection_id": latest.get("inspection_id"),
                "title": f"Product Change Alert: {product.get('name') or 'Packaged Commodity'}",
                "description": "Multiple persisted label versions are available for officer comparison.",
            }
    return None


@router.get("/summary")
async def get_dashboard_summary(
    date_from: Optional[str] = Query(None, pattern=r"^\d{4}-\d{2}-\d{2}$"),
    date_to: Optional[str] = Query(None, pattern=r"^\d{4}-\d{2}-\d{2}$"),
    category: Optional[str] = None,
    outcome: Optional[str] = None,
    user_payload: dict = Depends(get_current_user_payload),
):
    """Evidence-backed enforcement dashboard with server-side filters and drill-down queues."""
    repo = get_repository()
    role = str(user_payload.get("role") or "INSPECTOR").upper()
    inspector_scope = user_payload.get("sub") if role == "INSPECTOR" else None
    all_cases = await repo.list_inspections(inspector_id=inspector_scope)
    inspections = _filter_cases(all_cases, date_from, date_to, category, outcome)
    metrics = summarize_inspections(inspections)
    outcomes = metrics["outcomes"]
    finalized = sum(1 for item in inspections if str(item.get("status") or "").upper() in {"FINALIZED", "ARCHIVED"})

    # Statutory evaluations across checked parameters
    assessments = [classify_inspection(item) for item in inspections]
    total_passed_checks = sum(a["passed_check_count"] for a in assessments)
    total_failed_checks = sum(a["failed_check_count"] for a in assessments)
    total_active_violations = sum(a["active_violation_count"] for a in assessments)
    scores = [float(item["score"]) for item in inspections if item.get("score") is not None]

    total_decided_checks = total_passed_checks + total_failed_checks
    if total_decided_checks > 0:
        compliance_rate = round((total_passed_checks / total_decided_checks) * 100, 1)
        compliance_subtitle = f"{total_passed_checks} of {total_decided_checks} Statutory Checks Passed"
    elif scores:
        compliance_rate = round(sum(scores) / len(scores), 1)
        compliance_subtitle = f"Mean statutory score across {len(scores)} audits"
    elif finalized > 0:
        evaluated = outcomes.get("COMPLIANT", 0) + outcomes.get("POTENTIAL_VIOLATION", 0)
        compliance_rate = round(outcomes.get("COMPLIANT", 0) / evaluated * 100, 1) if evaluated else 0.0
        compliance_subtitle = "Based on conclusive case outcomes"
    else:
        compliance_rate = None
        compliance_subtitle = "No finalized inspections yet"

    violations_flagged = total_active_violations if total_active_violations > 0 else outcomes.get("POTENTIAL_VIOLATION", 0)
    potential_violations = outcomes.get("POTENTIAL_VIOLATION", 0)
    action_queue = [item for item in inspections if item["compliance_outcome"] in {"POTENTIAL_VIOLATION", "NEEDS_REVIEW", "UNVERIFIED"}]

    commodity_spread = []
    for name, stats in sorted(metrics["category_stats"].items(), key=lambda pair: pair[1]["total"], reverse=True):
        decided = stats["compliant"] + stats["potential_violations"]
        commodity_spread.append({"name": name, "category": name, **stats, "compliance_rate": round(stats["compliant"] / decided, 3) if decided else None})

    RULE_TITLES = {
        "RULE-006": "Rule 6: Mandatory Declarations",
        "RULE-007": "Rule 7: Numeral & Letter Height",
        "RULE-008": "Rule 8: Principal Display Panel",
        "RULE-009": "Rule 9: Contrast & Readability",
        "RULE-049": "Rule 49: E-Commerce Disclosures",
    }

    rule_health = []
    for code, stats in sorted(metrics["rule_stats"].items()):
        decided = stats["pass"] + stats["failed"]
        rate = round(stats["pass"] / decided, 3) if decided else None
        title = RULE_TITLES.get(code, code)
        rule_health.append({
            "rule": title,
            "code": code,
            "title": title,
            "total_checked": stats["total"],
            **stats,
            "rate": rate,
            "progress": rate,
            "pass_rate": f"{round(rate * 100)}%" if rate is not None else None,
        })

    trend_map: Dict[str, Dict[str, int]] = {}
    for item in inspections:
        month = _month_key(_date_value(item))
        bucket = trend_map.setdefault(month, {"total": 0, "compliant": 0, "needs_review": 0, "potential_violations": 0, "unverified": 0})
        bucket["total"] += 1
        key = {"COMPLIANT": "compliant", "NEEDS_REVIEW": "needs_review", "POTENTIAL_VIOLATION": "potential_violations", "UNVERIFIED": "unverified", "IN_PROGRESS": "unverified"}[item["compliance_outcome"]]
        bucket[key] += 1

    rules = await repo.list_rules()
    latest_rule = rules[0] if rules else None
    change_alert = await _product_change_alert(repo)
    return {
        "total_audited": finalized, "total_inspections": len(inspections), "raw_total_cases": len(all_cases),
        "compliance_rate": compliance_rate,
        "compliance_rate_subtitle": compliance_subtitle,
        "violations_flagged": violations_flagged, "potential_violations": potential_violations,
        "pending_review": outcomes.get("NEEDS_REVIEW", 0) + outcomes.get("UNVERIFIED", 0), "pending_reviews": outcomes.get("NEEDS_REVIEW", 0) + outcomes.get("UNVERIFIED", 0),
        "unverified_cases": outcomes.get("UNVERIFIED", 0), "drafts_pending": outcomes.get("IN_PROGRESS", 0),
        "active_rules_count": len(rules), "recent_changes_detected": 1 if change_alert else 0,
        "recent_inspections": inspections[:8], "enforcement_queue": action_queue[:25],
        "action_required": {"pending_reviews": outcomes.get("NEEDS_REVIEW", 0) + outcomes.get("UNVERIFIED", 0), "compliance_violations": potential_violations, "drafts_pending_finalisation": outcomes.get("IN_PROGRESS", 0), "unverified_cases": outcomes.get("UNVERIFIED", 0), "label_changes_to_review": 1 if change_alert else 0},
        "violation_summary": {"by_type": metrics["violation_types"], "by_severity": metrics["severity_counts"]},
        "product_change_alert": change_alert,
        "latest_rule_update": ({"code": latest_rule.get("code"), "title": latest_rule.get("title"), "category": latest_rule.get("category"), "effective_date": latest_rule.get("effective_from"), "version": latest_rule.get("version")} if latest_rule else None),
        "commodity_spread": commodity_spread, "rule_health": rule_health,
        "monthly_trend": [{"month": month, **values} for month, values in sorted(trend_map.items())],
        "filters": {"date_from": date_from, "date_to": date_to, "category": category, "outcome": outcome},
        "user": {"full_name": user_payload.get("full_name") or "Inspector", "role": role, "officer_id": user_payload.get("officer_id") or "", "department": "Legal Metrology Department"},
        "role": role,
    }


@router.get("/inspector")
async def get_inspector_dashboard(user_payload: dict = Depends(get_current_user_payload)):
    repo = get_repository()
    inspections = _filter_cases(await repo.list_inspections(inspector_id=user_payload["sub"]), None, None, None, None)
    metrics = summarize_inspections(inspections)["outcomes"]
    return {
        "inspector": {"name": user_payload.get("full_name") or "Inspector", "officer_id": user_payload.get("officer_id") or "", "department": "Legal Metrology Department"},
        "metrics": {"total_inspections": len(inspections), "today_inspections": len(inspections), "compliant": metrics.get("COMPLIANT", 0), "needs_review": metrics.get("NEEDS_REVIEW", 0) + metrics.get("UNVERIFIED", 0), "potential_violations": metrics.get("POTENTIAL_VIOLATION", 0)},
        "compliance_breakdown": {"pass": metrics.get("COMPLIANT", 0), "review": metrics.get("NEEDS_REVIEW", 0), "unverified": metrics.get("UNVERIFIED", 0), "potential_violation": metrics.get("POTENTIAL_VIOLATION", 0)},
        "recent_inspections": inspections[:8],
        "inspection_intelligence": {"pending_reviews": metrics.get("NEEDS_REVIEW", 0), "unverified_cases": metrics.get("UNVERIFIED", 0), "repeated_violations": 0, "label_changes_detected": 0},
    }


@router.get("/supervisor")
async def get_supervisor_dashboard(user_payload: dict = Depends(require_role("SUPERVISOR", "ADMIN"))):
    repo = get_repository()
    inspections = _filter_cases(await repo.list_inspections(), None, None, None, None)
    metrics = summarize_inspections(inspections)["outcomes"]
    return {
        "team_metrics": {"total_inspections": len(inspections), "passed": metrics.get("COMPLIANT", 0), "review_pending": metrics.get("NEEDS_REVIEW", 0) + metrics.get("UNVERIFIED", 0), "potential_violations": metrics.get("POTENTIAL_VIOLATION", 0), "confirmed_violations": metrics.get("POTENTIAL_VIOLATION", 0), "repeat_offenders": 0},
        "recent_activity": inspections[:10], "escalations": [item for item in inspections if item["compliance_outcome"] == "POTENTIAL_VIOLATION"][:10],
    }


@router.get("/admin")
async def get_admin_dashboard(user_payload: dict = Depends(require_role("ADMIN"))):
    repo = get_repository()
    users, rules, logs = await repo.list_users(), await repo.list_rules(), await repo.list_logs(limit=10)
    return {"system_status": {"database": "Repository configured", "ocr_engine": "Configured", "llm_service": "Configured", "pdp_vision_engine": "Operational", "report_generator": "PDF and DOCX ready"}, "counts": {"users": len(users), "rules": len(rules), "audit_events": len(logs)}, "recent_audit_logs": logs}
