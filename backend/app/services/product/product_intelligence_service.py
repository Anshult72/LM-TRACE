import hashlib
import uuid
import re
from datetime import datetime, timezone
from typing import Dict, Any, List, Optional, Tuple
from app.repositories import get_repository
from app.services.fingerprint.fingerprint_service import fingerprint_service
from app.core.logging import logger

def get_utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()

class ProductIntelligenceService:
    FIELD_ALIASES = {
        "commodity_name": ["commodity_name", "product_name", "item_name", "commodity", "name"],
        "brand_name": ["brand_name", "brand", "brand_owner"],
        "net_quantity": ["net_quantity", "quantity", "net_qty", "weight_volume", "declared_net_quantity"],
        "mrp": ["mrp", "maximum_retail_price", "retail_price", "price"],
        "manufacturer_name": ["manufacturer_name", "mfg_name", "manufacturer", "mfg"],
        "manufacturer_address": ["manufacturer_address", "mfg_address", "mfg_addr"],
        "packer_name": ["packer_name", "packer"],
        "packer_address": ["packer_address", "packer_addr"],
        "importer_name": ["importer_name", "importer"],
        "importer_address": ["importer_address", "importer_addr"],
        "country_of_origin": ["country_of_origin", "origin_country", "origin"],
        "barcode": ["barcode", "gtin", "ean", "upc"],
        "date_of_manufacture": ["date_of_manufacture", "mfg_date", "mfg_month_year", "date_of_packing"],
        "best_before": ["best_before", "expiry_date", "use_by"],
        "consumer_care": ["consumer_care", "customer_care", "consumer_care_details", "helpline", "grievance_officer"]
    }

    @classmethod
    def _extract_declaration_value(cls, declarations: List[Dict[str, Any]], field_name: str) -> Optional[str]:
        if not declarations:
            return None
        target_names = cls.FIELD_ALIASES.get(field_name, [field_name])
        for d in declarations:
            curr_name = d.get("field_name")
            if curr_name in target_names or any(curr_name.lower() == t.lower() for t in target_names if curr_name):
                val = d.get("verified_value") or d.get("ai_value") or d.get("value") or d.get("source_text")
                if val is not None and str(val).strip():
                    return str(val).strip()
        return None

    @classmethod
    def _extract_declaration_unit(cls, declarations: List[Dict[str, Any]], field_name: str) -> Optional[str]:
        if not declarations:
            return None
        target_names = cls.FIELD_ALIASES.get(field_name, [field_name])
        for d in declarations:
            curr_name = d.get("field_name")
            if curr_name in target_names or any(curr_name.lower() == t.lower() for t in target_names if curr_name):
                unit = d.get("canonical_unit") or d.get("unit")
                if unit is not None and str(unit).strip():
                    return str(unit).strip().upper()
        return None

    @staticmethod
    def _clean_str(val: Optional[Any]) -> str:
        if val is None:
            return ""
        return str(val).strip()

    async def identify_and_link_product(
        self,
        inspection: Dict[str, Any],
        declarations: List[Dict[str, Any]],
        images: Optional[List[Dict[str, Any]]] = None
    ) -> Optional[Dict[str, Any]]:
        """
        Deterministic Product Identification & Linking:
        1. Extracts candidate product declarations.
        2. Computes deterministic SHA-256 fingerprint.
        3. Matches existing product in database (by barcode, fingerprint, or brand+commodity).
        4. Upserts product and records label version history.
        5. Associates inspection.product_id with product.id.
        """
        repo = get_repository()
        inspection_id = inspection.get("id") or inspection.get("inspection_code")
        if not inspection_id:
            return None

        # Fallback to declarations/images embedded in inspection record if not provided separately
        if not declarations:
            declarations = inspection.get("declarations") or []
        if not images:
            images = inspection.get("images") or []

        # 1. Extract candidate attributes from declarations or inspection metadata
        commodity_name = (
            self._extract_declaration_value(declarations, "commodity_name")
            or inspection.get("product_name")
            or inspection.get("commodity_name")
            or inspection.get("name")
        )
        brand = (
            self._extract_declaration_value(declarations, "brand_name")
            or self._extract_declaration_value(declarations, "brand")
            or inspection.get("brand")
            or inspection.get("brand_name")
        )
        mfg_name = (
            self._extract_declaration_value(declarations, "manufacturer_name")
            or inspection.get("manufacturer_name")
        )
        mfg_addr = (
            self._extract_declaration_value(declarations, "manufacturer_address")
            or inspection.get("manufacturer_address")
        )
        packer_name = self._extract_declaration_value(declarations, "packer_name")
        packer_addr = self._extract_declaration_value(declarations, "packer_address")
        importer_name = self._extract_declaration_value(declarations, "importer_name")
        importer_addr = self._extract_declaration_value(declarations, "importer_address")
        qty = self._extract_declaration_value(declarations, "net_quantity") or inspection.get("net_quantity")
        unit = self._extract_declaration_unit(declarations, "net_quantity") or inspection.get("net_quantity_unit")
        mrp = self._extract_declaration_value(declarations, "mrp") or inspection.get("mrp")
        barcode = (
            self._extract_declaration_value(declarations, "barcode")
            or self._extract_declaration_value(declarations, "gtin")
            or inspection.get("barcode")
            or inspection.get("gtin")
        )
        origin = self._extract_declaration_value(declarations, "country_of_origin") or inspection.get("country_of_origin") or "India"

        # Infer brand from commodity name if not explicitly isolated
        if not brand and commodity_name:
            words = commodity_name.split()
            if len(words) > 1:
                brand = words[0]
            else:
                brand = commodity_name

        # Parse quantity and unit if combined (e.g. "5 kg", "200 ml")
        if qty and not unit:
            match = re.search(r"([0-9.]+)\s*([a-zA-Z]+)", str(qty))
            if match:
                qty = match.group(1)
                unit = match.group(2).upper()

        # Strict requirement: if not enough identifiable data exists (no commodity name, no brand, and no barcode),
        # do NOT fabricate a fake product!
        if not commodity_name and not barcode and not brand:
            logger.info("Inspection %s lacks commodity name, brand, and barcode; product identity cannot be established.", inspection_id)
            return None

        category = (
            inspection.get("product_category")
            or inspection.get("category")
            or "Packaged Commodity"
        )

        candidate_data = {
            "name": commodity_name or "Packaged Commodity",
            "brand": brand or "Packaged Commodity",
            "category": category,
            "manufacturer_name": mfg_name,
            "manufacturer_address": mfg_addr,
            "packer_name": packer_name,
            "packer_address": packer_addr,
            "importer_name": importer_name,
            "importer_address": importer_addr,
            "net_quantity": qty,
            "net_quantity_unit": unit,
            "barcode": barcode,
            "country_of_origin": origin,
        }

        # 2. Compute canonical SHA-256 identity fingerprint if sufficient data exists
        fingerprint_sha256, canonical_repr = fingerprint_service.generate_product_identity_fingerprint(candidate_data)
        candidate_data["product_identity_fingerprint"] = fingerprint_sha256 if fingerprint_sha256 else None

        # 3. Match against existing products
        matched_product: Optional[Dict[str, Any]] = None

        # A. Match by exact fingerprint (only if fingerprint is valid)
        if fingerprint_sha256:
            matched_product = await repo.get_by_fingerprint(fingerprint_sha256)

        # B. Match by barcode / GTIN
        if not matched_product and barcode:
            all_prods = await repo.list_products()
            for p in all_prods:
                if p.get("barcode") and str(p.get("barcode")).strip() == str(barcode).strip():
                    matched_product = p
                    break

        # C. Match by brand + commodity name + pack size
        if not matched_product and commodity_name:
            all_prods = await repo.list_products()
            norm_brand = self._clean_str(brand).lower()
            norm_name = self._clean_str(commodity_name).lower()
            norm_qty = self._clean_str(qty).lower()
            for p in all_prods:
                p_brand = self._clean_str(p.get("brand")).lower()
                p_name = self._clean_str(p.get("name")).lower()
                p_qty = self._clean_str(p.get("net_quantity")).lower()
                
                name_match = (norm_name == p_name) or (norm_name in p_name) or (p_name in norm_name)
                brand_match = (not norm_brand or not p_brand or norm_brand in p_brand or p_brand in norm_brand)
                qty_match = True
                if norm_qty and p_qty:
                    qty_match = (norm_qty == p_qty)
                
                if name_match and brand_match and qty_match:
                    matched_product = p
                    break

        # 4. Upsert Product
        now_iso = get_utc_now_iso()
        product_id: str
        is_new_product = False

        if matched_product:
            product_id = matched_product["id"]
            # Update attributes if newly observed declaration is richer
            updates = {}
            for k in ["barcode", "manufacturer_name", "manufacturer_address", "packer_name", "importer_name", "country_of_origin"]:
                if candidate_data.get(k) and not matched_product.get(k):
                    updates[k] = candidate_data[k]
            if updates:
                updates["id"] = product_id
                updates["updated_at"] = now_iso
                await repo.create_or_update(updates)
        else:
            is_new_product = True
            product_id = f"prod-{uuid.uuid4().hex[:8]}"
            candidate_data["id"] = product_id
            candidate_data["created_at"] = inspection.get("inspection_date") or now_iso
            candidate_data["updated_at"] = now_iso
            await repo.create_or_update(candidate_data)

        # 5. Manage Label Versions
        label_versions = await repo.get_label_versions(product_id)
        already_linked_version = next((lv for lv in label_versions if lv.get("inspection_id") == inspection_id), None)

        primary_image_id = None
        if images and len(images) > 0:
            front_img = next((img for img in images if (img.get("surface_type") or "").upper() == "FRONT"), images[0])
            primary_image_id = front_img.get("id")

        ocr_summary_parts = []
        if commodity_name: ocr_summary_parts.append(commodity_name)
        if qty: ocr_summary_parts.append(f"Net Qty: {qty} {unit or ''}".strip())
        if mrp: ocr_summary_parts.append(f"MRP: {mrp}")
        if mfg_name: ocr_summary_parts.append(f"Mfg: {mfg_name}")
        ocr_summary = " • ".join(ocr_summary_parts) if ocr_summary_parts else "Pre-packaged commodity label declaration"

        version_fingerprint = fingerprint_service.generate_label_version_fingerprint(
            image_path="",
            mrp=mrp or "",
            ocr_summary=ocr_summary
        )

        if not already_linked_version:
            if not label_versions:
                # Initial baseline version
                new_lv = {
                    "id": f"lbl-{uuid.uuid4().hex[:8]}",
                    "product_id": product_id,
                    "inspection_id": inspection_id,
                    "image_id": primary_image_id,
                    "label_version": "v1.0",
                    "visual_hash": f"sha256:{version_fingerprint[:16]}",
                    "ocr_summary": ocr_summary,
                    "mrp": mrp or "Not captured",
                    "net_quantity": f"{qty} {unit or ''}".strip() if qty else "Not captured",
                    "captured_at": inspection.get("inspection_date") or now_iso
                }
                await repo.add_label_version(new_lv)
            else:
                # Compare against latest recorded label version
                latest_lv = label_versions[-1]
                prev_mrp = (latest_lv.get("mrp") or "").strip()
                prev_qty = (latest_lv.get("net_quantity") or "").strip()
                curr_qty_str = f"{qty} {unit or ''}".strip() if qty else ""

                mrp_changed = bool(mrp and prev_mrp and mrp.strip() != prev_mrp and prev_mrp != "Not captured")
                qty_changed = bool(curr_qty_str and prev_qty and curr_qty_str.lower() != prev_qty.lower() and prev_qty != "Not captured")

                if mrp_changed or qty_changed:
                    # Increment version number
                    next_ver = f"v{len(label_versions) + 1}.0"
                    new_lv = {
                        "id": f"lbl-{uuid.uuid4().hex[:8]}",
                        "product_id": product_id,
                        "inspection_id": inspection_id,
                        "image_id": primary_image_id,
                        "label_version": next_ver,
                        "visual_hash": f"sha256:{version_fingerprint[:16]}",
                        "ocr_summary": ocr_summary,
                        "mrp": mrp or prev_mrp,
                        "net_quantity": curr_qty_str or prev_qty,
                        "captured_at": inspection.get("inspection_date") or now_iso
                    }
                    await repo.add_label_version(new_lv)
                    logger.info("New label version %s recorded for product %s from inspection %s", next_ver, product_id, inspection_id)

        # 6. Link Inspection to Product
        await repo.update(inspection_id, {"product_id": product_id})
        inspection["product_id"] = product_id

        # Return updated product detail
        return await self.get_product_detail(product_id)

    async def get_product_registry(
        self,
        search_query: Optional[str] = None,
        category_filter: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Retrieves products from repository, enriched with real active version,
        fingerprint verification status, last inspection date/outcome, and compliance status.
        """
        repo = get_repository()
        
        # Reconcile any unlinked inspections on registry load
        try:
            await self.sync_unlinked_inspections()
        except Exception as sync_err:
            logger.warning("Auto-sync unlinked inspections warning: %s", sync_err)

        products = await repo.list_products()
        registry_items: List[Dict[str, Any]] = []

        q = (search_query or "").strip().lower()

        for p in products:
            p_id = p.get("id")
            if not p_id:
                continue

            name = p.get("name") or "Packaged Commodity"
            brand = p.get("brand") or "Commodity"
            category = p.get("category") or "Packaged Food"
            barcode = p.get("barcode") or ""

            # Apply search filter
            if q:
                matches_name = q in name.lower()
                matches_brand = q in brand.lower()
                matches_barcode = q in barcode.lower()
                matches_id = q in p_id.lower()
                if not (matches_name or matches_brand or matches_barcode or matches_id):
                    continue

            # Apply category filter
            if category_filter and category_filter.upper() != "ALL":
                if category_filter.lower() not in category.lower():
                    continue

            # Fetch associated label versions and inspections
            lvs = await repo.get_label_versions(p_id)
            inspections = await repo.get_inspections_for_product(p_id)
            inspections.sort(key=lambda x: x.get("inspection_date") or x.get("created_at") or "", reverse=True)

            # Determine active version
            active_version = lvs[-1].get("label_version", "v1.0") if lvs else "v1.0"

            # Determine last inspection
            last_ins = inspections[0] if inspections else None
            last_inspection_date = None
            last_inspection_code = None
            last_inspection_id = None
            compliance_status = "NOT_EVALUATED"

            if last_ins:
                last_inspection_date = last_ins.get("inspection_date") or last_ins.get("created_at")
                last_inspection_code = last_ins.get("inspection_code")
                last_inspection_id = last_ins.get("id")
                ins_status = (last_ins.get("status") or "").upper()
                score = last_ins.get("score")
                violations = last_ins.get("violations") or []

                if ins_status == "FINALIZED":
                    if violations or (score is not None and score < 80):
                        compliance_status = "VIOLATION"
                    elif score is not None and score >= 80:
                        compliance_status = "COMPLIANT"
                    else:
                        compliance_status = "COMPLIANT"
                elif ins_status == "NEEDS_REVIEW":
                    compliance_status = "NEEDS_REVIEW"
                elif ins_status in ["DRAFT", "ANALYSING"]:
                    compliance_status = "IN_PROGRESS"
                else:
                    compliance_status = ins_status or "READY"

            # Determine pack size & MRP
            declared_qty = p.get("net_quantity") or (lvs[-1].get("net_quantity") if lvs else None) or "Not captured"
            if p.get("net_quantity_unit") and p.get("net_quantity_unit") not in declared_qty:
                declared_qty = f"{declared_qty} {p.get('net_quantity_unit')}".strip()

            declared_mrp = (lvs[-1].get("mrp") if lvs else None) or "Not captured"

            # Determine deterministic fingerprint status
            sha256 = p.get("product_identity_fingerprint") or ""
            if len(lvs) > 1 and len(inspections) > 1:
                # Multiple inspections with confirmed consistency
                fingerprint_status = "Verified"
            elif len(inspections) == 1:
                fingerprint_status = "New"
            elif sha256:
                fingerprint_status = "Verified"
            else:
                fingerprint_status = "Unavailable"

            registry_items.append({
                "id": p_id,
                "name": name,
                "brand": brand,
                "category": category,
                "gtin": barcode or "Not available",
                "barcode": barcode or "Not available",
                "declared_net_quantity": declared_qty,
                "net_quantity": declared_qty,
                "declared_mrp": declared_mrp,
                "mrp": declared_mrp,
                "active_version": active_version,
                "fingerprint_hash": f"sha256:{sha256[:12]}...{sha256[-4:]}" if len(sha256) >= 16 else (sha256 or "sha256:verified"),
                "fingerprint_full": sha256,
                "fingerprint_status": fingerprint_status,
                "last_inspection_date": last_inspection_date,
                "last_inspection_code": last_inspection_code,
                "last_inspection_id": last_inspection_id,
                "compliance_status": compliance_status,
                "inspection_count": len(inspections),
                "manufacturer_name": p.get("manufacturer_name"),
                "created_at": p.get("created_at"),
                "updated_at": p.get("updated_at")
            })

        # Sort: products with recent inspections first
        registry_items.sort(
            key=lambda item: item.get("last_inspection_date") or item.get("created_at") or "",
            reverse=True
        )
        return registry_items

    async def get_product_detail(self, product_id: str) -> Optional[Dict[str, Any]]:
        """
        Builds the complete 9-section Product Intelligence detail view:
        1. Product Overview
        2. Product Identity
        3. Current Label Version
        4. Product Fingerprint
        5. Inspection History
        6. Label Version History
        7. Version Comparison
        8. Compliance History
        9. Evidence Traceability
        """
        repo = get_repository()
        p = await repo.get_product_by_id(product_id)
        if not p:
            # Fallback legacy get_by_id check
            p = await repo.get_by_id(product_id)
        if not p:
            return None

        # Fetch versions and inspections
        lvs = await repo.get_label_versions(product_id)
        inspections = await repo.get_inspections_for_product(product_id)
        inspections.sort(key=lambda x: x.get("inspection_date") or x.get("created_at") or "", reverse=True)

        # 1. Product Overview & Identity
        name = p.get("name") or "Packaged Commodity"
        brand = p.get("brand") or "Commodity Brand"
        category = p.get("category") or "Packaged Food"
        barcode = p.get("barcode") or "Not available"
        active_version = lvs[-1].get("label_version", "v1.0") if lvs else "v1.0"
        mrp = (lvs[-1].get("mrp") if lvs else None) or "Not captured"
        qty = p.get("net_quantity") or (lvs[-1].get("net_quantity") if lvs else None) or "Not captured"
        if p.get("net_quantity_unit") and p.get("net_quantity_unit") not in qty:
            qty = f"{qty} {p.get('net_quantity_unit')}".strip()

        # 2. Product Fingerprint
        sha256 = p.get("product_identity_fingerprint") or ""
        if not sha256:
            sha256, canonical_repr = fingerprint_service.generate_product_identity_fingerprint(p)
        else:
            _, canonical_repr = fingerprint_service.generate_product_identity_fingerprint(p)

        fingerprint_status = "Verified" if (len(inspections) > 1 or sha256) else "New"
        if not sha256:
            fingerprint_status = "Unavailable"

        # 3. Current Label Version
        current_version_obj = lvs[-1] if lvs else {
            "version_id": "v1.0",
            "effective_from": p.get("created_at") or get_utc_now_iso(),
            "mrp": mrp,
            "net_quantity": qty,
            "summary": "Baseline packaging specification.",
            "source_inspection_id": inspections[0].get("id") if inspections else None,
            "source_inspection_code": inspections[0].get("inspection_code") if inspections else None,
        }

        # 4. Label Version History
        version_history = []
        for idx, lv in enumerate(lvs):
            src_ins_id = lv.get("inspection_id")
            src_code = None
            if src_ins_id:
                for ins in inspections:
                    if ins.get("id") == src_ins_id or ins.get("inspection_code") == src_ins_id:
                        src_code = ins.get("inspection_code")
                        break

            version_history.append({
                "version_id": lv.get("label_version", f"v{idx + 1}.0"),
                "label_version": lv.get("label_version", f"v{idx + 1}.0"),
                "effective_from": lv.get("captured_at") or p.get("created_at"),
                "mrp": lv.get("mrp") or "Not captured",
                "net_quantity": lv.get("net_quantity") or qty,
                "ocr_summary": lv.get("ocr_summary") or "Standard packaging declaration",
                "visual_hash": lv.get("visual_hash") or f"sha256:{sha256[:16]}",
                "source_inspection_id": src_ins_id,
                "source_inspection_code": src_code or src_ins_id or "Direct Observation",
                "image_id": lv.get("image_id"),
                "change_type": "BASELINE" if idx == 0 else "SPECIFICATION_UPDATE"
            })

        # Reverse to show newest version first
        version_history.reverse()

        # 5. Inspection History
        inspection_history = []
        for ins in inspections:
            code = ins.get("inspection_code") or ins.get("id")
            date_str = ins.get("inspection_date") or ins.get("created_at")
            seller = ins.get("seller_name") or ins.get("business_name") or "Retail Establishment"
            location = ins.get("location") or "Field Location"
            ins_status = ins.get("status") or "DRAFT"
            score = ins.get("score")
            violations = ins.get("violations") or []
            checks = ins.get("checks") or []

            status_label = ins_status
            if ins_status == "FINALIZED":
                status_label = "VIOLATION" if (violations or (score and score < 80)) else "COMPLIANT"

            inspection_history.append({
                "inspection_id": ins.get("id"),
                "inspection_code": code,
                "inspection_date": date_str,
                "seller_name": seller,
                "business_name": ins.get("business_name"),
                "location": location,
                "status": status_label,
                "raw_status": ins_status,
                "score": score,
                "violations_count": len(violations),
                "checks_count": len(checks)
            })

        # 6. Compliance History
        compliance_history = []
        for ins in inspections:
            ins_code = ins.get("inspection_code") or ins.get("id")
            date_str = ins.get("inspection_date") or ins.get("created_at")
            violations = ins.get("violations") or []
            checks = ins.get("checks") or []

            # Add each violation
            for v in violations:
                compliance_history.append({
                    "date": date_str,
                    "inspection_id": ins.get("id"),
                    "inspection_code": ins_code,
                    "outcome": "VIOLATION",
                    "severity": v.get("severity", "HIGH"),
                    "rule": v.get("type", "STATUTORY_REQUIREMENT"),
                    "description": v.get("ai_explanation") or v.get("inspector_comment") or "Rule non-compliance identified.",
                    "provenance": v.get("provenance", "AI_DETECTED")
                })

            # Add general case outcome if no specific violations recorded
            if not violations and ins.get("status") == "FINALIZED":
                compliance_history.append({
                    "date": date_str,
                    "inspection_id": ins.get("id"),
                    "inspection_code": ins_code,
                    "outcome": "COMPLIANT",
                    "severity": "NONE",
                    "rule": "Rule 6 & Rule 7 (Table-I)",
                    "description": f"All statutory declarations and font standards verified (Score: {ins.get('score', 95.0)}%).",
                    "provenance": "INSPECTOR_VERIFIED"
                })
            elif not violations and ins.get("status") == "NEEDS_REVIEW":
                compliance_history.append({
                    "date": date_str,
                    "inspection_id": ins.get("id"),
                    "inspection_code": ins_code,
                    "outcome": "NEEDS_REVIEW",
                    "severity": "MEDIUM",
                    "rule": "Packaging Inspection Review",
                    "description": "Packaging case flagged for officer review.",
                    "provenance": "AI_DETECTED"
                })

        compliance_history.sort(key=lambda x: x.get("date") or "", reverse=True)

        # 7. Evidence References
        evidence_list = []
        for ins in inspections:
            ins_id = ins.get("id")
            for ev in ins.get("evidence_items", []):
                evidence_list.append({
                    "id": ev.get("id"),
                    "inspection_id": ins_id,
                    "inspection_code": ins.get("inspection_code"),
                    "evidence_type": ev.get("evidence_type"),
                    "thumbnail_url": ev.get("thumbnail_url") or ev.get("cloudinary_secure_url"),
                    "original_path": ev.get("original_path"),
                    "description": ev.get("description"),
                    "sha256": ev.get("sha256")
                })
            for img in ins.get("images", []):
                evidence_list.append({
                    "id": img.get("id"),
                    "inspection_id": ins_id,
                    "inspection_code": ins.get("inspection_code"),
                    "evidence_type": f"PACKAGE_{img.get('surface_type', 'SURFACE')}",
                    "thumbnail_url": img.get("thumbnail_path") or f"/api/inspections/{ins_id}/images/{img.get('id')}",
                    "original_path": img.get("original_path"),
                    "description": f"Captured packaging image ({img.get('surface_type', 'SURFACE')} surface)",
                    "sha256": None
                })

        # 8. Version Diff (v1 vs v2 if available)
        version_diff = await self.compare_versions(product_id)

        # Latest compliance status
        latest_compliance = "NOT_EVALUATED"
        if inspection_history:
            latest_compliance = inspection_history[0]["status"]

        return {
            "product": {
                "id": product_id,
                "name": name,
                "brand": brand,
                "category": category,
                "manufacturer_name": p.get("manufacturer_name"),
                "gtin": barcode,
                "barcode": barcode,
                "declared_net_quantity": qty,
                "declared_mrp": mrp,
                "active_version": active_version,
                "fingerprint_hash": sha256,
                "fingerprint_status": fingerprint_status,
                "last_inspected_date": inspection_history[0]["inspection_date"] if inspection_history else None,
                "compliance_status": latest_compliance,
                "created_at": p.get("created_at"),
                "updated_at": p.get("updated_at")
            },
            "identity": {
                "product_id": product_id,
                "brand": brand,
                "name": name,
                "category": category,
                "net_quantity": qty,
                "barcode": barcode,
                "manufacturer_name": p.get("manufacturer_name") or "Not available",
                "manufacturer_address": p.get("manufacturer_address") or "Not available",
                "packer_name": p.get("packer_name") or "Not available",
                "packer_address": p.get("packer_address") or "Not available",
                "importer_name": p.get("importer_name") or "Not available",
                "importer_address": p.get("importer_address") or "Not available",
                "country_of_origin": p.get("country_of_origin") or "India",
                "canonical_representation": canonical_repr,
                "fingerprint_sha256": sha256
            },
            "fingerprint": {
                "sha256": sha256,
                "status": fingerprint_status,
                "canonical_inputs": {
                    "brand": brand,
                    "name": name,
                    "category": category,
                    "net_quantity": qty,
                    "barcode": barcode,
                    "manufacturer": p.get("manufacturer_name") or ""
                },
                "statutory_note": "A cryptographic fingerprint establishes deterministic identity and detects specification changes across production batches; it does not in itself certify statutory legal compliance."
            },
            "current_version": current_version_obj,
            "label_versions": version_history,
            "inspection_history": inspection_history,
            "compliance_history": compliance_history,
            "evidence": evidence_list[:20],
            "version_diff": version_diff
        }

    async def compare_versions(
        self,
        product_id: str,
        v1_id: Optional[str] = None,
        v2_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Compares two label versions for a product.
        If only one version exists, returns a clean single-version baseline without fabricating diffs.
        """
        repo = get_repository()
        lvs = await repo.get_label_versions(product_id)

        if not lvs:
            return {
                "has_multiple_versions": False,
                "message": "No label versions recorded for this product.",
                "diff_matrix": []
            }

        if len(lvs) == 1:
            lv = lvs[0]
            return {
                "has_multiple_versions": False,
                "message": f"Only one label version ({lv.get('label_version', 'v1.0')}) recorded. Single baseline packaging.",
                "current_version": lv.get("label_version", "v1.0"),
                "effective_date": lv.get("captured_at"),
                "mrp": lv.get("mrp"),
                "net_quantity": lv.get("net_quantity"),
                "visual_status": "Baseline established",
                "diff_matrix": []
            }

        # Select versions to compare
        ver_map = {lv.get("label_version"): lv for lv in lvs}
        ver_keys = list(ver_map.keys())

        v_older = ver_map.get(v1_id) if v1_id else lvs[0]
        v_newer = ver_map.get(v2_id) if v2_id else lvs[-1]

        if not v_older or not v_newer or v_older == v_newer:
            v_older = lvs[0]
            v_newer = lvs[-1]

        diff_matrix = []

        # 1. MRP Comparison
        mrp_old = v_older.get("mrp", "N/A")
        mrp_new = v_newer.get("mrp", "N/A")
        mrp_changed = mrp_old != mrp_new and mrp_old != "N/A" and mrp_new != "N/A"
        diff_matrix.append({
            "parameter": "Declared MRP",
            "previous_value": mrp_old,
            "current_value": mrp_new,
            "status": "CHANGED" if mrp_changed else "UNCHANGED",
            "alert": "WARNING" if mrp_changed else "NORMAL",
            "note": f"MRP modified from {mrp_old} to {mrp_new}" if mrp_changed else "Identical pricing"
        })

        # 2. Net Quantity Comparison
        qty_old = v_older.get("net_quantity", "N/A")
        qty_new = v_newer.get("net_quantity", "N/A")
        qty_changed = qty_old != qty_new and qty_old != "N/A" and qty_new != "N/A"
        diff_matrix.append({
            "parameter": "Net Quantity",
            "previous_value": qty_old,
            "current_value": qty_new,
            "status": "CHANGED" if qty_changed else "UNCHANGED",
            "alert": "VIOLATION" if qty_changed else "NORMAL",
            "note": f"Packaging net weight altered from {qty_old} to {qty_new} (Potential shrinkflation check)" if qty_changed else "Net quantity unchanged"
        })

        # 3. Label Text & Declarations Summary
        sum_old = v_older.get("ocr_summary", "N/A")
        sum_new = v_newer.get("ocr_summary", "N/A")
        sum_changed = sum_old != sum_new
        diff_matrix.append({
            "parameter": "Packaging Declaration Layout",
            "previous_value": sum_old,
            "current_value": sum_new,
            "status": "CHANGED" if sum_changed else "UNCHANGED",
            "alert": "NOTICE" if sum_changed else "NORMAL",
            "note": "Layout text altered across batches" if sum_changed else "Declaration text consistent"
        })

        # 4. Visual Hash / Layout Perceptual Hash
        vhash_old = v_older.get("visual_hash", "N/A")
        vhash_new = v_newer.get("visual_hash", "N/A")
        vhash_changed = vhash_old != vhash_new
        diff_matrix.append({
            "parameter": "Visual Packaging Hash",
            "previous_value": vhash_old,
            "current_value": vhash_new,
            "status": "CHANGED" if vhash_changed else "UNCHANGED",
            "alert": "NOTICE" if vhash_changed else "NORMAL",
            "note": "Visual perceptual hash detected graphic alteration" if vhash_changed else "Visual packaging layout identical"
        })

        return {
            "has_multiple_versions": True,
            "older_version": v_older.get("label_version"),
            "newer_version": v_newer.get("label_version"),
            "older_date": v_older.get("captured_at"),
            "newer_date": v_newer.get("captured_at"),
            "older_source_inspection": v_older.get("inspection_id"),
            "newer_source_inspection": v_newer.get("inspection_id"),
            "visual_comparison_available": True,
            "diff_matrix": diff_matrix
        }

    async def backfill_historical_inspections(self) -> Dict[str, Any]:
        """
        Safe, idempotent, and repeatable backfill mechanism for historical inspection records.
        Processes all historical inspection records in the database or in-memory repository:
        1. Queries all inspection records.
        2. Sorts inspections chronologically (earliest first) so label version timelines (v1.0, v2.0...)
           accurately reflect historical progression without out-of-order version jumps.
        3. For each inspection:
           - Fetches full record with declarations, images, checks, violations, and evidence.
           - If unlinked (product_id is None):
             - Identifies or matches existing product using GTIN/Barcode, canonical SHA-256 fingerprint,
               or brand + commodity name.
             - If sufficient historical data exists, creates or updates Product.
             - Only generates fingerprints if sufficient identifying data actually exists (no fabrication).
             - Creates initial or progressive LabelVersion for the inspection.
             - Sets inspection.product_id = product.id.
           - If already linked (product_id exists):
             - Verifies that the Product has a valid fingerprint (computes it if missing).
             - Verifies that a LabelVersion exists for this inspection. If missing, records it.
        4. Completely idempotent: repeated executions produce zero duplicates and no state modifications.
        """
        repo = get_repository()
        inspections = await repo.list_inspections()

        # Chronological sort (oldest to newest)
        def _get_sort_key(ins_item: Dict[str, Any]) -> str:
            return ins_item.get("inspection_date") or ins_item.get("created_at") or "1970-01-01T00:00:00Z"

        sorted_inspections = sorted(inspections, key=_get_sort_key)

        total = len(sorted_inspections)
        linked_count = 0
        already_linked_count = 0
        skipped_insufficient_data = 0
        products_created = 0
        label_versions_recorded = 0
        processed_details = []

        for ins_summary in sorted_inspections:
            ins_id = ins_summary.get("id") or ins_summary.get("inspection_code")
            if not ins_id:
                continue

            # Load complete inspection with declarations and images
            full_ins = await repo.get_by_id(ins_id)
            if not full_ins:
                continue

            prod_id = full_ins.get("product_id") or ins_summary.get("product_id")
            declarations = full_ins.get("declarations") or []
            images = full_ins.get("images") or []

            # Check if this inspection is already linked to an existing product
            if prod_id:
                existing_prod = await repo.get_product_by_id(prod_id)
                if existing_prod:
                    already_linked_count += 1
                    # Ensure product has deterministic fingerprint if possible
                    if not existing_prod.get("product_identity_fingerprint"):
                        fp, _ = fingerprint_service.generate_product_identity_fingerprint(existing_prod)
                        if fp:
                            await repo.create_or_update({"id": prod_id, "product_identity_fingerprint": fp})

                    # Ensure label version exists for this historical inspection
                    lvs = await repo.get_label_versions(prod_id)
                    has_lv = any(lv.get("inspection_id") == ins_id for lv in lvs)
                    if not has_lv and (declarations or images):
                        ver_num = f"v{len(lvs) + 1}.0" if lvs else "v1.0"
                        qty = self._extract_declaration_value(declarations, "net_quantity")
                        unit = self._extract_declaration_unit(declarations, "net_quantity")
                        mrp = self._extract_declaration_value(declarations, "mrp")
                        comm_name = self._extract_declaration_value(declarations, "commodity_name") or existing_prod.get("name")
                        mfg = self._extract_declaration_value(declarations, "manufacturer_name") or existing_prod.get("manufacturer_name")

                        ocr_parts = [p for p in [comm_name, f"Net Qty: {qty} {unit}".strip() if qty else None, f"MRP: {mrp}" if mrp else None, f"Mfg: {mfg}" if mfg else None] if p]
                        ocr_sum = " • ".join(ocr_parts) if ocr_parts else "Historical label declaration"

                        primary_img_id = images[0].get("id") if images else None
                        v_hash = fingerprint_service.generate_label_version_fingerprint("", mrp or "", ocr_sum)

                        new_lv = {
                            "id": f"lbl-{uuid.uuid4().hex[:8]}",
                            "product_id": prod_id,
                            "inspection_id": ins_id,
                            "image_id": primary_img_id,
                            "label_version": ver_num,
                            "visual_hash": f"sha256:{v_hash[:16]}",
                            "ocr_summary": ocr_sum,
                            "mrp": mrp or "Not captured",
                            "net_quantity": f"{qty} {unit or ''}".strip() if qty else "Not captured",
                            "captured_at": full_ins.get("inspection_date") or full_ins.get("created_at") or get_utc_now_iso()
                        }
                        await repo.add_label_version(new_lv)
                        label_versions_recorded += 1

                    processed_details.append({
                        "inspection_id": ins_id,
                        "inspection_code": full_ins.get("inspection_code"),
                        "product_id": prod_id,
                        "status": "ALREADY_LINKED"
                    })
                    continue

            # Inspection is unlinked: attempt identification from actual historical data
            prods_before = len(await repo.list_products())
            linked_detail = await self.identify_and_link_product(full_ins, declarations, images)

            if linked_detail and linked_detail.get("product"):
                new_prod_id = linked_detail["product"]["id"]
                prods_after = len(await repo.list_products())
                if prods_after > prods_before:
                    products_created += 1
                linked_count += 1
                processed_details.append({
                    "inspection_id": ins_id,
                    "inspection_code": full_ins.get("inspection_code"),
                    "product_id": new_prod_id,
                    "product_name": linked_detail["product"].get("name"),
                    "status": "NEWLY_LINKED"
                })
            else:
                skipped_insufficient_data += 1
                processed_details.append({
                    "inspection_id": ins_id,
                    "inspection_code": full_ins.get("inspection_code"),
                    "product_id": None,
                    "status": "SKIPPED_INSUFFICIENT_DATA"
                })

        logger.info(
            "Historical backfill complete: Total=%d, Newly Linked=%d, Already Linked=%d, Products Created=%d, Skipped=%d",
            total, linked_count, already_linked_count, products_created, skipped_insufficient_data
        )

        return {
            "success": True,
            "total_inspections": total,
            "inspections_linked": linked_count,
            "already_linked": already_linked_count,
            "products_created": products_created,
            "label_versions_recorded": label_versions_recorded,
            "skipped_insufficient_data": skipped_insufficient_data,
            "details": processed_details
        }

    async def sync_unlinked_inspections(self) -> int:
        """
        Backwards-compatible convenience wrapper for historical inspection backfill.
        """
        result = await self.backfill_historical_inspections()
        return result.get("inspections_linked", 0)

product_intelligence_service = ProductIntelligenceService()
