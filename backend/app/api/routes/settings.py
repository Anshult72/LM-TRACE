from fastapi import APIRouter, Depends, HTTPException, status
from typing import Dict, Any
from app.core.security import require_role
from app.services.audit.audit_service import audit_service

router = APIRouter(prefix="/api/settings", tags=["System Settings"])

# In-memory settings state with statutory defaults
_system_settings: Dict[str, Any] = {
    "interface_theme": "LIGHT_INSTITUTIONAL",
    "gazette_language": "EN",
    "surface_alignment_guidance": True,
    "auto_enhance_contrast": True,
    "offline_storage_sync": True,
    "ai_engine_endpoint": "https://api.maanak.gov.in/v1/engine",
    "statutory_edition": "Legal Metrology (Packaged Commodities) Rules, 2011 (v2024.1)",
    "audit_retention_days": 2555,  # 7-year statutory retention
    "strict_tamper_sealing": True,
}

@router.get("")
async def get_system_settings(
    user_payload: dict = Depends(require_role("ADMIN"))
) -> Dict[str, Any]:
    """
    Returns system settings. Only accessible to ADMIN role.
    """
    return {"settings": _system_settings}

@router.put("")
async def update_system_settings(
    updates: Dict[str, Any],
    user_payload: dict = Depends(require_role("ADMIN"))
) -> Dict[str, Any]:
    """
    Updates system settings. Only accessible to ADMIN role.
    Records authoritative SETTINGS_UPDATED audit event.
    """
    global _system_settings
    _system_settings.update(updates)

    actor_id = user_payload.get("sub", "admin")
    actor_name = user_payload.get("full_name") or user_payload.get("email") or "Admin"
    role = user_payload.get("role", "ADMIN")

    await audit_service.record_event(
        action="SETTINGS_UPDATED",
        actor_id=actor_id,
        actor_name=actor_name,
        role=role,
        resource_type="SYSTEM",
        resource_id="system_settings",
        result="SUCCESS",
        description=f"Admin {actor_name} updated system configuration parameters.",
        metadata={"updated_keys": list(updates.keys())}
    )

    return {
        "message": "System settings updated successfully",
        "settings": _system_settings
    }
