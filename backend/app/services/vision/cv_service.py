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
            if gray.shape[0] < 8 or gray.shape[1] < 8:
                return {
                    "contrast": None, "sharpness": None, "blur": None, "status": "UNVERIFIED",
                    "explanation": "Declaration crop is too small for reliable visual legibility analysis.",
                    "reasons": ["Crop dimensions are below 8 pixels."], "confidence": 0.0,
                }

            # Percentile contrast is more robust than global standard deviation
            # on coloured/gradient packaging.  Glare and shadow ratios catch
            # washed-out or underexposed text that a sharpness score can miss.
            p05, p95 = np.percentile(gray, [5, 95])
            dynamic_range = float(p95 - p05)
            contrast = min(1.0, dynamic_range / 180.0)
            lap_var = float(cv2.Laplacian(gray, cv2.CV_64F).var())
            sharpness = min(1.0, lap_var / 250.0)
            mean_brightness = float(np.mean(gray))
            glare_ratio = float(np.mean(gray >= 248))
            shadow_ratio = float(np.mean(gray <= 12))
            edges = cv2.Canny(gray, 60, 180)
            edge_density = float(np.count_nonzero(edges)) / float(edges.size)

            reasons = []
            if lap_var < 45.0:
                reasons.append("Character edges are blurred or out of focus.")
            if contrast < 0.22:
                reasons.append("Text-to-background tonal separation is critically low.")
            if mean_brightness < 35.0 or shadow_ratio > 0.70:
                reasons.append("Declaration crop is substantially underexposed.")
            if (mean_brightness > 245.0 or glare_ratio > 0.82) and contrast < 0.28:
                reasons.append("Declaration crop is washed out or affected by glare.")
            if edge_density < 0.01:
                reasons.append("Too few stable character edges were detected.")

            critical_failures = sum([
                lap_var < 25.0,
                contrast < 0.14,
                mean_brightness < 25.0 or (mean_brightness > 248.0 and contrast < 0.20),
                (glare_ratio > 0.88 and contrast < 0.20) or shadow_ratio > 0.82,
                edge_density < 0.004,
            ])
            is_pass = (
                lap_var >= 60.0 and contrast >= 0.28 and 25.0 <= mean_brightness <= 250.0
                and shadow_ratio <= 0.70 and edge_density >= 0.01
            )
            status = "PASS" if is_pass else ("POTENTIAL_VIOLATION" if critical_failures >= 2 else "REVIEW")
            if status != "PASS" and not reasons:
                reasons.append("Legibility metrics are borderline; officer verification or a closer retake is required.")
            confidence = 0.95 if is_pass else (0.9 if status == "POTENTIAL_VIOLATION" else 0.65)
            return {
                "contrast": round(min(1.0, contrast), 2),
                "sharpness": round(sharpness, 2),
                "blur": round(lap_var, 1),
                "brightness": round(mean_brightness, 1),
                "dynamic_range": round(dynamic_range, 1),
                "glare_ratio": round(glare_ratio, 3),
                "shadow_ratio": round(shadow_ratio, 3),
                "edge_density": round(edge_density, 4),
                "status": status,
                "confidence": confidence,
                "reasons": reasons,
                "explanation": "Prominent and legible declaration." if is_pass else " ".join(reasons),
            }
        except Exception as e:
            logger.warning(f"Error in evaluate_readability: {e}")
            return {"contrast": None, "sharpness": None, "blur": None, "status": "UNVERIFIED", "explanation": "Visual analysis failed; retake the image if needed."}

    @staticmethod
    def measure_character_geometry(
        image_path: Optional[str],
        bbox: Optional[Dict[str, Any]],
        source_text: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Measures robust lower-bound character geometry in an OCR crop.

        The lower quartile, rather than the largest or average component, is
        used for statutory minimum-height evaluation.  Extreme components are
        removed with an IQR filter and the result carries measurement
        dispersion/confidence so noisy segmentation cannot silently pass.
        """
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
            gray = cv2.GaussianBlur(gray, (3, 3), 0)
            binary = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)[1]
            if np.mean(binary > 0) > 0.60:
                binary = cv2.bitwise_not(binary)
            binary = cv2.morphologyEx(binary, cv2.MORPH_OPEN, np.ones((2, 2), np.uint8))
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
            heights_arr = np.asarray([item[1] for item in components], dtype=float)
            q1, q3 = np.percentile(heights_arr, [25, 75])
            iqr = max(1.0, float(q3 - q1))
            filtered = [item for item in components if q1 - 1.5 * iqr <= item[1] <= q3 + 1.5 * iqr]
            if len(filtered) < 2:
                filtered = components
            widths = np.asarray([item[0] for item in filtered], dtype=float)
            heights = np.asarray([item[1] for item in filtered], dtype=float)
            ratios = widths / np.maximum(heights, 1.0)
            coefficient_of_variation = float(np.std(heights) / max(1.0, np.mean(heights)))
            sample_factor = min(1.0, len(filtered) / 8.0)
            stability_factor = max(0.0, 1.0 - min(1.0, coefficient_of_variation))
            confidence = round(0.35 + 0.4 * sample_factor + 0.25 * stability_factor, 3)

            # Narrow glyphs (1, I, i, l) are exempt from the one-third rule.
            # Only publish an automatic proportion measurement if OCR text and
            # segmented glyph counts align closely enough to remove them.
            alnum_chars = [char for char in (source_text or "") if char.isalnum()]
            proportion_ratios = list(ratios)
            proportion_verified = False
            if alnum_chars and abs(len(alnum_chars) - len(filtered)) <= max(1, round(len(filtered) * 0.2)):
                paired = zip(alnum_chars[:len(filtered)], ratios[:len(alnum_chars)])
                proportion_ratios = [float(ratio) for char, ratio in paired if char not in {"1", "i", "I", "l"}]
                proportion_verified = bool(proportion_ratios)
            return {
                "status": "MEASURED",
                "char_height_px": round(float(np.percentile(heights, 25)), 2),
                "char_width_px": round(float(np.percentile(widths, 25)), 2),
                "median_char_height_px": round(float(np.median(heights)), 2),
                "min_char_height_px": round(float(np.min(heights)), 2),
                "height_dispersion": round(coefficient_of_variation, 3),
                "proportion_ratio": round(float(np.min(proportion_ratios)), 3) if proportion_verified else None,
                "proportion_verified": proportion_verified,
                "sample_count": len(filtered),
                "measurement_confidence": confidence,
                "explanation": f"Lower-quartile character geometry measured from {len(filtered)} stable components.",
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
