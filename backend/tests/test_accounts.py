def test_create_account(client, headers):
    response = client.post("/api/accounts/", headers=headers, json={
        "name": "Bank Account",
        "group_name": "Bank Accounts",
        "account_type": "Bank",
        "opening_balance": 50000,
    })
    assert response.status_code == 201
    assert response.json()["name"] == "Bank Account"


def test_list_accounts(client, headers):
    response = client.get("/api/accounts/", headers=headers)
    assert response.status_code == 200


def test_create_voucher(client, headers):
    acc_response = client.get("/api/accounts/", headers=headers)
    accounts = acc_response.json()
    if len(accounts) < 2:
        client.post("/api/accounts/", headers=headers, json={
            "name": "Sales Account", "group_name": "Direct Income", "account_type": "Income",
        })
    acc_response = client.get("/api/accounts/", headers=headers)
    accounts = acc_response.json()

    response = client.post("/api/vouchers/", headers=headers, json={
        "voucher_type": "Journal",
        "date": "2026-01-01",
        "narration": "Test entry",
        "entries": [
            {"account_id": accounts[0]["id"], "debit": 1000, "credit": 0, "particular": "Test debit"},
            {"account_id": accounts[1]["id"], "debit": 0, "credit": 1000, "particular": "Test credit"},
        ],
    })
    assert response.status_code == 201
    assert "voucher_no" in response.json()
