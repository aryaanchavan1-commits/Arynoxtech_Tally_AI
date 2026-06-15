import pytest


def test_create_product(client, headers):
    resp = client.post("/api/inventory/products/", headers=headers, json={
        "name": "Widget Pro", "sku": "WGT001", "unit": "NOS",
        "purchase_price": 50, "selling_price": 120, "current_stock": 500,
        "gst_rate": 18, "hsn_sac": "84713000",
    })
    assert resp.status_code == 201


def test_list_products(client, headers):
    resp = client.get("/api/inventory/products/", headers=headers)
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)


def test_create_category(client, headers):
    resp = client.post("/api/inventory/categories/", headers=headers, json={
        "name": "Electronics", "description": "Electronic items",
    })
    assert resp.status_code == 201
    assert resp.json()["name"] == "Electronics"


def test_low_stock_products(client, headers):
    resp = client.get("/api/inventory/products/low-stock/list", headers=headers)
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)


def test_delete_product(client, headers):
    resp = client.get("/api/inventory/products/", headers=headers)
    products = resp.json()
    if products:
        pid = products[0]["id"]
        resp = client.delete(f"/api/inventory/products/{pid}", headers=headers)
        assert resp.status_code == 200


def test_expense_flow(client, headers):
    cat_resp = client.post("/api/expenses/categories", headers=headers, json={
        "name": "Office Supplies",
    })
    cat_id = cat_resp.json()["id"]

    resp = client.post("/api/expenses/", headers=headers, json={
        "category_id": cat_id, "amount": 5000, "expense_date": "2026-04-01",
        "payment_mode": "Cash", "description": "Stationery",
    })
    assert resp.status_code == 201
    data = resp.json()
    assert data["amount"] == 5000
    assert data["category_name"] == "Office Supplies"

    list_resp = client.get("/api/expenses/", headers=headers)
    assert list_resp.status_code == 200

    eid = list_resp.json()[0]["id"]
    del_resp = client.delete(f"/api/expenses/{eid}", headers=headers)
    assert del_resp.status_code == 200


def test_dashboard_summary(client, headers):
    resp = client.get("/api/dashboard/summary", headers=headers)
    assert resp.status_code == 200
    data = resp.json()
    assert "total_revenue" in data
    assert "total_expenses" in data
    assert "net_profit" in data


def test_reports_trial_balance(client, headers):
    resp = client.get("/api/reports/trial-balance", headers=headers)
    assert resp.status_code == 200
    assert "items" in resp.json()


def test_reports_profit_loss(client, headers):
    resp = client.get("/api/reports/profit-loss?from_date=2026-01-01&to_date=2026-12-31", headers=headers)
    assert resp.status_code == 200


def test_reports_balance_sheet(client, headers):
    resp = client.get("/api/reports/balance-sheet", headers=headers)
    assert resp.status_code == 200


def test_backup_flow(client, headers):
    resp = client.post("/api/backup/create?description=Test+Backup", headers=headers)
    assert resp.status_code == 200

    list_resp = client.get("/api/backup/list", headers=headers)
    assert list_resp.status_code == 200
    backups = list_resp.json()
    if backups:
        bid = backups[0]["id"]
        del_resp = client.delete(f"/api/backup/{bid}", headers=headers)
        assert del_resp.status_code == 200


def test_enterprise_company(client, headers):
    resp = client.post("/api/enterprise/companies", headers=headers, json={
        "name": "My Business", "city": "Pune", "state": "Maharashtra",
    })
    assert resp.status_code == 201
    assert resp.json()["name"] == "My Business"

    list_resp = client.get("/api/enterprise/companies", headers=headers)
    assert list_resp.status_code == 200


def test_health_check(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.json()["status"] == "healthy"


def test_cors_headers(client):
    resp = client.options("/api/auth/login", headers={
        "Origin": "http://localhost:3000",
        "Access-Control-Request-Method": "POST",
    })
    assert resp.status_code == 200
