import os
import cv2
import numpy as np
from typing import Dict, Any, Optional, Tuple
from app.core.logging import logger

class OpenCvVisionService:
    @staticmethod
    def assess_image_quality(image_path: str) -> Dict[str, Any]:
        """
        Assesses blur, lighting, contrast, and returns quality evaluation.
        """
        if not os.path.exists(image_path):
            return {
                "quality_score": 0.0,
                "assessment": "UNVERIFIED",
                "blur_score": None,
                "contrast_score": None,
                "sharpness_score": None,
                "reasons": ["Image file is unavailable for quality analysis."]
            }

        try:
            img = cv2.imread(image_path)
            if img is None:
                return {"quality_score": 0.5, "assessment": "NEEDS_RETAKE", "reasons": ["Unable to decode image"]}

            gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
            
            # 1. Blur via Laplacian variance
            lap_var = cv2.Laplacian(gray, cv2.CV_64F).var()
            
            # 2. Contrast via standard deviation
            std_dev = np.std(gray)
            contrast_score = min(1.0, std_dev / 64.0)

            # 3. Brightness/lighting
            mean_brightness = np.mean(gray)
            
            reasons = []
            if lap_var < 80.0:
                reasons.append("Image is blurry; text may not be sharp.")
            if contrast_score < 0.35:
                reasons.append("Low contrast between packaging and lighting.")
            if mean_brightness < 40 or mean_brightness > 230:
                reasons.append("Poor lighting conditions (too dark or washed out glare).")

            is_good = lap_var >= 80.0 and contrast_score >= 0.35 and (40 <= mean_brightness <= 230)
            score = round((min(lap_var, 400.0) / 400.0 * 0.5) + (contrast_score * 0.5), 2)

            return {
                "quality_score": score,
                "assessment": "GOOD" if is_good else "NEEDS_RETAKE",
                "blur_score": round(lap_var, 1),
                "contrast_score": round(contrast_score, 2),
                "sharpness_score": round(min(1.0, lap_var / 300.0), 2),
                "reasons": reasons
            }
        except Exception as e:
            logger.warning(f"Error in assess_image_quality: {e}")
            return {
                "quality_score": 0.0,
                "assessment": "UNVERIFIED",
                "blur_score": None,
                "contrast_score": None,
                "sharpness_score": None,
                "reasons": ["Image quality analysis failed."]
            }

    @staticmethod
    def evaluate_readability(crop_path: Optional[str], bbox: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        Evaluates contrast, sharpness, blur, and text-background separation.
        """
        if not crop_path or not os.path.exists(crop_path):
            return {
                "contrast": None, "sharpness": None, "blur": None,
                "status": "UNVERIFIED",
                "explanation": "No captured image is available for visual legibility analysis."
            }

        try:
            img = cv2.imread(crop_path)
            if img is None:
                return {"contrast": None, "sharpness": None, "blur": None, "status": "UNVERIFIED", "explanation": "Image could not be decoded for visual analysis."}
            if bbox:
                height, width = img.shape[:2]
                x = max(0, min(width, int(float(bbox.get("x", 0)))))
                y = max(0, min(height, int(float(bbox.get("y", 0)))))
                w = max(0, int(float(bbox.get("width", 0))))
                h = max(0, int(float(bbox.get("height", 0))))
                cropped = img[y:min(height, y + h), x:min(width, x + w)]
                if cropped.size:
                    img = cropped
            gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
            lap_var = cv2.Laplacian(gray, cv2.CV_64F).var()
            contrast = np.std(gray) / 128.0

            is_pass = lap_var >= 60.0 and contrast >= 0.30
            is_visual_failure = lap_var >= 80.0 and contrast < 0.18
            return {
                "contrast": round(min(1.0, contrast), 2),
                "sharpness": round(min(1.0, lap_var / 250.0), 2),
                "blur": round(lap_var, 1),
                "status": "PASS" if is_pass else ("POTENTIAL_VIOLATION" if is_visual_failure else "REVIEW"),
                "explanation": "Prominent and legible declaration." if is_pass else (
                    "Text edges are measurable but contrast against the label background is critically low."
                    if is_visual_failure else "Low text-to-background contrast or soft character edges; confirm with a clearer capture."
                )
            }
        except Exception as e:
            logger.warning(f"Error in evaluate_readability: {e}")
            return {"contrast": None, "sharpness": None, "blur": None, "status": "UNVERIFIED", "explanation": "Visual analysis failed; retake the image if needed."}

    @staticmethod
    def measure_character_geometry(image_path: Optional[str], bbox: Optional[Dict[str, Any]]) -> Dict[str, Any]:
        """Measures median connected-character geometry within an OCR-grounded crop."""
        if not image_path or not bbox or not os.path.exists(image_path):
            return {"status": "UNVERIFIED", "char_height_px": None, "char_width_px": None, "sample_count": 0,
                    "explanation": "OCR crop or source image unavailable for character measurement."}
        try:
            image = cv2.imread(image_path)
            if image is None:
                raise ValueError("Image could not be decoded")
            image_h, image_w = image.shape[:2]
            x = max(0, min(image_w, int(float(bbox.get("x", 0)))))
            y = max(0, min(image_h, int(float(bbox.get("y", 0)))))
            w = max(0, int(float(bbox.get("width", 0))))
            h = max(0, int(float(bbox.get("height", 0))))
            crop = image[y:min(image_h, y + h), x:min(image_w, x + w)]
            if crop.size == 0:
                raise ValueError("OCR bounding box is outside image bounds")
            gray = cv2.cvtColor(crop, cv2.COLOR_BGR2GRAY)
            binary = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)[1]
            count, _, stats, _ = cv2.connectedComponentsWithStats(binary, 8)
            components = []
            crop_area = max(1, crop.shape[0] * crop.shape[1])
            for idx in range(1, count):
                comp_w, comp_h, area = int(stats[idx, cv2.CC_STAT_WIDTH]), int(stats[idx, cv2.CC_STAT_HEIGHT]), int(stats[idx, cv2.CC_STAT_AREA])
                if 2 <= comp_w <= crop.shape[1] * 0.5 and 3 <= comp_h <= crop.shape[0] * 0.95 and 3 <= area <= crop_area * 0.25:
                    components.append((comp_w, comp_h))
            if not components:
                return {"status": "UNVERIFIED", "char_height_px": None, "char_width_px": None, "sample_count": 0,
                        "explanation": "No stable character components could be isolated in the declaration crop."}
            widths = [item[0] for item in components]
            heights = [item[1] for item in components]
            return {
                "status": "MEASURED",
                "char_height_px": round(float(np.median(heights)), 2),
                "char_width_px": round(float(np.median(widths)), 2),
                "sample_count": len(components),
                "explanation": f"Median character geometry measured from {len(components)} connected components.",
            }
        except Exception as exc:
            logger.warning("Error measuring character geometry: %s", exc)
            return {"status": "UNVERIFIED", "char_height_px": None, "char_width_px": None, "sample_count": 0,
                    "explanation": "Character geometry measurement failed."}

    @staticmethod
    def check_placement(bbox: dict, surface_type: str, rule_requirement: str = "PRINCIPAL_DISPLAY_PANEL") -> Dict[str, Any]:
        """
        Evaluates declaration location and relative surface placement.
        """
        surface_upper = (surface_type or "FRONT").upper()
        if rule_requirement == "PRINCIPAL_DISPLAY_PANEL":
            is_on_pdp = surface_upper in ["FRONT", "TOP"]
            return {
                "status": "PASS" if is_on_pdp else "REVIEW",
                "surface": surface_upper,
                "explanation": f"Declaration located on {surface_upper} surface." + (" Placed on Principal Display Panel." if is_on_pdp else " Mandatory declaration should appear on Principal Display Panel.")
            }
        return {
            "status": "PASS",
            "surface": surface_upper,
            "explanation": f"Declaration located on {surface_upper} surface."
        }

cv_service = OpenCvVisionService()
