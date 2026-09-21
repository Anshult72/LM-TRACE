from fastapi import APIRouter, Depends, HTTPException, Query, status
from typing import Dict, Any, List, Optional
from app.repositories import get_repository
from app.core.security import get_current_user_payload, require_role
from app.schemas.domain import (
    StatutoryDocumentResponse,
    StatutoryRuleResponse,
    StatutorySummaryResponse,
    StatutoryFamilyResponse,
    StatutoryTraceabilityResponse,
)

router = APIRouter(prefix="/api/statutory", tags=["Statutory Reference"])

@router.get("/summary", response_model=StatutorySummaryResponse)
async def get_statutory_summary(
    user_payload: dict = Depends(get_current_user_payload)
):
    """
    Returns database-derived statutory metrics (Active Rules, Families, Amendments, Future Effective).
    """
    repo = get_repository()
    return await repo.get_statutory_summary()

@router.get("/families", response_model=List[StatutoryFamilyResponse])
async def list_statutory_families(
    user_payload: dict = Depends(get_current_user_payload)
):
    """
    Returns configured statutory framework families (LM Act, Packaged Commodities Rules, etc.).
    """
    repo = get_repository()
    return await repo.get_statutory_families()

@router.get("/documents", response_model=List[StatutoryDocumentResponse])
async def list_statutory_documents(
    doc_type: Optional[str] = Query(None, description="Document type filter: ACT, PRINCIPAL_RULE, GAZETTE_AMENDMENT, OFFICIAL_ADVISORY, PROPOSED_AMENDMENT"),
    status: Optional[str] = Query(None, description="Status filter: ACTIVE, SUPERSEDED, NOT_YET_EFFECTIVE, ARCHIVED"),
    family: Optional[str] = Query(None, description="Statutory family filter"),
    search: Optional[str] = Query(None, description="Search keyword across title, notification, GSR, and summary"),
    user_payload: dict = Depends(get_current_user_payload)
):
    """
    Returns official statutory enactments, principal rules, amendments, and advisories.
    """
    repo = get_repository()
    return await repo.list_statutory_documents(
        doc_type=doc_type,
        status=status,
        family=family,
        search=search
    )

@router.get("/documents/{doc_id}", response_model=StatutoryDocumentResponse)
async def get_statutory_document(
    doc_id: str,
    user_payload: dict = Depends(get_current_user_payload)
):
    """
    Returns single statutory document details with child statutory rules.
    """
    repo = get_repository()
    doc = await repo.get_statutory_document_by_id(doc_id)
    if not doc:
        raise HTTPException(status_code=404, detail=f"Statutory document '{doc_id}' not found.")
    return doc

@router.get("/rules", response_model=List[StatutoryRuleResponse])
async def list_statutory_rules(
    document_id: Optional[str] = Query(None, description="Filter by parent statutory document ID"),
    family: Optional[str] = Query(None, description="Filter by statutory family"),
    status: Optional[str] = Query(None, description="Filter by status: ACTIVE, SUPERSEDED, NOT_YET_EFFECTIVE"),
    search: Optional[str] = Query(None, description="Search keyword across rule number, title, requirement, and source"),
    rule_code: Optional[str] = Query(None, description="Filter by exact rule code or mapped engine code"),
    user_payload: dict = Depends(get_current_user_payload)
):
    """
    Returns structured statutory rules with Rule Engine mappings and effective dates.
    """
    repo = get_repository()
    return await repo.list_statutory_rules(
        document_id=document_id,
        family=family,
        status=status,
        search=search,
        rule_code=rule_code
    )

@router.get("/rules/{rule_id}", response_model=StatutoryRuleResponse)
async def get_statutory_rule(
    rule_id: str,
    user_payload: dict = Depends(get_current_user_payload)
):
    """
    Returns single statutory rule details, source document reference, and Rule Engine mapping.
    """
    repo = get_repository()
    rule = await repo.get_statutory_rule_by_id(rule_id)
    if not rule:
        raise HTTPException(status_code=404, detail=f"Statutory rule '{rule_id}' not found.")
    return rule

@router.get("/traceability/{code}", response_model=StatutoryTraceabilityResponse)
async def get_statutory_traceability(
    code: str,
    user_payload: dict = Depends(get_current_user_payload)
):
    """
    Traces any compliance finding, check type, or Rule Engine code (e.g. RULE-006, RULE-007)
    back to its statutory rule provision, effective version, and official source document.
    """
    repo = get_repository()
    return await repo.get_statutory_traceability(code)

@router.post("/documents", response_model=StatutoryDocumentResponse, status_code=status.HTTP_201_CREATED)
async def create_statutory_document(
    doc_data: Dict[str, Any],
    user_payload: dict = Depends(require_role("ADMIN"))
):
    """
    Admin-only endpoint to register or amend a statutory document with audit logging.
    """
    repo = get_repository()
    if not doc_data.get("title") or not doc_data.get("document_type"):
        raise HTTPException(status_code=400, detail="Title and document_type are required.")

    if not doc_data.get("id"):
        import uuid
        doc_data["id"] = f"doc-{uuid.uuid4().hex[:8]}"

    saved = await repo.save_legal_document(doc_data)

    await repo.append_log({
        "user_id": user_payload["sub"],
        "role": user_payload.get("role", "ADMIN"),
        "action": "STATUTORY_DOCUMENT_CREATED",
        "resource_type": "STATUTORY_DOCUMENT",
        "resource_id": saved["id"],
        "new_value": {"title": saved.get("title"), "document_type": saved.get("document_type")}
    })

    return saved
