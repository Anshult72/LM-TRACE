from __future__ import annotations
import os
import io
import re
import json
import uuid
import socket
import hashlib
import ipaddress
from datetime import datetime, timezone
from urllib.parse import urlparse, urljoin
from typing import Dict, Any, Optional, Tuple, List

import httpx
from PIL import Image
import lxml.html

from app.core.config import settings
from app.core.logging import logger
from app.storage.file_storage import storage_manager
from app.services.ocr import get_ocr_service


# List of restricted IP networks for strict SSRF protection
BLOCKED_NETWORKS = [
    ipaddress.ip_network("0.0.0.0/8"),          # Current network
    ipaddress.ip_network("10.0.0.0/8"),         # Private RFC 1918
    ipaddress.ip_network("100.64.0.0/10"),      # Carrier-grade NAT
    ipaddress.ip_network("127.0.0.0/8"),        # Loopback
    ipaddress.ip_network("169.254.0.0/16"),     # Link-local / Cloud metadata (AWS, GCP, Azure)
    ipaddress.ip_network("172.16.0.0/12"),      # Private RFC 1918
    ipaddress.ip_network("192.0.0.0/24"),       # IETF Protocol Assignments
    ipaddress.ip_network("192.0.2.0/24"),       # TEST-NET-1
    ipaddress.ip_network("192.88.99.0/24"),     # 6to4 Relay Anycast
    ipaddress.ip_network("192.168.0.0/16"),     # Private RFC 1918
    ipaddress.ip_network("198.18.0.0/15"),      # Network benchmark tests
    ipaddress.ip_network("198.51.100.0/24"),    # TEST-NET-2
    ipaddress.ip_network("203.0.113.0/24"),     # TEST-NET-3
    ipaddress.ip_network("224.0.0.0/4"),        # Multicast
    ipaddress.ip_network("240.0.0.0/4"),        # Reserved for Future Use
    ipaddress.ip_network("255.255.255.255/32"), # Broadcast
    # IPv6
    ipaddress.ip_network("::/128"),             # Unspecified
    ipaddress.ip_network("::1/128"),            # Loopback
    ipaddress.ip_network("fc00::/7"),           # Unique local address (ULA)
    ipaddress.ip_network("fe80::/10"),          # Link-local unicast
    ipaddress.ip_network("ff00::/8"),           # Multicast
]

# Cloud metadata hostnames explicitly blocked
BLOCKED_HOSTNAMES = {
    "localhost", "metadata.google.internal", "metadata", "instance-data",
    "169.254.169.254", "fd00:ec2::254"
}


def get_utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


class OnlineListingService:
    """
    Production-grade service for fetching, parsing, analyzing, and auditing
    public e-commerce product listings under the Legal Metrology (Packaged Commodities)
    Rules, 2011 (Rule 6(10) / Rule 2027 digital disclosure requirements).
    """

    @staticmethod
    def validate_url_security(url_str: str) -> Tuple[bool, str, Optional[str]]:
        """
        Enforces strict, multi-layered SSRF (Server-Side Request Forgery) protection:
        1. Validates scheme is strictly HTTP or HTTPS.
        2. Blocks forbidden schemes (file://, javascript:, data:, ftp:, etc.).
        3. Extracts hostname and checks blacklist (localhost, metadata endpoints).
        4. Resolves all IPv4 and IPv6 DNS records.
        5. Checks every resolved IP against private, loopback, link-local, carrier NAT, and cloud metadata blocks.
        """
        try:
            url_str = (url_str or "").strip()
            if not url_str:
                return False, "URL cannot be empty.", None

            parsed = urlparse(url_str)
            if parsed.scheme.lower() not in ["http", "https"]:
                return False, f"Invalid protocol '{parsed.scheme}'. Only public HTTP and HTTPS URLs are permitted.", None

            hostname = parsed.hostname
            if not hostname:
                return False, "Invalid URL: hostname could not be parsed.", None

            hostname_lower = hostname.lower()
            if hostname_lower in BLOCKED_HOSTNAMES or hostname_lower.endswith(".local") or hostname_lower.endswith(".internal"):
                return False, f"Access to restricted hostname '{hostname}' is strictly prohibited.", None

            # Resolve DNS records for hostname
            try:
                addr_info = socket.getaddrinfo(hostname, None)
            except socket.gaierror as dns_err:
                return False, f"DNS resolution failed for '{hostname}': {dns_err}", None

            resolved_ips = set()
            for item in addr_info:
                sockaddr = item[4]
                ip_str = sockaddr[0]
                resolved_ips.add(ip_str)

            if not resolved_ips:
                return False, f"No IP addresses resolved for hostname '{hostname}'.", None

            first_ip = None
            for ip_str in resolved_ips:
                try:
                    ip_obj = ipaddress.ip_address(ip_str)
                except ValueError:
                    return False, f"Invalid resolved IP address: {ip_str}", None

                if first_ip is None:
                    first_ip = str(ip_obj)

                # Check against all blocked networks
                for blocked in BLOCKED_NETWORKS:
                    if ip_obj in blocked:
                        return False, f"Security Violation: Target IP '{ip_str}' belongs to private/restricted network {blocked}.", ip_str

                if ip_obj.is_private or ip_obj.is_loopback or ip_obj.is_link_local or ip_obj.is_reserved or ip_obj.is_multicast:
                    return False, f"Security Violation: Target IP '{ip_str}' is non-public or reserved.", ip_str

            return True, "URL is safe for scanning.", first_ip

        except Exception as e:
            logger.warning(f"URL validation exception for '{url_str}': {e}")
            return False, f"URL security check failed: {str(e)}", None

    @staticmethod
    def detect_marketplace(url_str: str) -> str:
        """Identifies standard e-commerce platform from hostname."""
        try:
            parsed = urlparse(url_str)
            host = (parsed.hostname or "").lower()
            if "amazon." in host or "amzn." in host:
                return "Amazon India"
            elif "flipkart." in host:
                return "Flipkart"
            elif "blinkit." in host:
                return "Blinkit"
            elif "zeptonow." in host:
                return "Zepto"
            elif "swiggy." in host or "instamart" in url_str.lower():
                return "Swiggy Instamart"
            elif "bigbasket." in host:
                return "BigBasket"
            elif "jiomart." in host:
                return "JioMart"
            elif "myntra." in host:
                return "Myntra"
            elif "nykaa." in host:
                return "Nykaa"
            elif "tatacliq." in host:
                return "Tata CLiQ"
            elif "dmart." in host:
                return "DMart Ready"
            else:
                clean_host = host.replace("www.", "")
                return clean_host.title() if clean_host else "Independent E-Commerce Platform"
        except Exception:
            return "Independent E-Commerce Platform"

    async def fetch_listing_preview(self, safe_url: str) -> Dict[str, Any]:
        """Legacy preview wrapper kept for backwards compatibility."""
        res = await self.fetch_and_extract_listing(safe_url)
        return {
            "url": res.get("original_url") or safe_url,
            "status": res.get("fetch_status") or "Fetched",
            "text_preview": res.get("raw_text_preview") or ""
        }

    async def fetch_and_extract_listing(
        self,
        url: str,
        inspection_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Executes the authoritative URL fetching and layered extraction pipeline:
        1. SSRF validation of initial and redirect targets.
        2. Safe HTTP retrieval with controlled User-Agent and timeouts.
        3. Layered parsing: JSON-LD, meta tags, and DOM specification tables.
        4. Package image extraction & optional EasyOCR.
        5. Statutory declaration mapping under Rule 6(10).
        6. Snapshot creation with SHA-256 integrity hash.
        """
        retrieved_at = get_utc_now_iso()
        marketplace = self.detect_marketplace(url)

        # 1. SSRF Security Check
        is_safe, msg, _ = self.validate_url_security(url)
        if not is_safe:
            return {
                "fetch_status": "BLOCKED",
                "original_url": url,
                "final_url": url,
                "retrieved_at": retrieved_at,
                "marketplace": marketplace,
                "error_message": msg,
                "warnings": [f"SSRF Security Guard blocked request: {msg}"],
                "declarations": {},
                "declarations_matrix": [],
                "image_urls": [],
            }

        # 2. HTTP Fetch Pipeline with Manual Redirect & SSRF Tracking
        request_headers = {
            "User-Agent": (
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
                "(KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36 LM-TraceBot/1.0"
            ),
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
            "Accept-Language": "en-IN,en-GB;q=0.9,en;q=0.8",
            "Sec-Fetch-Dest": "document",
            "Sec-Fetch-Mode": "navigate",
            "Sec-Fetch-Site": "none",
            "Sec-Fetch-User": "?1",
            "Upgrade-Insecure-Requests": "1",
        }

        current_url = url
        final_url = url
        response_text = ""
        fetch_status = "RETRIEVED"
        error_message = None
        warnings: List[str] = []

        try:
            async with httpx.AsyncClient(
                timeout=httpx.Timeout(connect=5.0, read=15.0, write=5.0, pool=5.0),
                follow_redirects=False,
                verify=True
            ) as client:
                for redirect_hop in range(6):
                    try:
                        resp = await client.get(current_url, headers=request_headers)
                    except httpx.ConnectTimeout:
                        return self._error_response(url, current_url, retrieved_at, marketplace, "TIMEOUT", "Connection to listing URL timed out (5s connect limit).")
                    except httpx.ReadTimeout:
                        return self._error_response(url, current_url, retrieved_at, marketplace, "TIMEOUT", "Timed out waiting for response from listing server (15s read limit).")
                    except (httpx.ConnectError, httpx.NetworkError) as net_err:
                        return self._error_response(url, current_url, retrieved_at, marketplace, "FAILED", f"Network connection error: {net_err}")

                    # Check HTTP status
                    status_code = resp.status_code

                    # Handle Redirects
                    if status_code in (301, 302, 303, 307, 308):
                        location = resp.headers.get("Location")
                        if not location:
                            break
                        redirect_target = urljoin(current_url, location)
                        # Re-verify SSRF on each redirect hop
                        is_target_safe, target_msg, _ = self.validate_url_security(redirect_target)
                        if not is_target_safe:
                            return self._error_response(
                                url, redirect_target, retrieved_at, marketplace, "BLOCKED",
                                f"Unsafe redirect blocked: {target_msg}"
                            )
                        current_url = redirect_target
                        final_url = redirect_target
                        continue

                    final_url = str(resp.url) or current_url

                    if status_code == 401 or status_code == 403:
                        return self._error_response(
                            url, final_url, retrieved_at, marketplace, "LOGIN_REQUIRED" if status_code == 401 else "BLOCKED",
                            "Listing could not be fetched automatically because the marketplace requires interactive login, session cookies, or anti-bot verification."
                        )
                    elif status_code == 404:
                        return self._error_response(
                            url, final_url, retrieved_at, marketplace, "FAILED",
                            f"Listing page not found at target URL (HTTP 404)."
                        )
                    elif status_code == 429:
                        return self._error_response(
                            url, final_url, retrieved_at, marketplace, "BLOCKED",
                            "Rate limited by target platform (HTTP 429). Please retry after a brief pause."
                        )
                    elif status_code >= 500:
                        return self._error_response(
                            url, final_url, retrieved_at, marketplace, "FAILED",
                            f"Target marketplace server returned error HTTP {status_code}."
                        )
                    elif status_code != 200:
                        return self._error_response(
                            url, final_url, retrieved_at, marketplace, "FAILED",
                            f"Unexpected HTTP status code {status_code} returned by target URL."
                        )

                    # Response size safety limit (5 MB)
                    if len(resp.content) > 5 * 1024 * 1024:
                        warnings.append("Page body exceeded 5MB; content truncated for inspection safety.")
                        response_text = resp.text[:5 * 1024 * 1024]
                    else:
                        response_text = resp.text
                    break
                else:
                    return self._error_response(url, final_url, retrieved_at, marketplace, "FAILED", "Too many redirects (exceeded 5 hops).")

        except Exception as exc:
            logger.warning(f"Error fetching URL '{url}': {exc}")
            return self._error_response(url, final_url, retrieved_at, marketplace, "FAILED", f"Fetch error: {str(exc)}")

        # 3. Layered Extraction
        extracted_data = self._parse_listing_html(response_text, final_url, marketplace)

        # 4. Save Listing Snapshot to Disk & Hash
        snapshot_id = f"snap-{uuid.uuid4().hex[:10]}"
        content_hash = hashlib.sha256(response_text.encode("utf-8")).hexdigest()
        
        try:
            snapshot_filename = f"{snapshot_id}_{content_hash[:8]}.html"
            snapshot_path = os.path.join(storage_manager.listing_dir, snapshot_filename)
            with open(snapshot_path, "w", encoding="utf-8", errors="replace") as f:
                f.write(response_text)
        except Exception as snap_err:
            logger.warning(f"Could not persist listing snapshot on disk: {snap_err}")
            snapshot_path = None

        # 5. Image Processing & OCR (Run EasyOCR on package images if available)
        image_ocr_declarations = await self._run_image_ocr_on_listing_images(
            extracted_data.get("image_urls", []), inspection_id
        )
        if image_ocr_declarations:
            for k, v in image_ocr_declarations.items():
                if k not in extracted_data["declarations"] or not extracted_data["declarations"][k].get("value"):
                    extracted_data["declarations"][k] = v

        # 6. Build Rule 6(10) Declarations Matrix & Assess Completeness
        matrix, missing_fields = self._build_rule_6_10_matrix(extracted_data["declarations"])

        if missing_fields:
            fetch_status = "PARTIAL"
            warnings.append(
                f"Listing fetched successfully; {len(missing_fields)} statutory declaration(s) not detected on digital PDP: {', '.join(missing_fields)}."
            )
        else:
            fetch_status = "RETRIEVED"

        return {
            "fetch_status": fetch_status,
            "original_url": url,
            "final_url": final_url,
            "retrieved_at": retrieved_at,
            "marketplace": marketplace,
            "page_title": extracted_data.get("page_title"),
            "product_title": extracted_data.get("product_title"),
            "brand": extracted_data.get("brand"),
            "seller": extracted_data.get("seller"),
            "category": extracted_data.get("category"),
            "sku": extracted_data.get("sku"),
            "gtin": extracted_data.get("gtin"),
            "mrp": extracted_data.get("mrp"),
            "selling_price": extracted_data.get("selling_price"),
            "unit_sale_price": extracted_data.get("unit_sale_price"),
            "net_quantity": extracted_data.get("net_quantity"),
            "country_of_origin": extracted_data.get("country_of_origin"),
            "manufacturer": extracted_data.get("manufacturer"),
            "packer": extracted_data.get("packer"),
            "importer": extracted_data.get("importer"),
            "consumer_care": extracted_data.get("consumer_care"),
            "best_before": extracted_data.get("best_before"),
            "declarations": extracted_data.get("declarations", {}),
            "declarations_matrix": matrix,
            "image_urls": extracted_data.get("image_urls", []),
            "snapshot_id": snapshot_id,
            "content_hash": content_hash,
            "raw_text_preview": extracted_data.get("raw_text_preview"),
            "warnings": warnings,
            "error_message": None,
        }

    def _error_response(
        self,
        original_url: str,
        final_url: str,
        retrieved_at: str,
        marketplace: str,
        status: str,
        error_msg: str
    ) -> Dict[str, Any]:
        return {
            "fetch_status": status,
            "original_url": original_url,
            "final_url": final_url,
            "retrieved_at": retrieved_at,
            "marketplace": marketplace,
            "page_title": None,
            "product_title": None,
            "brand": None,
            "seller": None,
            "category": None,
            "sku": None,
            "gtin": None,
            "mrp": None,
            "selling_price": None,
            "unit_sale_price": None,
            "net_quantity": None,
            "country_of_origin": None,
            "manufacturer": None,
            "packer": None,
            "importer": None,
            "consumer_care": None,
            "best_before": None,
            "declarations": {},
            "declarations_matrix": [],
            "image_urls": [],
            "snapshot_id": None,
            "content_hash": None,
            "raw_text_preview": None,
            "warnings": [error_msg],
            "error_message": error_msg,
        }

    def _parse_listing_html(self, html_text: str, base_url: str, marketplace: str) -> Dict[str, Any]:
        """
        Multi-source extraction engine:
        1. JSON-LD structured data
        2. OpenGraph / Twitter metadata
        3. Specification & Detail HTML tables
        """
        res = {
            "page_title": None,
            "product_title": None,
            "brand": None,
            "seller": None,
            "category": "Packaged Commodity",
            "sku": None,
            "gtin": None,
            "mrp": None,
            "selling_price": None,
            "unit_sale_price": None,
            "net_quantity": None,
            "country_of_origin": None,
            "manufacturer": None,
            "packer": None,
            "importer": None,
            "consumer_care": None,
            "best_before": None,
            "declarations": {},
            "image_urls": [],
            "raw_text_preview": ""
        }

        if not html_text:
            return res

        try:
            tree = lxml.html.fromstring(html_text)
        except Exception as e:
            logger.warning(f"Failed to parse HTML with lxml: {e}")
            # Fallback simple text
            clean_text = re.sub(r"<[^>]+>", " ", html_text)
            res["raw_text_preview"] = " ".join(clean_text.split())[:1200]
            return res

        # Extract <title>
        title_elems = tree.xpath("//title/text()")
        if title_elems:
            res["page_title"] = title_elems[0].strip()

        # -----------------------------------------------------------------
        # LAYER 1: JSON-LD STRUCTURED DATA
        # -----------------------------------------------------------------
        json_ld_scripts = tree.xpath('//script[@type="application/ld+json"]/text()')
        for script in json_ld_scripts:
            try:
                data = json.loads(script.strip())
                items = data if isinstance(data, list) else [data]
                for item in items:
                    if not isinstance(item, dict):
                        continue
                    # Check @graph
                    graph = item.get("@graph")
                    sub_items = graph if isinstance(graph, list) else [item]
                    for obj in sub_items:
                        if not isinstance(obj, dict):
                            continue
                        obj_type = str(obj.get("@type", ""))
                        if "Product" in obj_type or "Commodity" in obj_type or "ItemPage" in obj_type:
                            self._extract_from_json_ld_product(obj, res, base_url)
            except Exception:
                pass

        # -----------------------------------------------------------------
        # LAYER 2: OPEN GRAPH & TWITTER META TAGS
        # -----------------------------------------------------------------
        meta_tags = tree.xpath("//meta")
        for meta in meta_tags:
            prop = meta.get("property", "") or meta.get("name", "")
            content = meta.get("content", "")
            if not prop or not content:
                continue
            prop_lower = prop.lower()

            if not res["product_title"] and prop_lower in ("og:title", "twitter:title"):
                res["product_title"] = content.strip()
            elif not res["brand"] and prop_lower in ("og:brand", "product:brand"):
                res["brand"] = content.strip()
                res["declarations"]["brand_name"] = {"value": content.strip(), "provenance": "META_TAG"}
            elif not res["selling_price"] and prop_lower in ("product:price:amount", "og:price:amount"):
                res["selling_price"] = content.strip()
            elif prop_lower in ("og:image", "twitter:image"):
                full_img = urljoin(base_url, content.strip())
                if full_img not in res["image_urls"]:
                    res["image_urls"].append(full_img)

        # -----------------------------------------------------------------
        # LAYER 3: SPECIFICATION & DETAIL TABLES
        # -----------------------------------------------------------------
        # Search all key-value tables and definitions
        spec_rows = tree.xpath(
            '//table//tr | //div[contains(@class, "spec")] | //div[contains(@class, "detail")] | '
            '//dl | //div[contains(@id, "productDetails")] | //div[contains(@id, "detailBullets")]'
        )

        table_dict: Dict[str, str] = {}
        for row in spec_rows:
            text_cells = [c.strip() for c in row.xpath(".//th//text() | .//td//text() | .//dt//text() | .//dd//text()") if c.strip()]
            if len(text_cells) >= 2:
                key = text_cells[0].lower().strip(" :-\t\r\n")
                val = " ".join(text_cells[1:]).strip()
                table_dict[key] = val

        # Also search Amazon detailBullets specifically
        bullet_items = tree.xpath('//div[@id="detailBullets_feature_div"]//li')
        for b in bullet_items:
            b_texts = [t.strip() for t in b.xpath(".//text()") if t.strip()]
            if len(b_texts) >= 2:
                key = b_texts[0].lower().strip(" :-\t\r\n")
                val = " ".join(b_texts[1:]).strip()
                table_dict[key] = val

        self._map_table_dict_to_declarations(table_dict, res)

        # -----------------------------------------------------------------
        # LAYER 4: HEURISTIC TEXT / VISIBLE DOM FALLBACKS
        # -----------------------------------------------------------------
        if not res["product_title"]:
            h1_elems = tree.xpath("//h1//text()")
            if h1_elems:
                res["product_title"] = " ".join([h.strip() for h in h1_elems if h.strip()])

        # Look for visible MRP/Price in body if not found
        if not res["mrp"] or not res["selling_price"]:
            price_matches = tree.xpath(
                '//*[contains(@class, "price") or contains(@id, "price") or contains(@class, "mrp")]//text()'
            )
            for pm in price_matches:
                pm_clean = pm.strip()
                match = re.search(r'(?:₹|Rs\.?|INR)\s*([0-9,]+(?:\.[0-9]{1,2})?)', pm_clean, re.IGNORECASE)
                if match:
                    val = f"₹{match.group(1)}"
                    if "mrp" in pm_clean.lower() and not res["mrp"]:
                        res["mrp"] = val
                        res["declarations"]["mrp"] = {"value": val, "provenance": "VISIBLE_TEXT"}
                    elif not res["selling_price"]:
                        res["selling_price"] = val

        # Collect candidate product images from DOM
        if len(res["image_urls"]) < 4:
            img_elems = tree.xpath(
                '//div[contains(@class, "image") or contains(@id, "image") or contains(@class, "gallery")]//img/@src | '
                '//img[contains(@id, "landingImage") or contains(@class, "product-image")]/@src'
            )
            for src in img_elems:
                if src and not src.startswith("data:"):
                    full_src = urljoin(base_url, src.strip())
                    if full_src not in res["image_urls"] and ("sprite" not in full_src.lower() and "icon" not in full_src.lower()):
                        res["image_urls"].append(full_src)

        # Clean preview text
        all_body_text = tree.xpath("//body//text()")
        clean_words = [w.strip() for w in all_body_text if w.strip() and not w.strip().startswith("{")]
        res["raw_text_preview"] = " ".join(clean_words[:250])

        return res

    def _extract_from_json_ld_product(self, obj: Dict[str, Any], res: Dict[str, Any], base_url: str):
        """Maps schema.org/Product JSON-LD to structured fields."""
        if not res["product_title"] and obj.get("name"):
            res["product_title"] = str(obj["name"]).strip()
            res["declarations"]["commodity_name"] = {"value": res["product_title"], "provenance": "JSON_LD"}

        if not res["brand"]:
            brand_obj = obj.get("brand")
            if isinstance(brand_obj, dict) and brand_obj.get("name"):
                res["brand"] = str(brand_obj["name"]).strip()
            elif isinstance(brand_obj, str):
                res["brand"] = brand_obj.strip()
            if res["brand"]:
                res["declarations"]["brand_name"] = {"value": res["brand"], "provenance": "JSON_LD"}

        if not res["sku"] and obj.get("sku"):
            res["sku"] = str(obj["sku"]).strip()

        if not res["gtin"]:
            gtin = obj.get("gtin13") or obj.get("gtin") or obj.get("gtin8") or obj.get("barcode")
            if gtin:
                res["gtin"] = str(gtin).strip()
                res["declarations"]["barcode"] = {"value": res["gtin"], "provenance": "JSON_LD"}

        if not res["country_of_origin"] and obj.get("countryOfOrigin"):
            res["country_of_origin"] = str(obj["countryOfOrigin"]).strip()
            res["declarations"]["country_of_origin"] = {"value": res["country_of_origin"], "provenance": "JSON_LD"}

        # Offers
        offers = obj.get("offers")
        offer_list = offers if isinstance(offers, list) else [offers] if isinstance(offers, dict) else []
        for o in offer_list:
            if not isinstance(o, dict):
                continue
            price = o.get("price")
            currency = o.get("priceCurrency") or "INR"
            if price and not res["selling_price"]:
                symbol = "₹" if currency in ("INR", "₹") else f"{currency} "
                res["selling_price"] = f"{symbol}{price}"
            seller = o.get("seller")
            if seller and not res["seller"]:
                if isinstance(seller, dict) and seller.get("name"):
                    res["seller"] = str(seller["name"]).strip()
                elif isinstance(seller, str):
                    res["seller"] = seller.strip()

        # Images
        imgs = obj.get("image")
        img_list = imgs if isinstance(imgs, list) else [imgs] if isinstance(imgs, str) else []
        for img in img_list:
            if isinstance(img, str) and img.strip():
                full_img = urljoin(base_url, img.strip())
                if full_img not in res["image_urls"]:
                    res["image_urls"].append(full_img)

    def _map_table_dict_to_declarations(self, table_dict: Dict[str, str], res: Dict[str, Any]):
        """Maps normalized key-value table pairs to Legal Metrology declaration fields."""
        for key, val in table_dict.items():
            val_clean = val.strip()
            if not val_clean:
                continue

            # Manufacturer
            if any(k in key for k in ["manufacturer", "mfg by", "manufactured by"]):
                if not res["manufacturer"]:
                    res["manufacturer"] = val_clean
                    res["declarations"]["manufacturer_name"] = {"value": val_clean, "provenance": "SPECIFICATION_TABLE"}
            # Packer
            elif any(k in key for k in ["packer", "packed by"]):
                if not res["packer"]:
                    res["packer"] = val_clean
                    res["declarations"]["packer_name"] = {"value": val_clean, "provenance": "SPECIFICATION_TABLE"}
            # Importer
            elif any(k in key for k in ["importer", "imported by"]):
                if not res["importer"]:
                    res["importer"] = val_clean
                    res["declarations"]["importer_name"] = {"value": val_clean, "provenance": "SPECIFICATION_TABLE"}
            # Country of Origin
            elif any(k in key for k in ["country of origin", "origin", "country of manufacture"]):
                if not res["country_of_origin"]:
                    res["country_of_origin"] = val_clean
                    res["declarations"]["country_of_origin"] = {"value": val_clean, "provenance": "SPECIFICATION_TABLE"}
            # Net Quantity
            elif any(k in key for k in ["net quantity", "net content", "net weight", "net wt", "quantity"]):
                if not res["net_quantity"]:
                    res["net_quantity"] = val_clean
                    res["declarations"]["net_quantity"] = {"value": val_clean, "provenance": "SPECIFICATION_TABLE"}
            # MRP
            elif any(k in key for k in ["mrp", "maximum retail price"]):
                if not res["mrp"]:
                    res["mrp"] = val_clean
                    res["declarations"]["mrp"] = {"value": val_clean, "provenance": "SPECIFICATION_TABLE"}
            # Unit Sale Price
            elif any(k in key for k in ["unit sale price", "usp", "price per unit"]):
                if not res["unit_sale_price"]:
                    res["unit_sale_price"] = val_clean
                    res["declarations"]["unit_sale_price"] = {"value": val_clean, "provenance": "SPECIFICATION_TABLE"}
            # Consumer Care / Grievance
            elif any(k in key for k in ["consumer care", "customer care", "helpline", "grievance"]):
                if not res["consumer_care"]:
                    res["consumer_care"] = val_clean
                    res["declarations"]["consumer_care"] = {"value": val_clean, "provenance": "SPECIFICATION_TABLE"}
            # Generic / Common Name
            elif any(k in key for k in ["generic name", "common name", "commodity name"]):
                if not res["product_title"] or len(res["product_title"]) > 80:
                    res["declarations"]["commodity_name"] = {"value": val_clean, "provenance": "SPECIFICATION_TABLE"}
            # Best Before / Expiry
            elif any(k in key for k in ["best before", "expiry date", "use by", "shelf life"]):
                if not res["best_before"]:
                    res["best_before"] = val_clean
                    res["declarations"]["best_before"] = {"value": val_clean, "provenance": "SPECIFICATION_TABLE"}

    async def _run_image_ocr_on_listing_images(
        self,
        image_urls: List[str],
        inspection_id: Optional[str]
    ) -> Dict[str, Dict[str, Any]]:
        """
        Safely downloads up to 2 candidate packaging images and runs EasyOCR
        to detect declarations that appear only on the product label.
        """
        ocr_declarations: Dict[str, Dict[str, Any]] = {}
        if not image_urls:
            return ocr_declarations

        ocr_service = get_ocr_service()
        # Try first 2 images
        for idx, img_url in enumerate(image_urls[:2]):
            try:
                # SSRF check image URL
                is_safe, _, _ = self.validate_url_security(img_url)
                if not is_safe:
                    continue

                async with httpx.AsyncClient(timeout=5.0) as client:
                    resp = await client.get(img_url)
                    if resp.status_code != 200 or len(resp.content) > 4 * 1024 * 1024:
                        continue
                    
                    # Validate decodable image bytes
                    try:
                        img = Image.open(io.BytesIO(resp.content))
                        img.verify()
                    except Exception:
                        continue

                    # Save to storage
                    safe_ins_id = inspection_id or f"temp-listing-{uuid.uuid4().hex[:6]}"
                    orig_path, _, _, _, _ = await storage_manager.save_inspection_image(
                        safe_ins_id, resp.content, f"listing_img_{idx}.jpg"
                    )

                    # Run OCR
                    ocr_res = await ocr_service.extract_text(orig_path, f"img-ecom-{idx}", surface_type="FRONT")
                    raw_text = (ocr_res.raw_text or "").lower()

                    # Heuristic detection from OCR text
                    if "net qty" in raw_text or "net weight" in raw_text or "net wt" in raw_text:
                        match = re.search(r'(?:net\s*(?:qty|weight|wt)[^0-9]{0,5})([0-9]+\s*(?:g|kg|ml|l|gm))', raw_text, re.IGNORECASE)
                        if match:
                            ocr_declarations["net_quantity"] = {"value": match.group(1).upper(), "provenance": "IMAGE_OCR"}

                    if "mrp" in raw_text or "incl" in raw_text:
                        match = re.search(r'(?:mrp|₹|rs\.?)[^0-9]{0,5}([0-9,]+(?:\.[0-9]{1,2})?)', raw_text, re.IGNORECASE)
                        if match:
                            ocr_declarations["mrp"] = {"value": f"₹{match.group(1)}", "provenance": "IMAGE_OCR"}

                    if "mfd" in raw_text or "manufactured by" in raw_text:
                        ocr_declarations["manufacturer_name"] = {"value": "Detected on physical package image", "provenance": "IMAGE_OCR"}

                    if "country of origin" in raw_text or "made in" in raw_text:
                        match = re.search(r'(?:country of origin|made in)[:\s]*([a-zA-Z]+)', raw_text, re.IGNORECASE)
                        if match:
                            ocr_declarations["country_of_origin"] = {"value": match.group(1).title(), "provenance": "IMAGE_OCR"}

            except Exception as ocr_err:
                logger.warning(f"Error running OCR on image '{img_url}': {ocr_err}")

        return ocr_declarations

    def _build_rule_6_10_matrix(
        self, declarations: Dict[str, Any]
    ) -> Tuple[List[Dict[str, Any]], List[str]]:
        """
        Builds the statutory digital declaration matrix required under PCR 2011,
        Rule 6(10) (Mandatory E-Commerce Marketplace Disclosures).
        """
        mandatory_checks = [
            ("commodity_name", "Common / Generic Product Name", "Rule 6(1)(a)"),
            ("net_quantity", "Net Quantity", "Rule 6(1)(b)"),
            ("mrp", "Maximum Retail Price (MRP incl. taxes)", "Rule 6(1)(d)"),
            ("country_of_origin", "Country of Origin", "Rule 6(1)(n)"),
            ("manufacturer_name", "Manufacturer / Packer / Importer Details", "Rule 6(1)(a)"),
            ("consumer_care", "Consumer Care / Grievance Redressal", "Rule 6(1)(f)"),
        ]

        matrix = []
        missing = []

        for field_key, label, rule_ref in mandatory_checks:
            decl = declarations.get(field_key)
            val = decl.get("value") if isinstance(decl, dict) else decl
            provenance = decl.get("provenance", "NOT_DETECTED") if isinstance(decl, dict) else "NOT_DETECTED"

            # Check alternative keys for manufacturer (packer or importer)
            if field_key == "manufacturer_name" and not val:
                packer = declarations.get("packer_name")
                importer = declarations.get("importer_name")
                if packer:
                    val = packer.get("value") if isinstance(packer, dict) else packer
                    provenance = packer.get("provenance", "SPECIFICATION_TABLE") if isinstance(packer, dict) else "SPECIFICATION_TABLE"
                elif importer:
                    val = importer.get("value") if isinstance(importer, dict) else importer
                    provenance = importer.get("provenance", "SPECIFICATION_TABLE") if isinstance(importer, dict) else "SPECIFICATION_TABLE"

            is_present = bool(val and str(val).strip())
            if is_present:
                matrix.append({
                    "field_name": field_key,
                    "label": label,
                    "statutory_rule": rule_ref,
                    "status": "DETECTED",
                    "value": str(val),
                    "provenance": provenance,
                    "exempt": False
                })
            else:
                missing.append(label)
                matrix.append({
                    "field_name": field_key,
                    "label": label,
                    "statutory_rule": rule_ref,
                    "status": "NOT_DETECTED",
                    "value": None,
                    "provenance": "NOT_DETECTED",
                    "exempt": False
                })

        # Add Rule 6(10) Statutory Exemption Note:
        matrix.append({
            "field_name": "manufacturing_date",
            "label": "Month & Year of Manufacture / Packing",
            "statutory_rule": "Rule 6(10) Proviso",
            "status": "EXEMPT",
            "value": "Statutorily exempt on digital PDP (provided best before declared where applicable)",
            "provenance": "STATUTORY_EXEMPTION",
            "exempt": True
        })

        return matrix, missing


online_listing_service = OnlineListingService()
