import pytest
import io
from PIL import Image
from httpx import AsyncClient, ASGITransport
from app.main import app

def _make_sample_png_bytes() -> bytes:
    img = Image.new('RGB', (100, 100), color=(73, 109, 137))
    buf = io.BytesIO()
    img.save(buf, format='PNG')
    return buf.getvalue()

_SAMPLE_PNG = _make_sample_png_bytes()

@pytest.mark.asyncio
async def test_backend_surface_validation_comprehensive():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # 1. Login to get token
        login_res = await ac.post(
            "/api/auth/login",
            json={"email": "inspector@demo.gov.in", "password": "Inspector@123"},
        )
        assert login_res.status_code == 200
        token = login_res.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # 2. Create a test inspection
        create_res = await ac.post(
            "/api/inspections",
            headers=headers,
            json={
                "location": "Verification Test Site",
                "seller_name": "Test Trader",
                "product_category": "Packaged Food",
                "inspection_type": "PHYSICAL",
            },
        )
        assert create_res.status_code == 200
        ins_id = create_res.json()["id"]

        # ----------------------------------------------------
        # TEST 1: ZERO IMAGES -> Blocked
        # ----------------------------------------------------
        analyze_zero = await ac.post(f"/api/inspections/{ins_id}/analyze", headers=headers)
        assert analyze_zero.status_code == 400
        err_detail = analyze_zero.json()["detail"]
        assert err_detail["code"] == "REQUIRED_IMAGES_MISSING"
        assert err_detail["required_count"] == 4
        assert err_detail["completed_count"] == 0
        assert len(err_detail["missing_surfaces"]) == 4

        # Verify GET /required-surfaces
        status_zero = await ac.get(f"/api/inspections/{ins_id}/required-surfaces", headers=headers)
        assert status_zero.status_code == 200
        data_zero = status_zero.json()
        assert data_zero["valid"] is False
        assert data_zero["completed_count"] == 0

        # ----------------------------------------------------
        # TEST 2: ONE IMAGE (FRONT) -> Blocked
        # ----------------------------------------------------
        await ac.post(
            f"/api/inspections/{ins_id}/images",
            headers=headers,
            data={"surface_type": "FRONT"},
            files={"file": ("front.png", io.BytesIO(_SAMPLE_PNG), "image/png")},
        )

        analyze_one = await ac.post(f"/api/inspections/{ins_id}/analyze", headers=headers)
        assert analyze_one.status_code == 400
        err_one = analyze_one.json()["detail"]
        assert err_one["code"] == "REQUIRED_IMAGES_MISSING"
        assert err_one["completed_count"] == 1
        assert "Front (PDP)" not in err_one["missing_surfaces"]
        assert "Back (Declarations)" in err_one["missing_surfaces"]
        assert "Side (Consumer Care)" in err_one["missing_surfaces"]
        assert "MRP & Date Stamp" in err_one["missing_surfaces"]

        # ----------------------------------------------------
        # TEST 3: TWO IMAGES (FRONT, BACK) -> Blocked
        # ----------------------------------------------------
        await ac.post(
            f"/api/inspections/{ins_id}/images",
            headers=headers,
            data={"surface_type": "BACK"},
            files={"file": ("back.png", io.BytesIO(_SAMPLE_PNG), "image/png")},
        )

        analyze_two = await ac.post(f"/api/inspections/{ins_id}/analyze", headers=headers)
        assert analyze_two.status_code == 400
        err_two = analyze_two.json()["detail"]
        assert err_two["completed_count"] == 2
        assert len(err_two["missing_surfaces"]) == 2
        assert "Side (Consumer Care)" in err_two["missing_surfaces"]
        assert "MRP & Date Stamp" in err_two["missing_surfaces"]

        # ----------------------------------------------------
        # TEST 4: THREE IMAGES (FRONT, BACK, SIDE) -> Blocked
        # ----------------------------------------------------
        await ac.post(
            f"/api/inspections/{ins_id}/images",
            headers=headers,
            data={"surface_type": "SIDE"},
            files={"file": ("side.png", io.BytesIO(_SAMPLE_PNG), "image/png")},
        )

        analyze_three = await ac.post(f"/api/inspections/{ins_id}/analyze", headers=headers)
        assert analyze_three.status_code == 400
        err_three = analyze_three.json()["detail"]
        assert err_three["completed_count"] == 3
        assert err_three["missing_surfaces"] == ["MRP & Date Stamp"]

        # ----------------------------------------------------
        # TEST 5: DUPLICATE SURFACE DOES NOT SATISFY MISSING
        # Upload another FRONT instead of MRP_AREA
        # ----------------------------------------------------
        await ac.post(
            f"/api/inspections/{ins_id}/images",
            headers=headers,
            data={"surface_type": "FRONT"},
            files={"file": ("front_duplicate.png", io.BytesIO(_SAMPLE_PNG), "image/png")},
        )

        analyze_dup = await ac.post(f"/api/inspections/{ins_id}/analyze", headers=headers)
        assert analyze_dup.status_code == 400
        assert analyze_dup.json()["detail"]["missing_surfaces"] == ["MRP & Date Stamp"]

        # ----------------------------------------------------
        # TEST 6: WRONG INSPECTION IMAGES DO NOT COUNT
        # Create second inspection, check that it has 0 completed
        # ----------------------------------------------------
        create_other = await ac.post(
            "/api/inspections",
            headers=headers,
            json={"location": "Other Site", "seller_name": "Other Trader"},
        )
        other_id = create_other.json()["id"]
        other_status = await ac.get(f"/api/inspections/{other_id}/required-surfaces", headers=headers)
        assert other_status.json()["completed_count"] == 0

        analyze_other = await ac.post(f"/api/inspections/{other_id}/analyze", headers=headers)
        assert analyze_other.status_code == 400
        assert analyze_other.json()["detail"]["completed_count"] == 0

        # ----------------------------------------------------
        # TEST 7: ALL FOUR SURFACES COMPLETE -> Analysis Starts!
        # Upload MRP_AREA to ins_id
        # ----------------------------------------------------
        await ac.post(
            f"/api/inspections/{ins_id}/images",
            headers=headers,
            data={"surface_type": "MRP_AREA"},
            files={"file": ("mrp.png", io.BytesIO(_SAMPLE_PNG), "image/png")},
        )

        status_four = await ac.get(f"/api/inspections/{ins_id}/required-surfaces", headers=headers)
        assert status_four.json()["valid"] is True
        assert status_four.json()["completed_count"] == 4
        assert len(status_four.json()["missing_surfaces"]) == 0

        analyze_four = await ac.post(f"/api/inspections/{ins_id}/analyze", headers=headers)
        assert analyze_four.status_code == 200
        assert analyze_four.json()["success"] is True
