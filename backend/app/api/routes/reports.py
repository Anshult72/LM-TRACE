import os
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Response, status
from fastapi.responses import FileResponse
from typing import Dict, Any
from app.repositories import get_repository
from app.core.security import get_current_user_payload
from app.storage.file_storage import storage_manager
from app.services.reports.docx_generator import docx_report_generator
from app.services.reports.pdf_generator import pdf_report_generator
from app.schemas.domain import InspectionReportModel
from app.core.logging import logger

router = APIRouter(prefix="/api/reports", tags=["Reports"])

def get_utc_now_iso():
    return datetime.now(timezone.utc).isoformat()

@router.get("/{inspection_id}")
async def get_report_metadata(
    inspection_id: str,
    user_payload: dict = Depends(get_current_user_payload)
):
    repo = get_repository()
    rep = await repo.get_report_by_inspection_id(inspection_id)
    if not rep:
        return {
            "inspection_id": inspection_id,
            "report_version": 1,
            "archival_status": "NOT_GENERATED"
        }
    return rep

@router.post("/{inspection_id}/pdf")
async def archive_pdf_report(
    inspection_id: str,
    file: UploadFile = File(...),
    user_payload: dict = Depends(get_current_user_payload)
):
    """
    Archives Flutter-generated dynamic A4 PDF report with SHA-256 integrity.
    """
    repo = get_repository()
    ins = await repo.get_by_id(inspection_id)
    if not ins:
        raise HTTPException(status_code=404, detail="Inspection not found")

    file_bytes = await file.read()
    if len(file_bytes) > 20 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="Report file size exceeds 20 MB limit.")
    if not file_bytes.startswith(b"%PDF-"):
        raise HTTPException(status_code=400, detail="Uploaded report is not a valid PDF document.")

    existing_rep = await repo.get_report_by_inspection_id(inspection_id)
    version = (existing_rep.get("report_version", 0) + 1) if existing_rep else 1

    file_path, sha256 = await storage_manager.save_report_pdf(inspection_id, file_bytes, version)

    report_record = {
        "id": existing_rep.get("id") if existing_rep else f"rep-{inspection_id}",
        "inspection_id": inspection_id,
        "report_version": version,
        "pdf_path": file_path,
        "pdf_sha256": sha256,
        "pdf_generated_at": get_utc_now_iso(),
        "archival_status": "ARCHIVED",
        "generated_by": user_payload["sub"]
    }

    saved = await repo.save_report_metadata(report_record)

    await repo.append_log({
        "user_id": user_payload["sub"],
        "role": user_payload["role"],
        "action": "PDF_REPORT_ARCHIVED",
        "resource_type": "REPORT",
        "resource_id": saved["id"],
        "metadata": {"sha256": sha256, "version": version}
    })

    return {"success": True, "report": saved}

@router.get("/{inspection_id}/pdf")
async def get_pdf_report(
    inspection_id: str,
    user_payload: dict = Depends(get_current_user_payload)
):
    repo = get_repository()
    rep = await repo.get_report_by_inspection_id(inspection_id)
    if not rep or not rep.get("pdf_path") or not os.path.exists(rep["pdf_path"]):
        raise HTTPException(status_code=404, detail="PDF report not found or not yet generated.")
    
    return FileResponse(
        rep["pdf_path"],
        media_type="application/pdf",
        filename=os.path.basename(rep["pdf_path"])
    )

def _build_report_model(ins: Dict[str, Any], user_payload: Dict[str, Any], version: int = 1) -> InspectionReportModel:
    declarations = ins.get("declarations", [])
    decl_map = {}
    formatted_declarations = []
    for d in declarations:
        if isinstance(d, dict):
            f_name = d.get("field_name", "")
            f_val = d.get("verified_value") or d.get("ai_value") or "N/A"
            decl_map[f_name] = f_val
            is_missing = d.get("presence_status") == "MISSING"
            is_invalid = d.get("correctness_status") == "INVALID"
            is_review = d.get("correctness_status") == "REVIEW"
            status_str = "FAIL" if (is_missing or is_invalid) else ("REVIEW" if is_review else "PASS")
            formatted_declarations.append({
                "declaration": f_name.replace("_", " ").title(),
                "ai_value": d.get("ai_value") or ("Missing" if is_missing else "N/A"),
                "verified_value": f_val,
                "correctness": d.get("correctness_status", "VALID"),
                "presence": d.get("presence_status", "UNVERIFIED"),
                "final_check": status_str
            })

    checks = ins.get("checks", [])
    formatted_checks = []
    for c in checks:
        if isinstance(c, dict):
            formatted_checks.append({
                "rule_code": c.get("rule_code", "RULE"),
                "check_type": c.get("check_type", "AUDIT"),
                "field_name": c.get("field_name", "general"),
                "input_value": str(c.get("input_value", "")),
                "expected_condition": str(c.get("expected_condition", "")),
                "result": str(c.get("result", "UNVERIFIED")),
                "explanation": str(c.get("explanation", "")),
                "source_reference": str(c.get("source_reference", "")),
                "evidence_id": c.get("evidence_id"),
            })

    pdp_info = ins.get("pdp_data") or {}
    pdp_area = pdp_info.get("areaCm2") or pdp_info.get("area_cm2")
    rule_snapshot = ins.get("rule_snapshot") or {}
    has_failed_checks = any(
        item.get("result") == "POTENTIAL_VIOLATION"
        for item in ins.get("checks", []) if isinstance(item, dict)
    )
    has_violations = bool(ins.get("violations")) or has_failed_checks
    has_unresolved_checks = any(
        item.get("result") in {"REVIEW", "UNVERIFIED"}
        for item in ins.get("checks", []) if isinstance(item, dict)
    )
    report_status = "POTENTIAL_VIOLATION" if has_violations else ("NEEDS_REVIEW" if has_unresolved_checks else "COMPLIANT")

    return InspectionReportModel(
        report_id=f"rep-{ins.get('id', 'default')}",
        report_version=version,
        inspection_id=ins.get("id", ""),
        inspection_code=ins.get("inspection_code", f"INS-{str(ins.get('id', ''))[:6]}"),
        inspection_date=ins.get("inspection_date", get_utc_now_iso()),
        inspector_name=user_payload.get("full_name") or user_payload.get("sub") or "Legal Metrology Inspector",
        officer_id=user_payload.get("officer_id", "LM-OFFICER"),
        location=ins.get("location", "Inspection Site"),
        seller_name=ins.get("seller_name") or ins.get("business_name"),
        business_name=ins.get("business_name") or ins.get("seller_name"),
        inspection_type=ins.get("inspection_type", "PHYSICAL"),
        product_name=decl_map.get("commodity_name") or decl_map.get("product_name") or "Packaged Commodity",
        brand=decl_map.get("brand") or ins.get("business_name") or "Packaged Goods",
        category=rule_snapshot.get("product_category") or "Packaged Commodity",
        mrp=decl_map.get("mrp") or "N/A",
        net_quantity=decl_map.get("net_quantity") or "N/A",
        overall_status=report_status,
        score=float(ins["score"]) if ins.get("score") is not None else 0.0,
        pdp_area_cm2=float(pdp_area) if pdp_area is not None else None,
        package_construction=ins.get("package_construction_type", "NORMAL"),
        calibration_status=ins.get("calibration_status") or "NOT_CALIBRATED",
        declarations=formatted_declarations,
        compliance_checks=formatted_checks,
        findings=ins.get("violations", []),
        evidence_images=ins.get("evidence_items", []),
        inspector_remarks=ins.get("notes"),
        disclaimer="This document represents an AI-assisted inspection assessment generated from the captured evidence and configured compliance rules. It is intended to assist authorized personnel. Final regulatory determination and enforcement action remain with the competent authority/authorized officer.",
        generated_at=get_utc_now_iso()
    )


def _violation_summary(ins: Dict[str, Any]) -> Dict[str, Any]:
    findings = [item for item in ins.get("violations", []) if isinstance(item, dict)]
    checks = [item for item in ins.get("checks", []) if isinstance(item, dict)]
    by_type: Dict[str, int] = {}
    by_severity: Dict[str, int] = {}
    for item in findings:
        finding_type = str(item.get("type") or "UNKNOWN")
        severity = str(item.get("severity") or "UNSPECIFIED")
        by_type[finding_type] = by_type.get(finding_type, 0) + 1
        by_severity[severity] = by_severity.get(severity, 0) + 1
    unverified = [item for item in checks if item.get("result") in {"REVIEW", "UNVERIFIED"}]
    failed = [item for item in checks if item.get("result") == "POTENTIAL_VIOLATION"]
    return {
        "inspection_id": ins.get("id"),
        "inspection_code": ins.get("inspection_code"),
        "overall_status": "POTENTIAL_VIOLATION" if findings or failed else (
            "NEEDS_REVIEW" if unverified else "COMPLIANT"
        ),
        "score": ins.get("score"),
        "violation_count": len(findings),
        "failed_check_count": len(failed),
        "review_or_unverified_count": len(unverified),
        "by_type": by_type,
        "by_severity": by_severity,
        "findings": findings,
        "review_items": unverified,
        "enforcement_ready": bool(checks) and not unverified and not failed and not findings,
    }


@router.get("/{inspection_id}/summary")
async def get_violation_summary(inspection_id: str, user_payload: dict = Depends(get_current_user_payload)):
    repo = get_repository()
    ins = await repo.get_by_id(inspection_id)
    if not ins:
        raise HTTPException(status_code=404, detail="Inspection not found")
    if not ins.get("checks"):
        raise HTTPException(status_code=400, detail="Run statutory analysis before generating a compliance report.")
    return _violation_summary(ins)


@router.post("/{inspection_id}/generate-pdf")
async def generate_and_archive_pdf(inspection_id: str, user_payload: dict = Depends(get_current_user_payload)):
    repo = get_repository()
    ins = await repo.get_by_id(inspection_id)
    if not ins:
        raise HTTPException(status_code=404, detail="Inspection not found")
    if not ins.get("checks"):
        raise HTTPException(status_code=400, detail="Run statutory analysis before generating a compliance report.")
    canonical_id = ins.get("id", inspection_id)
    existing = await repo.get_report_by_inspection_id(canonical_id)
    version = (existing.get("report_version", 0) + 1) if existing else 1
    report_model = _build_report_model(ins, user_payload, version)
    pdf_bytes = pdf_report_generator.generate_pdf(report_model)
    file_path, sha256 = await storage_manager.save_report_pdf(canonical_id, pdf_bytes, version)
    record = existing or {"id": f"rep-{canonical_id}", "inspection_id": canonical_id, "generated_by": user_payload["sub"]}
    record.update({
        "report_version": version, "pdf_path": file_path, "pdf_sha256": sha256,
        "pdf_generated_at": get_utc_now_iso(), "archival_status": "ARCHIVED",
    })
    saved = await repo.save_report_metadata(record)
    await repo.append_log({
        "user_id": user_payload["sub"], "role": user_payload["role"], "action": "PDF_REPORT_GENERATED",
        "resource_type": "REPORT", "resource_id": saved["id"], "metadata": {"sha256": sha256, "version": version},
    })
    return {"success": True, "report": saved, "summary": _violation_summary(ins)}

@router.post("/{inspection_id}/docx")
async def generate_and_archive_docx(
    inspection_id: str,
    user_payload: dict = Depends(get_current_user_payload)
):
    repo = get_repository()
    ins = await repo.get_by_id(inspection_id)
    if not ins:
        raise HTTPException(status_code=404, detail="Inspection not found")
    if not ins.get("checks"):
        raise HTTPException(status_code=400, detail="Run statutory analysis before generating a compliance report.")

    canonical_id = ins.get("id", inspection_id)
    existing_rep = await repo.get_report_by_inspection_id(canonical_id)
    version = (existing_rep.get("report_version", 0) + 1) if existing_rep else 1

    report_model = _build_report_model(ins, user_payload, version)
    docx_bytes = docx_report_generator.generate_docx(report_model)
    file_path, sha256 = await storage_manager.save_report_docx(canonical_id, docx_bytes, version)

    report_record = existing_rep or {
        "id": f"rep-{canonical_id}",
        "inspection_id": canonical_id,
        "report_version": version,
        "generated_by": user_payload["sub"]
    }
    report_record["docx_path"] = file_path
    report_record["docx_sha256"] = sha256
    report_record["docx_generated_at"] = get_utc_now_iso()
    report_record["report_version"] = version
    report_record["archival_status"] = "ARCHIVED"

    saved = await repo.save_report_metadata(report_record)

    await repo.append_log({
        "user_id": user_payload["sub"],
        "role": user_payload["role"],
        "action": "DOCX_REPORT_GENERATED",
        "resource_type": "REPORT",
        "resource_id": saved["id"],
        "metadata": {"sha256": sha256, "version": version}
    })

    return {"success": True, "report": saved}

@router.get("/{inspection_id}/docx")
async def get_docx_report(
    inspection_id: str,
    user_payload: dict = Depends(get_current_user_payload)
):
    repo = get_repository()
    ins = await repo.get_by_id(inspection_id)
    if not ins:
        raise HTTPException(status_code=404, detail="Inspection not found")
    if not ins.get("checks"):
        raise HTTPException(status_code=400, detail="Run statutory analysis before generating a compliance report.")

    canonical_id = ins.get("id", inspection_id)
    rep = await repo.get_report_by_inspection_id(canonical_id)
    if rep and rep.get("docx_path") and os.path.isfile(rep["docx_path"]):
        return FileResponse(
            rep["docx_path"],
            media_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            filename=os.path.basename(rep["docx_path"])
        )

    # Dynamic on-demand generation: if file is not on disk or hasn't been pre-generated
    version = (rep.get("report_version", 1)) if rep else 1
    report_model = _build_report_model(ins, user_payload, version)
    docx_bytes = docx_report_generator.generate_docx(report_model)

    try:
        file_path, sha256 = await storage_manager.save_report_docx(canonical_id, docx_bytes, version)
        report_record = rep or {
            "id": f"rep-{canonical_id}",
            "inspection_id": canonical_id,
            "report_version": version,
            "generated_by": user_payload.get("sub", "system")
        }
        report_record["docx_path"] = file_path
        report_record["docx_sha256"] = sha256
        report_record["docx_generated_at"] = get_utc_now_iso()
        await repo.save_report_metadata(report_record)
    except Exception as e:
        logger.warning(f"Could not persist docx report to disk: {e}")

    filename = f"LM_TRACE_REPORT_{ins.get('inspection_code', canonical_id)}.docx"
    return Response(
        content=docx_bytes,
        media_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        headers={
            "Content-Disposition": f'attachment; filename="{filename}"'
        }
    )
