import io

import pytest
from PIL import Image

from app.core.config import settings
from app.services.ocr import get_ocr_runtime_status, get_ocr_service
from app.services.ocr.groq_vision_ocr import GroqVisionOcrService
from app.services.ocr.mock_ocr import MockOcrService
from app.services.ocr.paddle_ocr import PaddleOcrService
from app.storage.file_storage import StorageManager


def _image_bytes(size=(320, 180), image_format="PNG") -> bytes:
    image = Image.new("RGB", size, "white")
    output = io.BytesIO()
    image.save(output, format=image_format)
    return output.getvalue()


def test_paddle_result_is_mapped_to_real_pixel_blocks():
    raw = [[
        [
            [[10, 20], [110, 20], [110, 50], [10, 50]],
            ("Net Qty 500 g", 0.97),
        ],
        [
            [[15, 70], [160, 70], [160, 100], [15, 100]],
            ("MRP Rs 80", 0.91),
        ],
    ]]

    result = PaddleOcrService._map_paddle_output(raw, "img-1", "FRONT")

    assert result.raw_text == "Net Qty 500 g\nMRP Rs 80"
    assert result.confidence == 0.94
    assert result.blocks[0].bbox.model_dump() == {
        "x": 10.0,
        "y": 20.0,
        "width": 100.0,
        "height": 30.0,
    }
    assert result.blocks[0].surface_type == "FRONT"


def test_groq_normalized_bbox_is_converted_and_clamped():
    bbox = GroqVisionOcrService._pixel_bbox([100, 200, 500, 100], 2000, 1000)
    assert bbox.model_dump() == {"x": 200.0, "y": 200.0, "width": 1000.0, "height": 100.0}

    clamped = GroqVisionOcrService._pixel_bbox([900, 950, 500, 500], 2000, 1000)
    assert clamped.model_dump() == {"x": 1800.0, "y": 950.0, "width": 200.0, "height": 50.0}


@pytest.mark.asyncio
async def test_image_storage_rejects_non_images_and_tiny_images(tmp_path):
    storage = StorageManager(str(tmp_path))

    with pytest.raises(ValueError, match="valid decodable image"):
        await storage.save_inspection_image("ins-1", b"not-an-image", "fake.jpg")

    with pytest.raises(ValueError, match="resolution is too small"):
        await storage.save_inspection_image("ins-1", _image_bytes((50, 50)), "tiny.png")


@pytest.mark.asyncio
async def test_image_storage_uses_decoded_format_not_filename(tmp_path):
    storage = StorageManager(str(tmp_path))
    original, thumbnail, width, height, digest = await storage.save_inspection_image(
        "ins-1", _image_bytes(), "misleading.exe"
    )

    assert original.endswith(".png")
    assert thumbnail.endswith(".jpg")
    assert (width, height) == (320, 180)
    assert len(digest) == 64


def test_mock_ocr_requires_explicit_demo_configuration(monkeypatch):
    monkeypatch.setattr(settings, "MOCK_AI_MODE", True)
    monkeypatch.setattr(settings, "OCR_PROVIDER", "auto")
    assert isinstance(get_ocr_service(), MockOcrService)

    status = get_ocr_runtime_status()
    assert status == {"ready": True, "provider": "mock", "live": False}


def test_groq_provider_without_key_fails_instead_of_fabricating(monkeypatch):
    monkeypatch.setattr(settings, "MOCK_AI_MODE", False)
    monkeypatch.setattr(settings, "OCR_PROVIDER", "groq")
    monkeypatch.setattr(settings, "GROQ_API_KEY", None)

    with pytest.raises(RuntimeError, match="requires GROQ_API_KEY"):
        get_ocr_service()
