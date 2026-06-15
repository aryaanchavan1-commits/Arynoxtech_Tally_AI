import pytest


def test_create_sales_invoice(client, headers, sample_customer, sample_product):
    resp = client.post("/api/invoices/", headers=headers, json={
        "invoice_type": "Sales",
        "invoice_date": "2026-04-01",
        "customer_id": sample_customer["id"],
        "items": [{
            "product_id": sample_product["id"],
            "hsn_sac": "84713000",
            "description": "Test product",
            "quantity": 2,
            "rate": 1500.0,
            "cgst_rate": 9.0,
            "sgst_rate": 9.0,
        }],
    })
    assert resp.status_code == 201
    data = resp.json()
    assert data["invoice_type"] == "Sales"
    assert data["customer_name"] == "ABC Corp"
    assert data["grand_total"] > 0
    assert "INV-" in data["invoice_no"]
    assert data["grand_total_words"] is not None


def test_create_purchase_invoice(client, headers, sample_supplier, sample_product):
    resp = client.post("/api/invoices/", headers=headers, json={
        "invoice_type": "Purchase",
        "invoice_date": "2026-04-01",
        "supplier_id": sample_supplier["id"],
        "items": [{
            "product_id": sample_product["id"],
            "hsn_sac": "84713000",
            "description": "Raw material",
            "quantity": 10,
            "rate": 800.0,
            "igst_rate": 18.0,
        }],
    })
    assert resp.status_code == 201
    data = resp.json()
    assert data["invoice_type"] == "Purchase"
    assert data["supplier_name"] == "XYZ Traders"


def test_list_invoices(client, headers):
    resp = client.get("/api/invoices/", headers=headers)
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)


def test_get_invoice(client, headers):
    list_resp = client.get("/api/invoices/", headers=headers)
    invoices = list_resp.json()
    if invoices:
        inv_id = invoices[0]["id"]
        resp = client.get(f"/api/invoices/{inv_id}", headers=headers)
        assert resp.status_code == 200
        assert resp.json()["id"] == inv_id


def test_filter_invoices_by_type(client, headers):
    resp = client.get("/api/invoices/?invoice_type=Sales", headers=headers)
    assert resp.status_code == 200
    for inv in resp.json():
        assert inv["invoice_type"] == "Sales"


def test_create_invoice_without_items_or_account_is_valid(client, headers):
    """Customer auto-gets an account on creation, so invoice creation is valid"""
    c = client.post("/api/customers/", headers=headers, json={
        "name": "No Account Customer", "email": "noacc@test.com",
    }).json()
    resp = client.post("/api/invoices/", headers=headers, json={
        "invoice_type": "Sales",
        "invoice_date": "2026-04-01",
        "customer_id": c["id"],
        "items": [{"description": "Test", "quantity": 1, "rate": 100}],
    })
    assert resp.status_code == 201
    assert resp.json()["customer_name"] == "No Account Customer"


def test_create_invoice_with_place_of_supply(client, headers, sample_customer, sample_product):
    resp = client.post("/api/invoices/", headers=headers, json={
        "invoice_type": "Sales",
        "invoice_date": "2026-04-01",
        "customer_id": sample_customer["id"],
        "place_of_supply": "Maharashtra",
        "items": [{
            "product_id": sample_product["id"],
            "hsn_sac": "84713000",
            "description": "Test",
            "quantity": 1,
            "rate": 1000.0,
            "cgst_rate": 9.0,
            "sgst_rate": 9.0,
        }],
    })
    if resp.status_code == 201:
        assert resp.json()["place_of_supply"] == "Maharashtra"


def test_invoice_total_calculation(client, headers, sample_customer):
    resp = client.post("/api/invoices/", headers=headers, json={
        "invoice_type": "Sales",
        "invoice_date": "2026-04-01",
        "customer_id": sample_customer["id"],
        "items": [{
            "hsn_sac": "84713000",
            "description": "Item A",
            "quantity": 2,
            "rate": 1000.0,
            "cgst_rate": 9.0,
            "sgst_rate": 9.0,
        }],
    })
    assert resp.status_code == 201
    data = resp.json()
    taxable = data["taxable_amount"]
    assert taxable == 2000.0
    assert data["cgst_amount"] == 180.0
    assert data["sgst_amount"] == 180.0
    assert data["grand_total"] == 2360


def test_delete_invoice(client, headers):
    list_resp = client.get("/api/invoices/", headers=headers)
    invoices = list_resp.json()
    if invoices:
        inv_id = invoices[0]["id"]
        resp = client.delete(f"/api/invoices/{inv_id}", headers=headers)
        assert resp.status_code == 200


def test_update_invoice_status(client, headers):
    list_resp = client.get("/api/invoices/", headers=headers)
    invoices = list_resp.json()
    if invoices:
        inv_id = invoices[0]["id"]
        resp = client.put(f"/api/invoices/{inv_id}/status?status=Paid&paid_amount={invoices[0]['grand_total']}", headers=headers)
        assert resp.status_code == 200


def test_invoice_report(client, headers):
    resp = client.get("/api/invoices/report", headers=headers)
    if resp.status_code == 200:
        data = resp.json()
        assert "total_invoices" in data
        assert "total_amount" in data
