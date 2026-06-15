import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.database import Base, engine


@pytest.fixture(scope="session", autouse=True)
def clean_db():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    yield


@pytest.fixture(scope="session")
def client():
    c = TestClient(app)
    yield c


@pytest.fixture(scope="session")
def auth_token(client):
    resp = client.post("/api/auth/register", json={
        "full_name": "Test User", "username": "testuser", "password": "testpass123",
    })
    if resp.status_code == 201:
        return resp.json()["access_token"]
    resp = client.post("/api/auth/login", json={
        "username": "testuser", "password": "testpass123",
    })
    return resp.json()["access_token"]


@pytest.fixture
def headers(auth_token):
    return {"Authorization": f"Bearer {auth_token}"}


@pytest.fixture
def cash_account(client, headers):
    resp = client.post("/api/accounts/", headers=headers, json={
        "name": "Cash", "group_name": "Cash in Hand", "account_type": "Cash", "opening_balance": 50000,
    })
    if resp.status_code == 201:
        return resp.json()
    accounts = client.get("/api/accounts/", headers=headers).json()
    for a in accounts:
        if a["name"] == "Cash":
            return a
    return {"id": 1, "name": "Cash"}


@pytest.fixture
def sample_customer(client, headers, cash_account):
    resp = client.post("/api/customers/", headers=headers, json={
        "name": "ABC Corp", "email": "abc@test.com", "phone": "9876543210",
        "gstin": "27AABCU9603R1ZM", "city": "Mumbai", "state": "Maharashtra",
        "account_id": cash_account["id"],
    })
    return resp.json()


@pytest.fixture
def sample_supplier(client, headers, cash_account):
    resp = client.post("/api/suppliers/", headers=headers, json={
        "name": "XYZ Traders", "email": "xyz@test.com", "phone": "9876543211",
        "gstin": "29AABCU9603R1ZP", "city": "Bengaluru", "state": "Karnataka",
        "account_id": cash_account["id"],
    })
    return resp.json()


@pytest.fixture
def sample_product(client, headers):
    resp = client.post("/api/inventory/products/", headers=headers, json={
        "name": "Test Product", "sku": "TST001", "unit": "NOS",
        "purchase_price": 100, "selling_price": 150, "current_stock": 1000,
        "gst_rate": 18, "hsn_sac": "84713000",
    })
    if resp.status_code == 201:
        return resp.json()
    products = client.get("/api/inventory/products/", headers=headers).json()
    for p in products:
        if p["sku"] == "TST001":
            return p
    return resp.json()
