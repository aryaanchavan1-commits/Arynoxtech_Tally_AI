import pytest


def test_create_customer(client, headers):
    resp = client.post("/api/customers/", headers=headers, json={
        "name": "Test Customer", "email": "cust@test.com", "phone": "9876543210",
        "gstin": "27AABCU9603R1ZM", "city": "Mumbai", "state": "Maharashtra",
    })
    assert resp.status_code == 201
    data = resp.json()
    assert data["name"] == "Test Customer"


def test_list_customers(client, headers):
    resp = client.get("/api/customers/", headers=headers)
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)


def test_get_customer(client, headers):
    resp = client.get("/api/customers/", headers=headers)
    customers = resp.json()
    if customers:
        cid = customers[0]["id"]
        resp = client.get(f"/api/customers/{cid}", headers=headers)
        assert resp.status_code == 200
        assert resp.json()["id"] == cid


def test_update_customer(client, headers):
    resp = client.get("/api/customers/", headers=headers)
    customers = resp.json()
    if customers:
        cid = customers[0]["id"]
        resp = client.put(f"/api/customers/{cid}", headers=headers, json={"name": "Updated Name"})
        assert resp.status_code == 200
        assert resp.json()["name"] == "Updated Name"


def test_customer_gstin_validation(client, headers):
    resp = client.post("/api/customers/", headers=headers, json={
        "name": "Bad GST", "gstin": "invalid-gst",
    })
    assert resp.status_code == 422


def test_create_supplier(client, headers):
    resp = client.post("/api/suppliers/", headers=headers, json={
        "name": "Test Supplier", "email": "supp@test.com", "phone": "9876543211",
        "gstin": "29AABCU9603R1ZP", "city": "Bengaluru", "state": "Karnataka",
    })
    assert resp.status_code == 201
    assert resp.json()["name"] == "Test Supplier"


def test_list_suppliers(client, headers):
    resp = client.get("/api/suppliers/", headers=headers)
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)


def test_delete_supplier(client, headers):
    resp = client.get("/api/suppliers/", headers=headers)
    suppliers = resp.json()
    if suppliers:
        sid = suppliers[0]["id"]
        resp = client.delete(f"/api/suppliers/{sid}", headers=headers)
        assert resp.status_code == 200
