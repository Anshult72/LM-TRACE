from typing import Dict, Any, List, Optional
from app.schemas.domain import ComplianceAssessmentResponse, ComplianceCheckResult
from app.engines.rule_engine.rule_engine import rule_engine
from app.services.vision.pdp_measurement_service import pdp_measurement_service, CalibrationStatus

class ComplianceEngine:
    async def evaluate_compliance(
        self,
        extracted_declarations: Dict[str, Any],
        correctness_data: Dict[str, Any],
        context: Dict[str, Any],
        readability_data: Optional[Dict[str, Any]] = None,
        placement_data: Optional[List[Dict[str, Any]]] = None,
    ) -> ComplianceAssessmentResponse:
        applicable_rules = await rule_engine.get_applicable_rules(context)
        requirements = rule_engine.determine_required_declarations(applicable_rules, context)

        checks: List[ComplianceCheckResult] = []
        review_items: List[Dict[str, Any]] = []
        violations: List[Dict[str, Any]] = []

        if context.get("rulesApplicable") is False:
            scope = context.get("marketScope", "NON_RETAIL")
            scope_check = ComplianceCheckResult(
                check_type="APPLICABILITY_SCOPE",
                field_name="market_scope",
                rule_code="RULE-003-SCOPE",
                rule_version="1.0",
                input_value=str(scope),
                expected_condition="Retail package within the applicable declaration scope",
                result="PASS",
                confidence=1.0,
                explanation=f"Package recorded as {scope}; retail-package declaration checks were not applied.",
                source_reference="Rule 3, Legal Metrology (Packaged Commodities) Rules, 2011",
            )
            return ComplianceAssessmentResponse(
                overall_status="PASS",
                score=100.0,
                score_breakdown={
                    "declarations_score": 100.0,
                    "legibility_score": 100.0,
                    "overall_score": 100.0,
                },
                passed_count=1,
                review_count=0,
                violation_count=0,
                unverified_count=0,
                checks=[scope_check],
                review_items=[],
                potential_violations=[],
            )

        matrix = correctness_data.get("matrix", []) if isinstance(correctness_data, dict) else []
        matrix_by_field = {
            item["field_name"]: item
            for item in matrix
            if isinstance(item, dict) and "field_name" in item
        }

        # The correctness screen groups manufacturer name and address into one
        # display card.  Legal-rule evaluation must still use the individual
        # OCR-grounded declarations, otherwise a present address/name can be
        # incorrectly reported as missing.
        matrix_aliases = {
            "manufacturer_name": "manufacturer",
            "manufacturer_address": "manufacturer",
            "packer_name": "packer",
            "packer_address": "packer",
            "importer_name": "importer",
            "importer_address": "importer",
            "manufacturing_date": "manufacturing_packing_date",
            "packing_date": "manufacturing_packing_date",
            "import_date": "manufacturing_packing_date",
        }

        def extracted_value(field: str) -> Any:
            value = extracted_declarations.get(field)
            if isinstance(value, dict):
                return value.get("value")
            return getattr(value, "value", None)

        # Resolve active statutory rule versions from applicable database rules
        decl_rule = rule_engine.get_rule_by_code_or_category(applicable_rules, "RULE-006-COMMODITY", "DECLARATIONS")
        decl_code = decl_rule.get("rule_code", "RULE-006") if decl_rule else "RULE-006"
        decl_ver = decl_rule.get("version", "2.0") if decl_rule else "2.0"
        decl_ref = decl_rule.get("statutory_reference", "Legal Metrology (Packaged Commodities) Rules, 2011 - Rule 6(1)") if decl_rule else "Rule 6(1)"

        pdp_rule = rule_engine.get_rule_by_code_or_category(applicable_rules, "RULE-007-CHAR-HEIGHT", "PDP_FONT_SIZE") or rule_engine.get_rule_by_code_or_category(applicable_rules, "RULE-007")
        pdp_code = pdp_rule.get("rule_code", "RULE-007-CHAR-HEIGHT") if pdp_rule else "RULE-007-CHAR-HEIGHT"
        pdp_ver = pdp_rule.get("version", "1.0") if pdp_rule else "1.0"
        pdp_ref = pdp_rule.get("statutory_reference", "Legal Metrology (Packaged Commodities) Rules, 2011 - Rule 7 & Table-I") if pdp_rule else "Rule 7 Table-I"

        prop_rule = rule_engine.get_rule_by_code_or_category(applicable_rules, "RULE-007-CHAR-RATIO") or rule_engine.get_rule_by_code_or_category(applicable_rules, "RULE-007")
        prop_code = prop_rule.get("rule_code", "RULE-007-CHAR-RATIO") if prop_rule else pdp_code
        prop_ver = prop_rule.get("version", "1.0") if prop_rule else pdp_ver
        prop_ref = prop_rule.get("statutory_reference", "Rule 7(3)") if prop_rule else "Rule 7(3)"

        leg_rule = rule_engine.get_rule_by_code_or_category(applicable_rules, "RULE-009-LEGIBILITY", "OTHER") or rule_engine.get_rule_by_code_or_category(applicable_rules, "RULE-009")
        leg_code = leg_rule.get("rule_code", "RULE-009-LEGIBILITY") if leg_rule else "RULE-009-LEGIBILITY"
        leg_ver = leg_rule.get("version", "1.0") if leg_rule else "1.0"
        leg_ref = leg_rule.get("statutory_reference", "Legal Metrology (Packaged Commodities) Rules, 2011 - Rule 9(1)") if leg_rule else "Rule 9(1)"

        mrp_rule = rule_engine.get_rule_by_code_or_category(applicable_rules, "RULE-006-MRP", "MRP")
        mrp_code = mrp_rule.get("rule_code", "RULE-006-MRP") if mrp_rule else "RULE-006-MRP"
        mrp_ver = mrp_rule.get("version", "2.0") if mrp_rule else "2.0"
        mrp_ref = mrp_rule.get("statutory_reference", "Legal Metrology (Packaged Commodities) Rules, 2011 - Rule 6(1)(e)") if mrp_rule else "Rule 6(1)(e)"

        usp_rule = rule_engine.get_rule_by_code_or_category(applicable_rules, "RULE-006-UNIT-SALE-PRICE", "MRP")
        usp_code = usp_rule.get("rule_code", "RULE-006-UNIT-SALE-PRICE") if usp_rule else "RULE-006-UNIT-SALE-PRICE"
        usp_ver = usp_rule.get("version", "1.0") if usp_rule else "1.0"
        usp_ref = usp_rule.get("statutory_reference", "Legal Metrology (Packaged Commodities) Rules, 2011 - Rule 6(11)") if usp_rule else "Rule 6(11)"

        ecom_rule = rule_engine.get_rule_by_code_or_category(applicable_rules, "RULE-ECOM-DECLARATIONS", "E_COMMERCE") or rule_engine.get_rule_by_code_or_category(applicable_rules, "RULE-ECOM")
        ecom_code = ecom_rule.get("rule_code", "RULE-ECOM-DECLARATIONS") if ecom_rule else "RULE-ECOM-DECLARATIONS"
        ecom_ver = ecom_rule.get("version", "1.0") if ecom_rule else "1.0"
        ecom_ref = ecom_rule.get("statutory_reference", "Legal Metrology (Packaged Commodities) Rules, 2011 - Rule 6(10)") if ecom_rule else "Rule 6(10)"

        def get_field_evidence(field: str) -> Optional[str]:
            val = extracted_declarations.get(field)
            if isinstance(val, dict):
                return val.get("source_block_id") or val.get("source_image_id")
            return getattr(val, "source_block_id", None) or getattr(val, "source_image_id", None)

        def get_field_bbox(field: str) -> Optional[Dict[str, Any]]:
            val = extracted_declarations.get(field)
            bbox = val.get("bbox") if isinstance(val, dict) else getattr(val, "bbox", None)
            return bbox.model_dump() if hasattr(bbox, "model_dump") else bbox

        if context.get("rulesApplicable", True) and not context.get("originTypeConfirmed", True):
            checks.append(ComplianceCheckResult(
                check_type="APPLICABILITY_CONTEXT",
                field_name="country_of_origin_type",
                rule_code="RULE-006-NAME-ADDR",
                rule_version="2.0",
                input_value="UNKNOWN",
                expected_condition="Officer must classify the commodity as domestic or imported",
                result="REVIEW",
                confidence=0.0,
                explanation="Import status could not be proven from package OCR; importer and country-of-origin applicability requires officer confirmation.",
                source_reference="Rule 6(1)(a), LM (Packaged Commodities) Rules, 2011",
            ))
            review_items.append({
                "type": "APPLICABILITY_REVIEW",
                "field": "country_of_origin_type",
                "severity": "HIGH",
                "confidence": 0.0,
                "explanation": "Confirm whether the packaged commodity is domestic or imported.",
            })

        if context.get("rulesApplicable", True) and context.get("electronicDeclarationsViaQr", False):
            checks.append(ComplianceCheckResult(
                check_type="DIGITAL_DECLARATION_ACCESS",
                field_name="qr_declarations",
                rule_code="RULE-006-DIGITAL",
                rule_version="1.0",
                input_value="Officer marked declarations as QR/electronically accessible",
                expected_condition="Open the code and capture the permitted digital declarations as evidence",
                result="REVIEW",
                confidence=0.0,
                explanation="A QR/electronic declaration cannot be treated as verified until its destination and declaration content are captured.",
                source_reference="Legal Metrology (Packaged Commodities) Rules, 2011 - Rule 6",
            ))
            review_items.append({
                "type": "DIGITAL_DECLARATION_REVIEW",
                "field": "qr_declarations",
                "severity": "HIGH",
                "confidence": 0.0,
                "explanation": "Open the QR/electronic declaration and capture its contents before final compliance confirmation.",
            })

        # 1. Evaluate Declaration Presence & Completeness against Requirements
        for field, req in requirements.items():
            is_req = req["required"]
            reason = req["reason"]
            rule_c = req.get("rule_code") or decl_code
            rule_v = req.get("rule_version") or decl_ver
            stat_ref = req.get("statutory_reference") or decl_ref
            candidate_fields = [field] + list(req.get("alternatives") or [])
            matched_field = next((candidate for candidate in candidate_fields if extracted_value(candidate)), field)
            mat_item = matrix_by_field.get(matched_field) or matrix_by_field.get(matrix_aliases.get(matched_field, ""))
            actual_value = extracted_value(matched_field)
            # Grouped correctness rows (manufacturer/importer/packer) may be
            # present when only one component exists. They must never make a
            # missing individual name/address look present.
            direct_matrix_match = isinstance(mat_item, dict) and mat_item.get("field_name") == matched_field
            is_present = bool(actual_value) or bool(direct_matrix_match and mat_item.get("presence"))
            evidence_id = get_field_evidence(matched_field) or (mat_item.get("source_block_id") if isinstance(mat_item, dict) else None)

            if is_req:
                if not is_present:
                    check_res = ComplianceCheckResult(
                        check_type="MANDATORY_DECLARATION",
                        field_name=field,
                        rule_code=rule_c,
                        rule_version=rule_v,
                        input_value=None,
                        expected_condition="Mandatory declaration must be present",
                        result="POTENTIAL_VIOLATION",
                        confidence=0.98,
                        explanation=f"Mandatory declaration '{field}' is absent from captured package surfaces ({reason}).",
                        source_reference=stat_ref,
                        evidence_id=evidence_id
                    )
                    checks.append(check_res)
                    violations.append({
                        "type": "MISSING_DECLARATION",
                        "field": field,
                        "severity": "HIGH",
                        "confidence": 0.98,
                        "explanation": f"Mandatory declaration '{field}' missing.",
                        "source_reference": stat_ref,
                    })
                else:
                    matrix_item = mat_item or {}
                    corr_status = matrix_item.get("correctness", "REVIEW")
                    input_value = actual_value or matrix_item.get("value")
                    if corr_status == "VALID":
                        checks.append(ComplianceCheckResult(
                            check_type="MANDATORY_DECLARATION",
                            field_name=field,
                            rule_code=rule_c,
                            rule_version=rule_v,
                            input_value=input_value,
                            expected_condition="Presence and valid format",
                            result="PASS",
                            confidence=matrix_item.get("confidence", 0.95),
                            explanation=f"Declaration '{field}' detected with valid format.",
                            source_reference=stat_ref,
                            evidence_id=evidence_id
                        ))
                    elif corr_status == "REVIEW":
                        completeness = matrix_item.get("completeness")
                        checks.append(ComplianceCheckResult(
                            check_type="DECLARATION_COMPLETENESS" if completeness == "INCOMPLETE" else "DECLARATION_CORRECTNESS",
                            field_name=field,
                            rule_code=rule_c,
                            rule_version=rule_v,
                            input_value=input_value,
                            expected_condition="Complete and standard declaration format",
                            result="REVIEW",
                            confidence=matrix_item.get("confidence", 0.85),
                            explanation=matrix_item.get("details") or f"Declaration '{field}' requires inspector review for completeness/standard formatting.",
                            source_reference=stat_ref,
                            evidence_id=evidence_id
                        ))
                        review_items.append({
                            "type": "CORRECTNESS_REVIEW",
                            "field": field,
                            "severity": "MEDIUM",
                            "confidence": 0.85,
                            "explanation": f"Incomplete or non-standard format for '{field}'."
                        })
                    else:
                        checks.append(ComplianceCheckResult(
                            check_type="DECLARATION_CORRECTNESS",
                            field_name=field,
                            rule_code=rule_c,
                            rule_version=rule_v,
                            input_value=input_value,
                            expected_condition="Statutory compliant declaration",
                            result="POTENTIAL_VIOLATION",
                            confidence=0.92,
                            explanation=matrix_item.get("details") or f"Declaration '{field}' fails correctness validation.",
                            source_reference=stat_ref,
                            evidence_id=evidence_id
                        ))
                        violations.append({
                            "type": "NON_COMPLIANT_DECLARATION",
                            "field": field,
                            "severity": "HIGH",
                            "confidence": 0.92,
                            "explanation": matrix_item.get("details") or f"Declaration '{field}' fails correctness check.",
                            "source_reference": stat_ref,
                            "bbox": get_field_bbox(matched_field),
                            "source_image_id": (extracted_declarations.get(matched_field) or {}).get("source_image_id") if isinstance(extracted_declarations.get(matched_field), dict) else None,
                        })
            else:
                # Optional or conditional check that is not applicable
                if is_present:
                    checks.append(ComplianceCheckResult(
                        check_type="OPTIONAL_DECLARATION",
                        field_name=field,
                        rule_code=rule_c,
                        rule_version=rule_v,
                        input_value=actual_value,
                        expected_condition="Non-mandatory statutory declaration",
                        result="PASS",
                        confidence=0.90,
                        explanation=f"Declaration '{field}' is optionally present on package.",
                        source_reference=stat_ref,
                        evidence_id=evidence_id
                    ))

        # 2. Rule 9 placement checks. A declaration is only auto-passed when
        # OCR provenance ties it to a captured package surface and valid bbox.
        for placement in placement_data or []:
            result = placement.get("status", "UNVERIFIED")
            field = placement.get("field_name", "package_declarations")
            checks.append(ComplianceCheckResult(
                check_type="PLACEMENT",
                field_name=field,
                rule_code=placement.get("rule_code", "RULE-009-PLACEMENT"),
                rule_version="1.0",
                input_value=placement.get("surface"),
                expected_condition="Declaration must be on the package/secure label and on an opaque outer wrapper when present",
                result=result,
                confidence=float(placement.get("confidence", 0.98 if result in {"PASS", "POTENTIAL_VIOLATION"} else 0.5)),
                explanation=placement.get("explanation", "Placement could not be verified."),
                source_reference=placement.get("statutory_reference", "Rule 9"),
                evidence_id=placement.get("source_block_id") or placement.get("source_image_id"),
            ))
            if result == "POTENTIAL_VIOLATION":
                violations.append({
                    "type": "NON_COMPLIANT_PLACEMENT",
                    "field": field,
                    "severity": "HIGH",
                    "confidence": 0.98,
                    "explanation": placement.get("explanation"),
                    "bbox": placement.get("bbox"),
                    "source_image_id": placement.get("source_image_id"),
                    "source_reference": placement.get("statutory_reference"),
                })
            elif result in {"REVIEW", "UNVERIFIED"}:
                review_items.append({
                    "type": "PLACEMENT_REVIEW",
                    "field": field,
                    "severity": "MEDIUM",
                    "confidence": 0.5,
                    "explanation": placement.get("explanation"),
                })

        # 3. Rule 7: Principal Display Panel Character & Numeral Height Check
        pdp_area = context.get("pdpAreaCm2")
        pkg_const = context.get("packageConstructionType") or "NORMAL"
        calib_status = context.get("calibrationStatus") or CalibrationStatus.NOT_CALIBRATED
        pixels_per_mm = context.get("pixelsPerMm")
        calibration_image_id = context.get("calibrationImageId")

        min_height_mm, table_range = pdp_measurement_service.resolve_rule_7_threshold(pdp_area, pkg_const)
        typography_results = (readability_data or {}).get("typography_results", [])
        for geometry in typography_results:
            field = geometry.get("field_name", "net_quantity")
            measured = geometry.get("status") == "MEASURED"
            measurement_confidence = float(geometry.get("measurement_confidence", 0.75 if geometry.get("sample_count", 0) >= 3 else 0.4))
            stable_measurement = geometry.get("sample_count", 0) >= 3 and measurement_confidence >= 0.65
            same_calibrated_plane = not calibration_image_id or geometry.get("source_image_id") == calibration_image_id
            can_measure_mm = measured and stable_measurement and same_calibrated_plane and min_height_mm is not None and calib_status == CalibrationStatus.CALIBRATED and pixels_per_mm
            if can_measure_mm:
                proportion_ratio = geometry.get("proportion_ratio")
                eval_width_px = (
                    float(proportion_ratio) * float(geometry["char_height_px"])
                    if proportion_ratio is not None else float(geometry["char_width_px"])
                )
                char_eval = pdp_measurement_service.evaluate_character_dimensions(
                    char_pixel_height=float(geometry["char_height_px"]),
                    char_pixel_width=eval_width_px,
                    pixels_per_mm=float(pixels_per_mm),
                    calibration_status=calib_status,
                    required_min_height_mm=float(min_height_mm),
                    character_str="A",
                )
                if not geometry.get("proportion_verified", False):
                    char_eval["proportion_status"] = "UNVERIFIED"
                    char_eval["explanation"] += " Character-level OCR alignment was insufficient to verify width proportion without including exempt narrow glyphs."
            else:
                ratio = round(float(geometry.get("char_width_px") or 0) / max(1.0, float(geometry.get("char_height_px") or 0)), 3)
                char_eval = {
                    "height_status": "UNVERIFIED", "proportion_status": "UNVERIFIED",
                    "measured_height_mm": None, "width_to_height_ratio": ratio,
                    "explanation": (
                        "The declaration is on a different image/plane from the active calibration."
                        if measured and stable_measurement and not same_calibrated_plane
                        else "Physical character size requires measured glyph geometry, PDP area and a calibrated pixel-to-millimetre scale."
                    ),
                }
            confidence = min(0.97, measurement_confidence) if can_measure_mm else min(0.5, measurement_confidence)
            checks.append(ComplianceCheckResult(
                check_type="CHARACTER_HEIGHT", field_name=field, rule_code=pdp_code, rule_version=pdp_ver,
                input_value=f"{char_eval['measured_height_mm']} mm" if char_eval.get("measured_height_mm") is not None else "UNVERIFIED",
                expected_condition=f"Minimum {min_height_mm} mm for PDP Area {pdp_area} cm² ({table_range})" if min_height_mm else "Calibrated PDP area required",
                result=char_eval["height_status"], confidence=confidence, explanation=char_eval["explanation"],
                source_reference=pdp_ref, evidence_id=get_field_evidence(geometry.get("matched_field") or field),
            ))
            checks.append(ComplianceCheckResult(
                check_type="CHARACTER_PROPORTION", field_name=field, rule_code=prop_code, rule_version=prop_ver,
                input_value=f"Width/Height Ratio: {char_eval['width_to_height_ratio']}",
                expected_condition="Width must be >= 1/3 of height, subject to character exceptions",
                result=char_eval["proportion_status"], confidence=confidence, explanation=char_eval["explanation"],
                source_reference=prop_ref, evidence_id=get_field_evidence(geometry.get("matched_field") or field),
            ))
            if char_eval["height_status"] == "POTENTIAL_VIOLATION":
                violations.append({"type": "INSUFFICIENT_FONT_SIZE", "field": field, "severity": "HIGH", "confidence": confidence,
                                   "explanation": f"Measured character height is below statutory minimum {min_height_mm} mm."})
            elif char_eval["height_status"] == "UNVERIFIED":
                review_items.append({"type": "UNVERIFIED_FONT_SIZE", "field": field, "severity": "MEDIUM", "confidence": confidence,
                                     "explanation": char_eval["explanation"]})
            if char_eval["proportion_status"] == "POTENTIAL_VIOLATION":
                violations.append({"type": "NON_COMPLIANT_CHARACTER_PROPORTION", "field": field, "severity": "HIGH", "confidence": confidence,
                                   "explanation": "Measured non-exempt character width is below one-third of its height."})
            elif char_eval["proportion_status"] == "UNVERIFIED":
                review_items.append({"type": "UNVERIFIED_CHARACTER_PROPORTION", "field": field, "severity": "MEDIUM", "confidence": confidence,
                                     "explanation": char_eval["explanation"]})

        if not typography_results and extracted_value("net_quantity"):
            checks.append(ComplianceCheckResult(
                check_type="CHARACTER_HEIGHT", field_name="net_quantity", rule_code=pdp_code, rule_version=pdp_ver,
                input_value="UNVERIFIED", expected_condition="Calibrated declaration character measurement",
                result="UNVERIFIED", confidence=0.0, explanation="No OCR-grounded character geometry was available.",
                source_reference=pdp_ref, evidence_id=get_field_evidence("net_quantity"),
            ))
            review_items.append({"type": "UNVERIFIED_FONT_SIZE", "field": "net_quantity", "severity": "MEDIUM", "confidence": 0.0,
                                 "explanation": "No OCR-grounded character geometry was available."})

        # 4. Rule 9 declaration-level legibility and readability checks.
        readability_results = (readability_data or {}).get("readability_results", [])
        if not readability_results and readability_data and "status" in readability_data:
            readability_results = [{"field_name": "mrp", "matched_field": "mrp", **readability_data}]
        for visual in readability_results:
            field = visual.get("field_name", "package_declarations")
            read_stat = visual.get("status", "UNVERIFIED")
            contrast, sharpness = visual.get("contrast"), visual.get("sharpness")
            input_value = f"Contrast: {contrast * 100:.0f}%, Sharpness: {sharpness * 100:.0f}%" if contrast is not None and sharpness is not None else "UNVERIFIED"
            checks.append(ComplianceCheckResult(
                check_type="READABILITY", field_name=field, rule_code=leg_code, rule_version=leg_ver,
                input_value=input_value, expected_condition="Conspicuous, prominent and legible declaration",
                result=read_stat, confidence=float(visual.get("confidence", 0.95 if read_stat in {"PASS", "POTENTIAL_VIOLATION"} else 0.5)),
                explanation=visual.get("explanation", "Visual legibility was not measured."), source_reference=leg_ref,
                evidence_id=get_field_evidence(visual.get("matched_field") or field),
            ))
            if read_stat == "POTENTIAL_VIOLATION":
                violations.append({"type": "ILLEGIBLE_DECLARATION", "field": field, "severity": "HIGH", "confidence": 0.95,
                                   "explanation": visual.get("explanation")})
            elif read_stat in {"REVIEW", "UNVERIFIED"}:
                review_items.append({"type": "READABILITY_REVIEW", "field": field, "severity": "MEDIUM", "confidence": 0.5,
                                     "explanation": visual.get("explanation")})

        # 4. E-Commerce Specific Checks (Rule 6(10) / RULE-006-ECOM)
        if context.get("isEcommerce", False):
            # Evaluate mandatory digital declarations for e-commerce listings
            ecom_exempt = {"manufacture_pack_import_date"}
            ecom_requirements = {
                field: req for field, req in requirements.items()
                if req.get("required") and field not in ecom_exempt
            }
            ecom_missing = []
            for field, req in ecom_requirements.items():
                candidates = [field] + list(req.get("alternatives") or [])
                if not any(extracted_value(candidate) for candidate in candidates):
                    ecom_missing.append(field)
            if not ecom_missing:
                checks.append(ComplianceCheckResult(
                    check_type="ECOMMERCE_DIGITAL_PDP",
                    field_name="e_commerce_declarations",
                    rule_code=ecom_code,
                    rule_version=ecom_ver,
                    input_value="All mandatory marketplace disclosures present",
                    expected_condition="Mandatory digital declarations on marketplace PDP",
                    result="PASS",
                    confidence=0.95,
                    explanation="All mandatory e-commerce declarations verified on digital listing.",
                    source_reference=ecom_ref
                ))
            else:
                checks.append(ComplianceCheckResult(
                    check_type="ECOMMERCE_DIGITAL_PDP",
                    field_name="e_commerce_declarations",
                    rule_code=ecom_code,
                    rule_version=ecom_ver,
                    input_value=f"Missing: {', '.join(ecom_missing)}",
                    expected_condition="Mandatory digital declarations on marketplace PDP",
                    result="POTENTIAL_VIOLATION",
                    confidence=0.95,
                    explanation=f"Marketplace PDP omits required statutory disclosures: {', '.join(ecom_missing)}.",
                    source_reference=ecom_ref
                ))
                violations.append({
                    "type": "ECOMMERCE_DISCLOSURE_VIOLATION",
                    "field": "e_commerce_declarations",
                    "severity": "HIGH",
                    "confidence": 0.95,
                    "explanation": f"E-commerce listing omits: {', '.join(ecom_missing)}."
                })

        # 5. Cross-Field Conflicts (Rule 18 MRP and Consistency)
        conflicts = correctness_data.get("conflicts", []) if isinstance(correctness_data, dict) else []
        for conf in conflicts:
            if not isinstance(conf, dict):
                continue
            c_field = conf.get("field_name", "general")
            # If issue involves MRP or pricing, cite Rule 18 Dual MRP
            rule_for_conf = mrp_code if c_field == "mrp" else decl_code
            ver_for_conf = mrp_ver if c_field == "mrp" else decl_ver
            ref_for_conf = mrp_ref if c_field == "mrp" else decl_ref
            
            checks.append(ComplianceCheckResult(
                check_type="CROSS_FIELD_CONSISTENCY",
                field_name=c_field,
                rule_code=rule_for_conf,
                rule_version=ver_for_conf,
                input_value=str(conf.get("source_values")),
                expected_condition="Consistent declarations across surfaces / No dual MRP",
                result="POTENTIAL_VIOLATION",
                confidence=0.95,
                explanation=conf.get("description", "Inconsistency across package faces."),
                source_reference=ref_for_conf,
                evidence_id=get_field_evidence(c_field)
            ))
            violations.append({
                "type": "CONFLICTING_DECLARATIONS",
                "field": c_field,
                "severity": "MEDIUM",
                "confidence": 0.95,
                "explanation": conf.get("description")
            })

        # Score calculation (analytical summary, not final legal judgment)
        passed_count = sum(1 for c in checks if c.result == "PASS")
        review_count = sum(1 for c in checks if c.result == "REVIEW")
        violation_count = sum(1 for c in checks if c.result == "POTENTIAL_VIOLATION")
        unverified_count = sum(1 for c in checks if c.result == "UNVERIFIED")

        total_eval = max(1, len(checks))
        raw_score = ((passed_count * 1.0) + (review_count * 0.7) + (unverified_count * 0.5)) / total_eval * 100.0
        score = round(raw_score, 1)

        # Status determination: Deterministic legal logic, NOT score cutoff
        if violation_count > 0:
            overall_status = "POTENTIAL_VIOLATION"
        elif review_count > 0 or unverified_count > 0:
            overall_status = "NEEDS_REVIEW"
        else:
            overall_status = "PASS"

        return ComplianceAssessmentResponse(
            overall_status=overall_status,
            score=score,
            score_breakdown={
                "declarations_score": round((passed_count / total_eval) * 100.0, 1),
                "legibility_score": 90.0,
                "overall_score": score
            },
            passed_count=passed_count,
            review_count=review_count,
            violation_count=violation_count,
            unverified_count=unverified_count,
            checks=checks,
            review_items=review_items,
            potential_violations=violations
        )

compliance_engine = ComplianceEngine()
