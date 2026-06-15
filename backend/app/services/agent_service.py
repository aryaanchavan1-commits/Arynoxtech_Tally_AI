import json
import re
import httpx
from typing import Any
from sqlalchemy.orm import Session
from app.models.accounting import Account, Voucher, AccountingEntry
from app.models.customer import Customer
from app.models.supplier import Supplier
from app.models.inventory import Product
from app.models.invoice import Invoice

AGENT_SYSTEM_PROMPT = """You are Arynox Agent, an AI assistant that can perform tasks in Arynoxtech Tally accounting software.
You have access to business data and can perform actions on behalf of the user.

AVAILABLE ACTIONS (output as JSON when you want to perform an action):
1. create_customer - Create a new customer
   params: name, phone, email, address, gstin, opening_balance (number)
2. update_customer - Update customer details
   params: id (required), name, phone, email, address, gstin
3. delete_customer - Delete a customer
   params: id (required)
4. create_account - Create a new chart of account
   params: name, account_type (Current Assets/Fixed Assets/Revenue/Expenses/etc), group_name, opening_balance (number)
5. create_voucher - Create a new voucher entry
   params: voucher_type (Payment/Receipt/Sales/Purchase/Journal), date, narration, total_amount (number), entries (list of {account_id, debit, credit, particular})
6. create_invoice - Create a new invoice
   params: invoice_no, invoice_date, customer_id, due_date, grand_total (number)
7. create_product - Create a new product
   params: name, sku, selling_price (number), purchase_price (number), current_stock (number), unit, category_id (number)
8. search_records - Search for any records
   params: query

RULES:
- When the user asks you to DO something (create, update, delete), output JSON with proposed actions
- When the user just asks a QUESTION, respond normally with text
- Always ask for confirmation before performing actions
- Always output valid JSON wrapped in ```json ... ``` tags
- Output format for actions:
```json
{
  "agent_action": true,
  "actions": [
    {
      "action": "action_name",
      "params": { "key": "value" },
      "description": "Clear description of what will be done"
    }
  ],
  "message": "Explanation to the user asking for confirmation"
}
```

For questions, just respond conversationally.
Keep responses concise and practical for Indian small business context."""


def extract_action_json(text: str) -> dict | None:
    json_match = re.search(r"```json\s*(\{.*?\})\s*```", text, re.DOTALL)
    if json_match:
        try:
            return json.loads(json_match.group(1))
        except json.JSONDecodeError:
            return None
    try:
        parsed = json.loads(text)
        if isinstance(parsed, dict) and parsed.get("agent_action"):
            return parsed
    except json.JSONDecodeError:
        pass
    return None


async def call_ai(prompt: str, api_key: str, provider_config: dict, model: str, system_prompt: str, timeout: int = 60) -> str:
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }
    if provider_config.get("name") == "openrouter":
        headers["HTTP-Referer"] = "https://arynoxtech.com"
        headers["X-Title"] = "Arynoxtech Tally"

    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": prompt},
        ],
        "max_tokens": 2048,
        "temperature": 0.3,
    }

    async with httpx.AsyncClient(timeout=timeout) as client:
        resp = await client.post(
            f"{provider_config['base_url']}/chat/completions",
            headers=headers,
            json=payload,
        )
        if resp.status_code == 200:
            return resp.json()["choices"][0]["message"]["content"]
        try:
            err = resp.json().get("error", {}).get("message", "") or resp.text[:200]
        except Exception:
            err = resp.text[:200]
        raise Exception(f"AI API Error ({resp.status_code}): {err}")


def execute_action(action: str, params: dict, db: Session, user_id: int) -> dict:
    if action == "create_customer":
        customer = Customer(
            name=params.get("name", ""),
            phone=params.get("phone", ""),
            email=params.get("email", ""),
            address=params.get("address", ""),
            gstin=params.get("gstin", ""),
            opening_balance=float(params.get("opening_balance", 0)),
            user_id=user_id,
        )
        db.add(customer)
        db.commit()
        db.refresh(customer)
        return {"success": True, "message": f"Customer '{customer.name}' created (ID: {customer.id})", "id": customer.id}

    elif action == "update_customer":
        customer = db.query(Customer).filter(Customer.id == params.get("id"), Customer.user_id == user_id).first()
        if not customer:
            return {"success": False, "message": "Customer not found"}
        for key in ("name", "phone", "email", "address", "gstin"):
            if key in params:
                setattr(customer, key, params[key])
        db.commit()
        return {"success": True, "message": f"Customer '{customer.name}' updated"}

    elif action == "delete_customer":
        customer = db.query(Customer).filter(Customer.id == params.get("id"), Customer.user_id == user_id).first()
        if not customer:
            return {"success": False, "message": "Customer not found"}
        name = customer.name
        db.delete(customer)
        db.commit()
        return {"success": True, "message": f"Customer '{name}' deleted"}

    elif action == "create_account":
        account = Account(
            name=params.get("name", ""),
            account_type=params.get("account_type", "Current Assets"),
            group_name=params.get("group_name", ""),
            opening_balance=float(params.get("opening_balance", 0)),
            user_id=user_id,
        )
        db.add(account)
        db.commit()
        db.refresh(account)
        return {"success": True, "message": f"Account '{account.name}' created (ID: {account.id})", "id": account.id}

    elif action == "create_voucher":
        from datetime import datetime
        voucher = Voucher(
            voucher_no=params.get("voucher_no", f"V{datetime.utcnow().strftime('%Y%m%d%H%M%S')}"),
            voucher_type=params.get("voucher_type", "Payment"),
            date=datetime.fromisoformat(params["date"]) if params.get("date") else datetime.utcnow(),
            narration=params.get("narration", ""),
            total_amount=float(params.get("total_amount", 0)),
            user_id=user_id,
        )
        db.add(voucher)
        db.commit()
        db.refresh(voucher)

        entries = params.get("entries", [])
        for e in entries:
            entry = AccountingEntry(
                voucher_id=voucher.id,
                account_id=e.get("account_id"),
                debit=float(e.get("debit", 0)),
                credit=float(e.get("credit", 0)),
                particular=e.get("particular", ""),
            )
            db.add(entry)
        db.commit()
        return {"success": True, "message": f"Voucher #{voucher.voucher_no} created (ID: {voucher.id})", "id": voucher.id}

    elif action == "create_invoice":
        from datetime import date
        invoice = Invoice(
            invoice_no=params.get("invoice_no", f"INV-{date.today().strftime('%Y%m%d')}"),
            invoice_type=params.get("invoice_type", "Sales"),
            invoice_date=date.fromisoformat(params["invoice_date"]) if params.get("invoice_date") else date.today(),
            due_date=date.fromisoformat(params["due_date"]) if params.get("due_date") else None,
            customer_id=params.get("customer_id"),
            grand_total=float(params.get("grand_total", 0)),
            status=params.get("status", "Unpaid"),
            user_id=user_id,
        )
        db.add(invoice)
        db.commit()
        db.refresh(invoice)
        return {"success": True, "message": f"Invoice '{invoice.invoice_no}' created (ID: {invoice.id})", "id": invoice.id}

    elif action == "create_product":
        product = Product(
            name=params.get("name", ""),
            sku=params.get("sku", ""),
            selling_price=float(params.get("selling_price", 0)),
            purchase_price=float(params.get("purchase_price", 0)),
            current_stock=float(params.get("current_stock", 0)),
            opening_stock=float(params.get("current_stock", 0)),
            category_id=params.get("category_id"),
            unit=params.get("unit", "Pieces"),
            user_id=user_id,
        )
        db.add(product)
        db.commit()
        db.refresh(product)
        return {"success": True, "message": f"Product '{product.name}' created (ID: {product.id})", "id": product.id}

    elif action == "search_records":
        query = params.get("query", "")
        results = []
        for model, fields in [(Customer, ["name", "phone", "email", "gstin"]),
                              (Supplier, ["name", "phone", "email", "gstin"]),
                              (Product, ["name", "sku"]),
                              (Account, ["name", "group_name", "account_type"])]:
            for field in fields:
                records = db.query(model).filter(
                    getattr(model, field).ilike(f"%{query}%")
                ).limit(5).all()
                for r in records:
                    results.append({"type": model.__name__, "id": r.id, "name": getattr(r, "name", "")})
                    break
        return {"success": True, "message": f"Found {len(results)} results", "results": results}

    return {"success": False, "message": f"Unknown action: {action}"}
