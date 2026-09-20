from app.services.ocr.interface import IOcrService
from app.services.ocr.mock_ocr import MockOcrService
from app.services.ocr.paddle_ocr import PaddleOcrService
from app.services.ocr.groq_vision_ocr import GroqVisionOcrService
from app.core.config import settings

def get_ocr_service() -> IOcrService:
    provider = (settings.OCR_PROVIDER or "auto").strip().lower()
    if provider not in {"auto", "groq", "paddle", "mock"}:
        raise RuntimeError(
            f"Unsupported OCR_PROVIDER '{settings.OCR_PROVIDER}'. "
            "Use auto, groq, paddle, or mock."
        )

    if settings.MOCK_AI_MODE or provider == "mock":
        return MockOcrService()
    if provider == "groq":
        if not settings.GROQ_API_KEY:
            raise RuntimeError("OCR_PROVIDER=groq requires GROQ_API_KEY.")
        return GroqVisionOcrService()
    if provider == "paddle":
        return PaddleOcrService()
    if settings.GROQ_API_KEY:
        return GroqVisionOcrService()
    return PaddleOcrService()


def get_ocr_runtime_status() -> dict:
    """Return configuration readiness without calling a paid OCR provider."""
    provider = (settings.OCR_PROVIDER or "auto").strip().lower()
    if settings.MOCK_AI_MODE or provider == "mock":
        return {"ready": True, "provider": "mock", "live": False}
    if provider == "groq" or (provider == "auto" and settings.GROQ_API_KEY):
        return {
            "ready": bool(settings.GROQ_API_KEY),
            "provider": "groq",
            "live": bool(settings.GROQ_API_KEY),
        }
    try:
        import paddleocr  # noqa: F401
        return {"ready": True, "provider": "paddle", "live": True}
    except Exception:
        return {
            "ready": False,
            "provider": "paddle",
            "live": False,
            "reason": "Neither GROQ_API_KEY nor a local PaddleOCR runtime is available.",
        }
