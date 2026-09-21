import cv2
import numpy as np
import pytest

from app.api.routes.reports import _build_report_model, _violation_summary
from app.engines.compliance_engine.compliance_engine import compliance_engine
from app.services.reports.pdf_generator import PdfReportGenerator
from app.services.vision.cv_service import OpenCvVisionService


def test_character_geometry_is_measured_from_ocr_crop(tmp_path):
    image = np.full((140, 420, 3), 255, dtype=np.uint8)
    cv2.putText(image, "MRP 150", (35, 90), cv2.FONT_HERSHEY_SIMPLEX, 1.8, (0, 0, 0), 4, cv2.LINE_AA)
    path = tmp_path / "label.png"
    cv2.imwrite(str(path), image)

    result = OpenCvVisionService.measure_character_geometry(
        str(path), {"x": 20, "y": 30, "width": 350, "height": 80}
    )

    assert result["status"] == "MEASURED"
    assert result["sample_count"] >= 3
    assert result["char_height_px"] > 0
    assert result["char_width_px"] > 0
    assert result["measurement_confidence"] >= 0.65
    assert result["median_char_height_px"] >= result["char_height_px"]


def test_readability_uses_exposure_contrast_and_edges(tmp_path):
    clear = np.full((120, 360, 3), 255, dtype=np.uint8)
    cv2.putText(clear, "NET QTY 1 KG", (15, 75), cv2.FONT_HERSHEY_SIMPLEX, 1.2, (0, 0, 0), 3, cv2.LINE_AA)
    clear_path = tmp_path / "clear.png"
    cv2.imwrite(str(clear_path), clear)
    clear_result = OpenCvVisionService.evaluate_readability(str(clear_path))
    assert clear_result["status"] == "PASS"
    assert clear_result["edge_density"] > 0

    washed_out = np.full((120, 360, 3), 250, dtype=np.uint8)
    cv2.putText(washed_out, "NET QTY 1 KG", (15, 75), cv2.FONT_HERSHEY_SIMPLEX, 1.2, (245, 245, 245), 2, cv2.LINE_AA)
    washed_path = tmp_path / "washed.png"
    cv2.imwrite(str(washed_path), washed_out)
    washed_result = OpenCvVisionService.evaluate_readability(str(washed_path))
    assert washed_result["status"] == "POTENTIAL_VIOLATION"
    assert washed_result["reasons"]


@pytest.mark.asyncio
async def test_calibrated_small_characters_create_font_size_violation():
    assessment = await compliance_engine.evaluate_compliance(
        extracted_declarations={"net_quantity": {"value": "1 kg"}},
        correctness_data={"matrix": [], "conflicts": []},
        context={
            "inspectionDate": "2026-09-20T00:00:00Z",
            "pdpAreaCm2": 150.0,
            "packageConstructionType": "NORMAL",
            "calibrationStatus": "CALIBRATED",
            "pixelsPerMm": 10.0,
        },
        readability_data={
            "typography_results": [{
                "field_name": "net_quantity", "matched_field": "net_quantity",
                "status": "MEASURED", "char_height_px": 10.0,
                "char_width_px": 5.0, "sample_count": 8,
            }],
            "readability_results": [],
        },
    )

    height_check = next(c for c in assessment.checks if c.check_type == "CHARACTER_HEIGHT")
    assert height_check.result == "POTENTIAL_VIOLATION"
    assert any(v["type"] == "INSUFFICIENT_FONT_SIZE" for v in assessment.potential_violations)


@pytest.mark.asyncio
async def test_uncalibrated_typography_never_fabricates_millimetres():
    assessment = await compliance_engine.evaluate_compliance(
        extracted_declarations={"net_quantity": {"value": "1 kg"}},
        correctness_data={"matrix": [], "conflicts": []},
        context={"inspectionDate": "2026-09-20T00:00:00Z", "pdpAreaCm2": 150.0},
        readability_data={
            "typography_results": [{
                "field_name": "net_quantity", "status": "MEASURED",
                "char_height_px": 10.0, "char_width_px": 5.0, "sample_count": 8,
            }]
        },
    )

    height_check = next(c for c in assessment.checks if c.check_type == "CHARACTER_HEIGHT")
    assert height_check.result == "UNVERIFIED"
    assert height_check.input_value == "UNVERIFIED"
    assert not any(v["type"] == "INSUFFICIENT_FONT_SIZE" for v in assessment.potential_violations)


@pytest.mark.asyncio
async def test_calibration_is_not_reused_across_different_image_planes():
    assessment = await compliance_engine.evaluate_compliance(
        extracted_declarations={"net_quantity": {"value": "1 kg"}},
        correctness_data={"matrix": [], "conflicts": []},
        context={
            "inspectionDate": "2026-09-20T00:00:00Z", "pdpAreaCm2": 150.0,
            "calibrationStatus": "CALIBRATED", "pixelsPerMm": 10.0,
            "calibrationImageId": "front-image",
        },
        readability_data={"typography_results": [{
            "field_name": "net_quantity", "source_image_id": "back-image",
            "status": "MEASURED", "char_height_px": 40.0, "char_width_px": 20.0,
            "sample_count": 8, "measurement_confidence": 0.9,
        }]},
    )
    height_check = next(c for c in assessment.checks if c.check_type == "CHARACTER_HEIGHT")
    assert height_check.result == "UNVERIFIED"
    assert "different image/plane" in height_check.explanation


def test_report_model_and_summary_do_not_claim_false_compliance():
    inspection = {
        "id": "ins-1", "inspection_code": "INS-0001", "declarations": [],
        "checks": [{"result": "UNVERIFIED", "check_type": "CHARACTER_HEIGHT"}],
        "violations": [],
    }
    report = _build_report_model(inspection, {"sub": "officer-1"})
    summary = _violation_summary(inspection)

    assert report.overall_status == "NEEDS_REVIEW"
    assert report.pdp_area_cm2 is None
    assert report.calibration_status == "NOT_CALIBRATED"
    assert summary["review_or_unverified_count"] == 1
    assert summary["enforcement_ready"] is False


def test_failed_check_blocks_enforcement_even_without_materialized_finding():
    inspection = {
        "id": "ins-2", "checks": [{"result": "POTENTIAL_VIOLATION"}], "violations": []
    }
    report = _build_report_model(inspection, {"sub": "officer-1"})
    summary = _violation_summary(inspection)

    assert report.overall_status == "POTENTIAL_VIOLATION"
    assert summary["failed_check_count"] == 1
    assert summary["enforcement_ready"] is False


def test_server_pdf_contains_report_sections():
    report = _build_report_model(
        {
            "id": "ins-3", "inspection_code": "INS-0003", "score": 72.5,
            "checks": [{
                "rule_code": "RULE-009", "check_type": "READABILITY", "field_name": "mrp",
                "input_value": "Contrast: 12%", "expected_condition": "Legible",
                "result": "POTENTIAL_VIOLATION", "explanation": "Critically low contrast",
            }],
            "violations": [{"type": "ILLEGIBLE_DECLARATION", "severity": "HIGH", "explanation": "Low contrast"}],
            "declarations": [{"field_name": "mrp", "ai_value": "Rs 100", "presence_status": "DETECTED", "correctness_status": "VALID"}],
        },
        {"sub": "officer-1"},
    )
    payload = PdfReportGenerator.generate_pdf(report)

    assert payload.startswith(b"%PDF-")
    assert len(payload) > 1500
