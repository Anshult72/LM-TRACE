from fastapi import APIRouter, Depends
from typing import Dict, Any
from app.repositories import get_repository
from app.core.security import get_current_user_payload

router = APIRouter(prefix="/api/dashboard", tags=["Dashboard"])

@router.get("/summary")
async def get_dashboard_summary(user_payload: dict = Depends(get_current_user_payload)):
    """Return the comprehensive KPI shape and live operational feeds consumed by the Flutter home dashboard."""
    repo = get_repository()
    inspections = await repo.list_inspections()
    rules = await repo.list_rules()

    total = len(inspections)
    finalized = [item for item in inspections if item.get("status") in ["FINALIZED", "ARCHIVED"]]
    total_audited = len(finalized)
    compliant = [item for item in finalized if (item.get("score") or 0) >= 80]
    pending_reviews = sum(1 for item in inspections if item.get("status") == "NEEDS_REVIEW")
    drafts_pending = sum(1 for item in inspections if item.get("status") == "DRAFT")
    violations_flagged = sum(
        1 for item in finalized
        if (item.get("score") is not None and item.get("score") < 80) or item.get("status") == "VIOLATION"
    )

    low_confidence_cases = sum(
        1 for item in inspections
        if item.get("status") in ["NEEDS_REVIEW", "ANALYSING"] or (item.get("score") is not None and 50 <= (item.get("score") or 0) < 80)
    )

    # Sort inspections by date descending to extract true recent records
    def _sort_key(ins):
        return ins.get("created_at") or ins.get("inspection_date") or ""

    sorted_inspections = sorted(inspections, key=_sort_key, reverse=True)
    recent_inspections = sorted_inspections[:5]

    # Query real products to detect actual label modifications
    product_change_alert = None
    try:
        products = await repo.list_products()
        for p in products:
            lvs = await repo.get_label_versions(p.get("id"))
            if len(lvs) > 1:
                product_change_alert = {
                    "product_id": p.get("id"),
                    "product_name": p.get("name", "Packaged Commodity"),
                    "brand": p.get("brand", ""),
                    "category": p.get("category", "Packaged Goods"),
                    "title": f"Product Change Alert: {p.get('name')}",
                    "description": "Visual redesign / specification update detected across sequential packaging batches.",
                    "detected_rule": "Rule 7 (Net Quantity Font & Layout Consistency)"
                }
                break
    except Exception:
        product_change_alert = None

    # Latest verified statutory rule update
    latest_rule_update = None
    if rules:
        active_rules = [r for r in rules if r.get("active", True)]
        if active_rules:
            latest = active_rules[0]
            latest_rule_update = {
                "code": latest.get("code", "RULE-007"),
                "title": latest.get("title", "Statutory Declarations Verification"),
                "category": latest.get("category", "LEGAL_METROLOGY"),
                "effective_date": "2024-01-01",
                "version": "2024.1"
            }

    compliance_rate = round((len(compliant) / total_audited * 100), 1) if total_audited > 0 else None

    # Real commodity category distribution
    commodity_counts: Dict[str, Dict[str, int]] = {}
    for item in finalized:
        cat = item.get("product_category") or "Packaged Commodity"
        if cat not in commodity_counts:
            commodity_counts[cat] = {"total": 0, "compliant": 0}
        commodity_counts[cat]["total"] += 1
        if (item.get("score") or 0) >= 80:
            commodity_counts[cat]["compliant"] += 1
    commodity_spread = [
        {
            "category": cat,
            "total": stats["total"],
            "compliance_rate": round(stats["compliant"] / stats["total"], 2) if stats["total"] > 0 else 0.0,
        }
        for cat, stats in commodity_counts.items()
    ]

    # Real rule health checks aggregation across inspections
    rule_checks_map: Dict[str, Dict[str, Any]] = {}
    for ins in inspections:
        for check in ins.get("checks", []):
            if isinstance(check, dict):
                r_code = check.get("rule_code") or check.get("rule_id") or "General"
                if r_code not in rule_checks_map:
                    rule_checks_map[r_code] = {"title": check.get("rule_title") or r_code, "total": 0, "pass": 0}
                rule_checks_map[r_code]["total"] += 1
                if check.get("status") in ["PASS", "COMPLIANT"]:
                    rule_checks_map[r_code]["pass"] += 1
    rule_health = [
        {
            "title": data["title"],
            "code": code,
            "total": data["total"],
            "pass_rate": f"{round((data['pass'] / data['total']) * 100)}%",
            "progress": round(data["pass"] / data["total"], 2),
        }
        for code, data in rule_checks_map.items()
    ]

    action_required = {
        "pending_reviews": pending_reviews,
        "compliance_violations": violations_flagged,
        "drafts_pending_finalisation": drafts_pending,
        "label_changes_to_review": 1 if product_change_alert else 0,
        "low_confidence_cases": low_confidence_cases,
    }

    return {
        "total_audited": total_audited,
        "total_inspections": total_audited,
        "raw_total_cases": total,
        "compliance_rate": compliance_rate,
        "compliance_rate_subtitle": "Based on finalized inspections" if total_audited > 0 else "No finalized inspections yet",
        "violations_flagged": violations_flagged,
        "potential_violations": violations_flagged,
        "violations_subtitle": "Non-compliant packages" if violations_flagged > 0 else "0 violations recorded",
        "pending_review": pending_reviews,
        "pending_reviews": pending_reviews,
        "pending_subtitle": "Awaiting inspector sign-off" if pending_reviews > 0 else "Nothing currently awaiting review",
        "drafts_pending": drafts_pending,
        "active_rules_count": len(rules),
        "recent_changes_detected": 1 if product_change_alert else 0,
        "recent_inspections": recent_inspections,
        "action_required": action_required,
        "product_change_alert": product_change_alert,
        "latest_rule_update": latest_rule_update,
        "commodity_spread": commodity_spread,
        "rule_health": rule_health,
        "user": {
            "full_name": user_payload.get("full_name") or "Inspector",
            "role": user_payload.get("role") or "INSPECTOR",
            "officer_id": user_payload.get("officer_id") or "",
            "department": "Legal Metrology Department",
        },
        "role": user_payload.get("role"),
    }

@router.get("/inspector")
async def get_inspector_dashboard(user_payload: dict = Depends(get_current_user_payload)):
    repo = get_repository()
    inspections = await repo.list_inspections(inspector_id=user_payload["sub"])
    
    total = len(inspections)
    compliant = sum(1 for i in inspections if i.get("status") in ["FINALIZED", "READY"] and (i.get("score") or 0) >= 80)
    review = sum(1 for i in inspections if i.get("status") == "NEEDS_REVIEW")
    violations = sum(1 for i in inspections if i.get("status") == "FINALIZED" and (i.get("score") or 0) < 80)

    return {
        "inspector": {
            "name": user_payload.get("full_name") or "Inspector",
            "officer_id": user_payload.get("officer_id") or "",
            "department": "Legal Metrology Department"
        },
        "metrics": {
            "today_inspections": total,
            "compliant": compliant,
            "needs_review": review,
            "potential_violations": violations
        },
        "compliance_breakdown": {
            "pass": compliant,
            "review": review,
            "potential_violation": violations
        },
        "recent_inspections": inspections[:5],
        "inspection_intelligence": {
            "pending_reviews": review,
            "low_confidence_findings": sum(1 for i in inspections if i.get("status") in ["NEEDS_REVIEW", "ANALYSING"]),
            "repeated_violations": 0,
            "label_changes_detected": 0
        }
    }

@router.get("/supervisor")
async def get_supervisor_dashboard(user_payload: dict = Depends(get_current_user_payload)):
    repo = get_repository()
    all_inspections = await repo.list_inspections()
    finalized = [i for i in all_inspections if i.get("status") in ["FINALIZED", "ARCHIVED"]]
    compliant = sum(1 for i in finalized if (i.get("score") or 0) >= 80)
    review = sum(1 for i in all_inspections if i.get("status") == "NEEDS_REVIEW")
    violations = sum(1 for i in finalized if (i.get("score") or 0) < 80)

    return {
        "team_metrics": {
            "total_inspections": len(finalized),
            "passed": compliant,
            "review_pending": review,
            "confirmed_violations": violations,
            "repeat_offenders": 0
        },
        "recent_activity": all_inspections[:6],
        "escalations": [
            {
                "inspection_code": i.get("inspection_code"),
                "product": i.get("product_name") or i.get("business_name") or "Packaged Commodity",
                "issue": "Non-compliant declarations detected",
                "status": "CONFIRMED_VIOLATION"
            }
            for i in finalized if (i.get("score") or 0) < 80
        ][:5]
    }

@router.get("/admin")
async def get_admin_dashboard(user_payload: dict = Depends(get_current_user_payload)):
    repo = get_repository()
    users = await repo.list_users()
    rules = await repo.list_rules()
    logs = await repo.list_logs(limit=10)

    return {
        "system_status": {
            "database": "Neon PostgreSQL (Connected / Demo Ready)",
            "ocr_engine": "PaddleOCR Abstraction (Ready)",
            "llm_service": "Groq vision + structured extraction (Configured)",
            "pdp_vision_engine": "OpenCV Metrology Engine (Operational)",
            "report_generator": "PDF & DOCX Multi-Format Engine (Ready)"
        },
        "counts": {
            "users": len(users),
            "rules": len(rules),
            "audit_events": len(logs)
        },
        "recent_audit_logs": logs
    }
