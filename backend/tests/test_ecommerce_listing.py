import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.services.listing.listing_service import online_listing_service


@pytest.mark.asyncio
async def test_url_security_accepts_valid_public_https():
    is_safe, msg, ip = online_listing_service.validate_url_security("https://www.google.com")
    assert is_safe is True
    assert "safe" in msg.lower()


@pytest.mark.asyncio
async def test_url_security_rejects_invalid_schemes():
    invalid_urls = [
        "file:///etc/passwd",
        "javascript:alert(1)",
        "data:text/html,<html>test</html>",
        "ftp://example.com/file",
        "gopher://example.com"
    ]
    for url in invalid_urls:
        is_safe, msg, _ = online_listing_service.validate_url_security(url)
        assert is_safe is False
        assert "only public http and https" in msg.lower() or "invalid protocol" in msg.lower()


@pytest.mark.asyncio
async def test_url_security_blocks_localhost_and_private_ips():
    blocked_urls = [
        "http://localhost:8000/test",
        "http://127.0.0.1:8000/admin",
        "http://10.0.0.1/status",
        "http://192.168.1.1/router",
        "http://172.16.0.1/internal",
        "http://[::1]:8080/debug",
        "http://169.254.169.254/latest/meta-data/"
    ]
    for url in blocked_urls:
        is_safe, msg, _ = online_listing_service.validate_url_security(url)
        assert is_safe is False, f"Expected {url} to be blocked by SSRF protection"
        assert "prohibited" in msg.lower() or "restricted" in msg.lower() or "violation" in msg.lower()


def test_marketplace_detection():
    cases = [
        ("https://www.amazon.in/dp/B08XYZ123", "Amazon India"),
        ("https://www.flipkart.com/product/p/itm123", "Flipkart"),
        ("https://blinkit.com/prn/pure-ghee/prid/456", "Blinkit"),
        ("https://www.zeptonow.com/pn/wheat-flour/pvid/789", "Zepto"),
        ("https://www.swiggy.com/instamart/item/101", "Swiggy Instamart"),
        ("https://www.bigbasket.com/pd/123/rice", "BigBasket"),
        ("https://organicstore.in/products/honey", "Organicstore.In"),
    ]
    for url, expected in cases:
        detected = online_listing_service.detect_marketplace(url)
        assert detected == expected


def test_json_ld_and_table_extraction():
    html_sample = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Heritage Pure Cow Ghee 1L - Best Price in India</title>
        <meta property="og:title" content="Heritage Pure Cow Ghee 1 Litre Pack" />
        <meta property="og:brand" content="Heritage Foods" />
        <meta property="product:price:amount" content="650.00" />
        <script type="application/ld+json">
        {
            "@context": "https://schema.org/",
            "@type": "Product",
            "name": "Heritage Pure Cow Ghee 1L",
            "image": "https://cdn.example.com/ghee_front.jpg",
            "sku": "HER-GHEE-1L",
            "gtin13": "8901234567890",
            "brand": {
                "@type": "Brand",
                "name": "Heritage"
            },
            "countryOfOrigin": "India",
            "offers": {
                "@type": "Offer",
                "priceCurrency": "INR",
                "price": "650",
                "seller": {
                    "@type": "Organization",
                    "name": "Heritage Consumer Direct"
                }
            }
        }
        </script>
    </head>
    <body>
        <h1>Heritage Pure Cow Ghee 1 Litre Jar</h1>
        <table class="spec-table">
            <tr><th>Net Quantity</th><td>1 L</td></tr>
            <tr><th>Maximum Retail Price</th><td>₹650.00 (inclusive of all taxes)</td></tr>
            <tr><th>Unit Sale Price</th><td>₹0.65 / 1 ml</td></tr>
            <tr><th>Manufactured By</th><td>Heritage Foods Limited, Kasipentla Village, Tirupati District, AP - 517112</td></tr>
            <tr><th>Country of Origin</th><td>India</td></tr>
            <tr><th>Consumer Care</th><td>care@heritagefoods.in, Toll Free: 1800-425-4444</td></tr>
            <tr><th>Best Before</th><td>9 Months from Packing</td></tr>
        </table>
    </body>
    </html>
    """
    extracted = online_listing_service._parse_listing_html(
        html_sample, "https://example.com/heritage-ghee", "Example Marketplace"
    )

    assert extracted["product_title"] == "Heritage Pure Cow Ghee 1L"
    assert extracted["brand"] == "Heritage"
    assert extracted["net_quantity"] == "1 L"
    assert "650" in extracted["mrp"]
    assert extracted["country_of_origin"] == "India"
    assert "Heritage Foods Limited" in extracted["manufacturer"]
    assert "care@heritagefoods.in" in extracted["consumer_care"]
    assert len(extracted["image_urls"]) > 0

    # Verify Rule 6(10) matrix
    matrix, missing = online_listing_service._build_rule_6_10_matrix(extracted["declarations"])
    assert len(missing) == 0, f"Expected 0 missing declarations, got: {missing}"

    # Verify Rule 6(10) manufacturing date exemption is explicitly documented
    mfg_entry = next((item for item in matrix if item["field_name"] == "manufacturing_date"), None)
    assert mfg_entry is not None
    assert mfg_entry["status"] == "EXEMPT"
    assert mfg_entry["exempt"] is True


def test_missing_declarations_triggers_partial_status():
    incomplete_html = """
    <html>
    <head><title>Random Item</title></head>
    <body>
        <h1>Novelty Ceramic Mug</h1>
        <div class="price">₹199</div>
    </body>
    </html>
    """
    extracted = online_listing_service._parse_listing_html(
        incomplete_html, "https://example.com/mug", "Example"
    )
    matrix, missing = online_listing_service._build_rule_6_10_matrix(extracted["declarations"])
    assert len(missing) > 0
    assert any("Net Quantity" in m for m in missing)
    assert any("Manufacturer" in m for m in missing)
    assert any("Country of Origin" in m for m in missing)


@pytest.mark.asyncio
async def test_api_fetch_rejects_ssrf_and_invalid_urls():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # Login
        login_res = await ac.post("/api/auth/login", json={
            "email": "inspector@demo.gov.in",
            "password": "Inspector@123"
        })
        token = login_res.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # 1. Private IP SSRF attempt
        res = await ac.post("/api/listings/fetch", json={
            "url": "http://127.0.0.1:8000/secret"
        }, headers=headers)
        assert res.status_code == 200
        data = res.json()
        assert data["fetch_status"] == "BLOCKED"
        assert "ssrf" in data["warnings"][0].lower() or "restricted" in data["error_message"].lower()

        # 2. Invalid scheme
        res2 = await ac.post("/api/listings/fetch", json={
            "url": "file:///etc/passwd"
        }, headers=headers)
        assert res2.status_code == 200
        data2 = res2.json()
        assert data2["fetch_status"] == "BLOCKED"


@pytest.mark.asyncio
async def test_api_create_ecommerce_inspection_and_analyze():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        login_res = await ac.post("/api/auth/login", json={
            "email": "inspector@demo.gov.in",
            "password": "Inspector@123"
        })
        token = login_res.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # 1. Create E-Commerce Inspection
        create_res = await ac.post("/api/inspections", json={
            "inspection_type": "ONLINE_LISTING",
            "marketplace": "Amazon India",
            "listing_url": "https://www.amazon.in/dp/B08DEMO123",
            "seller_name": "Cloudtail India",
            "business_name": "Amazon Seller Services Pvt Ltd",
            "product_category": "Packaged Food",
            "notes": "Verified public listing inspection"
        }, headers=headers)

        assert create_res.status_code == 200
        ins = create_res.json()
        assert ins["inspection_type"] == "ONLINE_LISTING"
        assert ins["marketplace"] == "Amazon India"
        assert ins["listing_url"] == "https://www.amazon.in/dp/B08DEMO123"
        ins_id = ins["id"]

        # 2. Run Compliance Analysis with simulated extracted listing data
        analyze_res = await ac.post("/api/listings/analyze", json={
            "inspection_id": ins_id,
            "extracted_data": {
                "commodity_name": {"value": "Organic Cold Pressed Groundnut Oil", "confidence": 0.98},
                "net_quantity": {"value": "1 Litre", "confidence": 0.95},
                "mrp": {"value": "₹349", "confidence": 0.99},
                "country_of_origin": {"value": "India", "confidence": 0.99},
                "manufacturer_name": {"value": "Pure Organics Agro Farms, Gujarat", "confidence": 0.95},
                "consumer_care": {"value": "care@pureorganics.in", "confidence": 0.90}
            }
        }, headers=headers)

        assert analyze_res.status_code == 200
        analysis = analyze_res.json()
        assert analysis["success"] is True
        assessment = analysis["assessment"]
        assert "overall_status" in assessment
        assert assessment["overall_status"] in ("PASS", "REVIEW", "POTENTIAL_VIOLATION")

        # 3. Verify Inspection is updated with declarations and status
        get_res = await ac.get(f"/api/inspections/{ins_id}", headers=headers)
        assert get_res.status_code == 200
        ins_detail = get_res.json()
        assert ins_detail["inspection_type"] == "ONLINE_LISTING"
        assert len(ins_detail["declarations"]) > 0
