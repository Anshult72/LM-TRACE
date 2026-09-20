import asyncio
import os
from typing import Any, List
from app.services.ocr.interface import IOcrService
from app.schemas.domain import BoundingBox, OcrBlock, OcrResult
from app.core.logging import logger

class PaddleOcrService(IOcrService):
    def __init__(self):
        self._ocr_engine = None
        self._initialization_error = None
        try:
            from paddleocr import PaddleOCR
            self._ocr_engine = PaddleOCR(use_angle_cls=True, lang='en')
            logger.info("Initialized real PaddleOCR engine.")
        except Exception as e:
            self._initialization_error = e
            logger.warning("PaddleOCR is unavailable: %s", e)

    @staticmethod
    def _map_paddle_output(raw_result: Any, image_id: str, surface_type: str) -> OcrResult:
        """Map PaddleOCR v2-style quadrilateral results into canonical OCR blocks."""
        page = raw_result
        if isinstance(page, list) and len(page) == 1 and isinstance(page[0], list):
            page = page[0]
        if not isinstance(page, list):
            page = []

        blocks: List[OcrBlock] = []
        for item in page:
            if not isinstance(item, (list, tuple)) or len(item) < 2:
                continue
            points, recognition = item[0], item[1]
            if not isinstance(recognition, (list, tuple)) or len(recognition) < 2:
                continue
            text = str(recognition[0] or "").strip()
            if not text or not isinstance(points, (list, tuple)) or len(points) < 2:
                continue
            try:
                xs = [float(point[0]) for point in points]
                ys = [float(point[1]) for point in points]
                confidence = max(0.0, min(1.0, float(recognition[1])))
            except (TypeError, ValueError, IndexError):
                continue
            x1, x2 = min(xs), max(xs)
            y1, y2 = min(ys), max(ys)
            blocks.append(OcrBlock(
                block_id=f"blk-{image_id}-{len(blocks) + 1}",
                text=text,
                confidence=confidence,
                bbox=BoundingBox(x=x1, y=y1, width=max(0.0, x2 - x1), height=max(0.0, y2 - y1)),
                image_id=image_id,
                surface_type=surface_type,
            ))

        return OcrResult(
            raw_text="\n".join(block.text for block in blocks),
            blocks=blocks,
            confidence=(round(sum(block.confidence for block in blocks) / len(blocks), 3) if blocks else 0.0),
            image_id=image_id,
        )

    async def extract_text(self, image_path: str, image_id: str, surface_type: str = "FRONT") -> OcrResult:
        if not os.path.isfile(image_path):
            raise FileNotFoundError(f"Captured image is unavailable: {image_path}")
        if self._ocr_engine is None:
            raise RuntimeError(
                "Live OCR is not configured. Set GROQ_API_KEY or install PaddleOCR; "
                "no mock declarations were generated."
            ) from self._initialization_error
        try:
            raw_result = await asyncio.to_thread(self._ocr_engine.ocr, image_path, cls=True)
            return self._map_paddle_output(raw_result, image_id, surface_type)
        except Exception as e:
            logger.exception("PaddleOCR execution failed for %s", image_id)
            raise RuntimeError(
                "Local OCR failed to process the captured image; no mock data was used."
            ) from e

    async def extract_text_from_images(self, image_items: List[dict]) -> List[OcrResult]:
        results = []
        for item in image_items:
            results.append(await self.extract_text(
                item.get("original_path", ""),
                item.get("id", "img-unknown"),
                item.get("surface_type", "FRONT"),
            ))
        return results
