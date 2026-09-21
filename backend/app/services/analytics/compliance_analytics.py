from collections import Counter, defaultdict
from typing import Any, Dict, Iterable, List


FINAL_STATES = {"FINALIZED", "ARCHIVED"}
OPEN_STATES = {"DRAFT", "ANALYSING", "ANALYZING", "UPLOADING"}
UNRESOLVED_RESULTS = {"REVIEW", "UNVERIFIED"}


def _dicts(values: Any) -> List[Dict[str, Any]]:
    return [item for item in (values or []) if isinstance(item, dict)]


def classify_inspection(inspection: Dict[str, Any]) -> Dict[str, Any]:
    """Classify a case exclusively from persisted statutory evidence, never score thresholds."""
    checks = _dicts(inspection.get("checks"))
    findings = [
        item for item in _dicts(inspection.get("violations"))
        if str(item.get("status") or "AI_DETECTED").upper() != "REJECTED"
    ]
    failed = [item for item in checks if str(item.get("result") or "").upper() == "POTENTIAL_VIOLATION"]
    unresolved = [item for item in checks if str(item.get("result") or "").upper() in UNRESOLVED_RESULTS]
    passed = [item for item in checks if str(item.get("result") or "").upper() == "PASS"]
    raw_status = str(inspection.get("status") or "DRAFT").upper()

    if findings or failed:
        outcome = "POTENTIAL_VIOLATION"
    elif unresolved or raw_status == "NEEDS_REVIEW":
        outcome = "NEEDS_REVIEW"
    elif checks and len(passed) == len(checks):
        outcome = "COMPLIANT"
    elif raw_status in OPEN_STATES:
        outcome = "IN_PROGRESS"
    else:
        outcome = "UNVERIFIED"

    return {
        "outcome": outcome,
        "raw_status": raw_status,
        "check_count": len(checks),
        "passed_check_count": len(passed),
        "failed_check_count": len(failed),
        "unresolved_check_count": len(unresolved),
        "active_violation_count": len(findings),
        "enforcement_ready": bool(checks) and not findings and not failed and not unresolved,
    }


def summarize_inspections(inspections: Iterable[Dict[str, Any]]) -> Dict[str, Any]:
    records = list(inspections)
    outcomes = Counter()
    violation_types = Counter()
    severity_counts = Counter()
    rule_stats: Dict[str, Dict[str, int]] = defaultdict(lambda: {"total": 0, "pass": 0, "failed": 0, "unresolved": 0})
    category_stats: Dict[str, Dict[str, int]] = defaultdict(lambda: {"total": 0, "compliant": 0, "needs_review": 0, "potential_violations": 0, "unverified": 0})

    for item in records:
        assessment = classify_inspection(item)
        outcome = assessment["outcome"]
        outcomes[outcome] += 1
        category = str(item.get("product_category") or item.get("category") or "Uncategorised")
        category_stats[category]["total"] += 1
        category_key = {
            "COMPLIANT": "compliant", "NEEDS_REVIEW": "needs_review",
            "POTENTIAL_VIOLATION": "potential_violations", "UNVERIFIED": "unverified",
            "IN_PROGRESS": "unverified",
        }[outcome]
        category_stats[category][category_key] += 1

        for finding in _dicts(item.get("violations")):
            if str(finding.get("status") or "AI_DETECTED").upper() == "REJECTED":
                continue
            violation_types[str(finding.get("type") or "UNKNOWN")] += 1
            severity_counts[str(finding.get("severity") or "UNSPECIFIED")] += 1

        for check in _dicts(item.get("checks")):
            code = str(check.get("rule_code") or "UNMAPPED_RULE")
            result = str(check.get("result") or "UNVERIFIED").upper()
            rule_stats[code]["total"] += 1
            if result == "PASS":
                rule_stats[code]["pass"] += 1
            elif result == "POTENTIAL_VIOLATION":
                rule_stats[code]["failed"] += 1
            else:
                rule_stats[code]["unresolved"] += 1

    return {
        "total_cases": len(records),
        "outcomes": dict(outcomes),
        "violation_types": dict(violation_types),
        "severity_counts": dict(severity_counts),
        "rule_stats": dict(rule_stats),
        "category_stats": dict(category_stats),
    }
