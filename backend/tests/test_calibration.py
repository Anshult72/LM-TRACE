import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.services.vision.calibration_service import calibration_service
from app.services.vision.pdp_measurement_service import CalibrationStatus
from app.repositories import get_repository

@pytest.mark.asyncio
async def test_calibration_math_calculation():
    """TEST 1 & 2: Mathematical scale derivation."""
    # 200 px with 100 mm known distance -> 2.0 px/mm
    res1 = calibration_service.validate_and_calculate(
        point_a={"x": 100.0, "y": 100.0},
        point_b={"x": 300.0, "y": 100.0},
        known_distance_mm=100.0
    )
    assert res1["pixel_distance"] == 200.0
    assert res1["pixels_per_mm"] == 2.0
    assert res1["status"] == CalibrationStatus.CALIBRATED

    # 100 px with 50 mm known distance -> 2.0 px/mm
    res2 = calibration_service.validate_and_calculate(
        point_a={"x": 50.0, "y": 50.0},
        point_b={"x": 150.0, "y": 50.0},
        known_distance_mm=50.0
    )
    assert res2["pixel_distance"] == 100.0
    assert res2["pixels_per_mm"] == 2.0

@pytest.mark.asyncio
async def test_calibration_rejections():
    """TEST 3, 4, 5, 6: Validation rejections for invalid inputs."""
    # Zero physical distance
    with pytest.raises(ValueError, match="greater than 0"):
        calibration_service.validate_and_calculate(
            point_a={"x": 0.0, "y": 0.0},
            point_b={"x": 100.0, "y": 0.0},
            known_distance_mm=0.0
        )

    # Negative physical distance
    with pytest.raises(ValueError, match="greater than 0"):
        calibration_service.validate_and_calculate(
            point_a={"x": 0.0, "y": 0.0},
            point_b={"x": 100.0, "y": 0.0},
            known_distance_mm=-25.0
        )

    # Degenerate/identical points
    with pytest.raises(ValueError, match="too close together"):
        calibration_service.validate_and_calculate(
            point_a={"x": 100.0, "y": 100.0},
            point_b={"x": 102.0, "y": 101.0},
            known_distance_mm=50.0
        )

    # Coordinates outside image bounds
    with pytest.raises(ValueError, match="exceed native image"):
        calibration_service.validate_and_calculate(
            point_a={"x": 100.0, "y": 100.0},
            point_b={"x": 1500.0, "y": 100.0},
            known_distance_mm=100.0,
            image_width=1280,
            image_height=720
        )

@pytest.mark.asyncio
async def test_calibration_pdp_resolution():
    """Tests PDP area and Rule 7 Table-I minimum character height resolution."""
    # Custom verified area: 150 cm2 -> Rule 7 Table-I requires 2.5 mm for normal packaging
    pdp_cm2, min_h, label = calibration_service.resolve_pdp_context(
        inspection={},
        custom_pdp_area_cm2=150.0,
        package_construction_type="NORMAL"
    )
    assert pdp_cm2 == 150.0
    assert min_h == 2.5
    assert label == "100_LT_A_LE_500"

    # Blown / Formed packaging: requires 4.0 mm for 150 cm2
    pdp_cm2, min_h, label = calibration_service.resolve_pdp_context(
        inspection={},
        custom_pdp_area_cm2=150.0,
        package_construction_type="BLOWN_FORMED_MOLDED"
    )
    assert min_h == 4.0

    # Unknown PDP area when no data exists (never fabricate 320 cm2!)
    pdp_cm2, min_h, label = calibration_service.resolve_pdp_context(inspection={})
    assert pdp_cm2 is None
    assert min_h is None
    assert label == "UNKNOWN_PDP_AREA"

@pytest.mark.asyncio
async def test_calibration_declaration_measurements():
    """TEST 11: CV declaration measurements conversion from pixels to physical mm."""
    declarations = [
        {
            "field_name": "net_quantity",
            "bbox": {"x": 100, "y": 200, "width": 80, "height": 30},
            "char_height_px": 20.0,
            "char_width_px": 10.0,
            "ai_value": "5 kg"
        }
    ]
    # Scale: 4.0 px/mm -> 20 px / 4.0 = 5.0 mm. Required: 2.5 mm -> PASS
    measurements = calibration_service.derive_declaration_character_measurements(
        declarations=declarations,
        pixels_per_mm=4.0,
        min_height_mm=2.5
    )
    assert len(measurements) == 1
    m = measurements[0]
    assert m["field_name"] == "net_quantity"
    assert m["measured_height_mm"] == 5.0
    assert m["measured_width_mm"] == 2.5
    assert m["status"] == "PASS"


def test_calibration_preview_never_substitutes_line_bbox_for_character_height():
    measurements = calibration_service.derive_declaration_character_measurements(
        declarations=[{
            "id": "dec-1", "field_name": "mrp", "ai_value": "Rs 100",
            "bbox": {"x": 10, "y": 10, "width": 120, "height": 30},
        }],
        pixels_per_mm=4.0,
        min_height_mm=2.5,
    )
    assert measurements[0]["status"] == "UNVERIFIED"
    assert measurements[0]["physical_height_mm"] == 0.0
    assert "not used as a substitute" in measurements[0]["explanation"]

@pytest.mark.asyncio
async def test_calibration_api_lifecycle():
    """TEST 7, 8, 9, 10, 13: End-to-end API lifecycle, persistence, superseding and audit logging."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # Obtain auth token
        login_res = await client.post("/api/auth/login", json={
            "email": "inspector@demo.gov.in",
            "password": "Inspector@123"
        })
        assert login_res.status_code == 200
        token = login_res.json()["access_token"]
        auth_headers = {"Authorization": f"Bearer {token}"}

        # Create a new draft inspection
        create_resp = await client.post(
            "/api/inspections",
            headers=auth_headers,
            json={
                "inspection_type": "PHYSICAL",
                "location": "Calibration Lab, Delhi",
                "seller_name": "Test Trader",
                "business_name": "Test Enterprise",
                "product_category": "Packaged Food",
                "package_type": "RECTANGULAR",
                "package_construction_type": "NORMAL",
                "applicability_context": {}
            }
        )
        assert create_resp.status_code == 200
        ins_id = create_resp.json()["id"]

        # Preview calibration without saving
        prev_resp = await client.post(
            f"/api/inspections/{ins_id}/calibrations/preview",
            headers=auth_headers,
            json={
                "reference_type": "RULER",
                "point_a": {"x": 100.0, "y": 200.0},
                "point_b": {"x": 500.0, "y": 200.0},
                "known_distance_mm": 100.0,
                "custom_pdp_area_cm2": 200.0
            }
        )
        assert prev_resp.status_code == 200
        prev_data = prev_resp.json()
        assert prev_data["pixel_distance"] == 400.0
        assert prev_data["pixels_per_mm"] == 4.0
        assert prev_data["required_min_height_mm"] == 2.5

        # Save first calibration
        save1_resp = await client.post(
            f"/api/inspections/{ins_id}/calibrations",
            headers=auth_headers,
            json={
                "reference_type": "RULER",
                "point_a": {"x": 100.0, "y": 200.0},
                "point_b": {"x": 500.0, "y": 200.0},
                "known_distance_mm": 100.0,
                "custom_pdp_area_cm2": 200.0
            }
        )
        assert save1_resp.status_code == 201
        cal1 = save1_resp.json()
        assert cal1["calibration_status"] == "VALID"
        assert cal1["pixels_per_unit"] == 4.0

        # Save second calibration (re-calibration) -> should mark first as SUPERSEDED
        save2_resp = await client.post(
            f"/api/inspections/{ins_id}/calibrations",
            headers=auth_headers,
            json={
                "reference_type": "KNOWN_PACKAGE_DIMENSION",
                "reference_description": "Known package width 80mm",
                "point_a": {"x": 100.0, "y": 200.0},
                "point_b": {"x": 420.0, "y": 200.0},
                "known_distance_mm": 80.0
            }
        )
        assert save2_resp.status_code == 201
        cal2 = save2_resp.json()
        assert cal2["calibration_status"] == "VALID"
        assert cal2["pixels_per_unit"] == 4.0

        # Verify calibrations list (history)
        list_resp = await client.get(
            f"/api/inspections/{ins_id}/calibrations",
            headers=auth_headers
        )
        assert list_resp.status_code == 200
        cal_list = list_resp.json()
        assert len(cal_list) == 2
        # Latest should be VALID, older should be SUPERSEDED
        assert cal_list[0]["id"] == cal2["id"]
        assert cal_list[0]["calibration_status"] == "VALID"
        assert cal_list[1]["id"] == cal1["id"]
        assert cal_list[1]["calibration_status"] == "SUPERSEDED"

        # Verify active calibration endpoint
        active_resp = await client.get(
            f"/api/inspections/{ins_id}/calibrations/active",
            headers=auth_headers
        )
        assert active_resp.status_code == 200
        active_data = active_resp.json()
        assert active_data["id"] == cal2["id"]

        # Verify inspection object has updated calibration
        ins_resp = await client.get(f"/api/inspections/{ins_id}", headers=auth_headers)
        ins_data = ins_resp.json()
        assert ins_data["calibration_status"] == "CALIBRATED"
        assert ins_data["calibration_data"]["pixelsPerMm"] == 4.0
