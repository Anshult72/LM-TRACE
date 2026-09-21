import re
import copy
from typing import Dict, Any, Optional, List
from datetime import datetime, timezone

from app.repositories import get_repository
from app.core.logging import logger

SENSITIVE_KEYS = {"password", "access_token", "authorization", "secret", "hashed_password", "token", "jwt"}

def get_utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()

def sanitize_audit_payload(obj: Any) -> Any:
    """Recursively sanitize passwords, authorization headers, and sensitive secrets."""
    if isinstance(obj, dict):
        cleaned = {}
        for k, v in obj.items():
            k_lower = str(k).lower()
            if any(s in k_lower for s in SENSITIVE_KEYS):
                cleaned[k] = "[REDACTED_SECURE]"
            else:
                cleaned[k] = sanitize_audit_payload(v)
        return cleaned
    elif isinstance(obj, list):
        return [sanitize_audit_payload(item) for item in obj]
    return obj

class AuditService:
    """
    Centralized, authoritative Audit Service for LM-TRACE.
    Guarantees immutable chronological audit events with server-side timestamps,
    actor snapshotting, sanitized payloads, and end-to-end chain of custody traceability.
    """

    def _determine_event_type(self, action: str, resource_type: str) -> str:
        act = action.upper()
        res = resource_type.upper()
        if "LOGIN" in act or "LOGOUT" in act or "AUTH" in res:
            return "AUTH"
        if "INSPECTION" in act or "INSPECTION" in res:
            return "INSPECTION"
        if "IMAGE" in act or "EVIDENCE" in act or "EVIDENCE" in res:
            return "EVIDENCE"
        if "OCR" in act:
            return "OCR"
        if "CV" in act or "VISION" in act or "MEASUREMENT" in act:
            return "CV"
        if "CALIBRATION" in act or "CALIBRATION" in res:
            return "CALIBRATION"
        if "RULE" in act:
            return "RULE_ENGINE"
        if "COMPLIANCE" in act:
            return "COMPLIANCE"
        if "FINDING" in act or "VIOLATION" in res:
            return "FINDING"
        if "REVIEW" in act or "SUPERVISOR" in act:
            return "SUPERVISOR"
        if "REPORT" in act or "REPORT" in res:
            return "REPORT"
        if "STATUTORY" in act:
            return "STATUTORY"
        return "SYSTEM"

    async def record_event(
        self,
        action: str,
        actor_id: str,
        role: str,
        resource_type: str,
        resource_id: str,
        actor_name: Optional[str] = None,
        inspection_id: Optional[str] = None,
        result: str = "SUCCESS",
        description: Optional[str] = None,
        old_value: Optional[Dict[str, Any]] = None,
        new_value: Optional[Dict[str, Any]] = None,
        metadata: Optional[Dict[str, Any]] = None,
        correlation_id: Optional[str] = None,
        event_type: Optional[str] = None,
        source: str = "LM-TRACE"
    ) -> Dict[str, Any]:
        """
        Records an append-only audit event in the system of record.
        """
        repo = get_repository()
        clean_action = action.strip().upper()
        clean_res_type = resource_type.strip().upper()
        determined_type = event_type or self._determine_event_type(clean_action, clean_res_type)

        # Default human-readable description if missing
        if not description:
            readable_action = clean_action.replace("_", " ").title()
            description = f"{readable_action} on {clean_res_type} {resource_id}."

        # Sanitize sensitive fields in old_value, new_value, metadata
        sanitized_old = sanitize_audit_payload(old_value) if old_value else None
        sanitized_new = sanitize_audit_payload(new_value) if new_value else None
        sanitized_meta = sanitize_audit_payload(metadata) if metadata else {}

        # Default correlation ID
        if not correlation_id:
            if inspection_id:
                correlation_id = f"TRACE-{inspection_id}"
            else:
                correlation_id = f"TRACE-{resource_id}"

        # Resolve actor name snapshot if not passed
        effective_actor_name = actor_name
        if not effective_actor_name:
            if actor_id == "system" or role == "SYSTEM":
                effective_actor_name = "LM-TRACE System Engine"
            elif actor_id == "anonymous" or role == "ANONYMOUS":
                effective_actor_name = "Unauthenticated Client"
            else:
                try:
                    user = await repo.get_by_id(actor_id)
                    if user:
                        effective_actor_name = user.get("full_name") or user.get("email") or actor_id
                    else:
                        effective_actor_name = actor_id
                except Exception:
                    effective_actor_name = actor_id

        payload = {
            "action": clean_action,
            "event_type": determined_type,
            "user_id": actor_id,
            "actor_id": actor_id,
            "actor_name": effective_actor_name,
            "role": role.upper(),
            "resource_type": clean_res_type,
            "resource_id": str(resource_id),
            "target_type": clean_res_type,
            "target_id": str(resource_id),
            "inspection_id": inspection_id,
            "result": result.upper(),
            "description": description,
            "old_value": sanitized_old,
            "new_value": sanitized_new,
            "before_data": sanitized_old,
            "after_data": sanitized_new,
            "metadata": sanitized_meta,
            "correlation_id": correlation_id,
            "timestamp": get_utc_now_iso(),
            "source": source
        }

        try:
            persisted = await repo.append_log(payload)
            return persisted
        except Exception as e:
            logger.error("Failed to append audit log: %s", e)
            return payload

audit_service = AuditService()
