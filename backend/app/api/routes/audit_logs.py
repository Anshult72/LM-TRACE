from fastapi import APIRouter, Depends, HTTPException, Query, status
from typing import Dict, Any, List, Optional, Union
from app.repositories import get_repository
from app.core.security import get_current_user_payload, require_role
from app.schemas.domain import (
    AuditEventResponse,
    AuditSummaryResponse,
    AuditListResponse,
    ChainOfCustodyResponse,
)
from app.services.audit.audit_service import audit_service

router = APIRouter(prefix="/api/audit-logs", tags=["Audit Trail"])

@router.get("", response_model=Union[AuditListResponse, List[Dict[str, Any]]])
async def list_audit_logs(
    q: Optional[str] = Query(None, description="Free text search on event ID, action, actor, description, inspection ID"),
    action: Optional[str] = Query(None, description="Filter by exact action name"),
    event_type: Optional[str] = Query(None, description="Filter by event category"),
    actor_id: Optional[str] = Query(None, description="Filter by actor ID"),
    role: Optional[str] = Query(None, description="Filter by role (INSPECTOR, ADMIN, SUPERVISOR, SYSTEM)"),
    resource_type: Optional[str] = Query(None, description="Filter by resource type"),
    inspection_id: Optional[str] = Query(None, description="Filter by inspection ID or code"),
    result: Optional[str] = Query(None, description="Filter by result (SUCCESS, FAILURE, WARNING)"),
    date_from: Optional[str] = Query(None, description="ISO format start date filter"),
    date_to: Optional[str] = Query(None, description="ISO format end date filter"),
    correlation_id: Optional[str] = Query(None, description="Filter by correlation ID"),
    limit: int = Query(50, ge=1, le=500),
    offset: int = Query(0, ge=0),
    as_list: bool = Query(False, description="Return raw list of events instead of paginated object"),
    user_payload: dict = Depends(require_role("INSPECTOR", "SUPERVISOR", "ADMIN"))
):
    repo = get_repository()
    res = await repo.list_logs_filtered(
        q=q,
        action=action,
        event_type=event_type,
        actor_id=actor_id,
        role=role,
        resource_type=resource_type,
        inspection_id=inspection_id,
        result=result,
        date_from=date_from,
        date_to=date_to,
        correlation_id=correlation_id,
        limit=limit,
        offset=offset,
    )
    if as_list:
        return res.get("items", [])
    return res

@router.get("/summary", response_model=AuditSummaryResponse)
async def get_audit_summary(
    user_payload: dict = Depends(require_role("INSPECTOR", "SUPERVISOR", "ADMIN"))
):
    repo = get_repository()
    return await repo.get_audit_summary()

@router.get("/chain/{inspection_id}", response_model=ChainOfCustodyResponse)
async def get_chain_of_custody(
    inspection_id: str,
    user_payload: dict = Depends(require_role("INSPECTOR", "SUPERVISOR", "ADMIN"))
):
    repo = get_repository()
    return await repo.get_chain_of_custody(inspection_id)

@router.get("/{id}", response_model=AuditEventResponse)
async def get_audit_log_by_id(
    id: str,
    user_payload: dict = Depends(require_role("INSPECTOR", "SUPERVISOR", "ADMIN"))
):
    repo = get_repository()
    log = await repo.get_log_by_id(id)
    if not log:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Audit event '{id}' not found in system of record."
        )
    return log

@router.delete("/{id}")
async def delete_audit_log(
    id: str,
    user_payload: dict = Depends(get_current_user_payload)
):
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail="Audit logs are append-only and strictly immutable under Legal Metrology compliance regulations."
    )

@router.put("/{id}")
async def update_audit_log(
    id: str,
    user_payload: dict = Depends(get_current_user_payload)
):
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail="Audit logs are append-only and strictly immutable under Legal Metrology compliance regulations."
    )
