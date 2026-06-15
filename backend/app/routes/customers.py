from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from sqlalchemy import func
from datetime import datetime
from app.database import get_db
from app.models.customer import Customer
from app.models.accounting import Account, Voucher, AccountingEntry
from app.schemas.customer import CustomerCreate, CustomerUpdate, CustomerResponse
from app.routes.auth import get_current_user

router = APIRouter(prefix="/api/customers", tags=["Customers"])


@router.get("/", response_model=List[CustomerResponse])
def list_customers(search: Optional[str] = None, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    query = db.query(Customer).filter(Customer.user_id == user_id)
    if search:
        query = query.filter(
            Customer.name.ilike(f"%{search}%") |
            Customer.mobile.ilike(f"%{search}%") |
            Customer.email.ilike(f"%{search}%")
        )
    return query.order_by(Customer.name).all()


@router.post("/", response_model=CustomerResponse, status_code=201)
def create_customer(data: CustomerCreate, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    account = Account(
        name=data.name,
        group_name="Receivables",
        account_type="Assets",
        opening_balance=data.opening_balance,
        current_balance=data.opening_balance,
        user_id=user_id,
    )
    db.add(account)
    db.flush()

    customer = Customer(
        name=data.name,
        company_name=data.company_name,
        email=data.email,
        phone=data.phone,
        mobile=data.mobile,
        gstin=data.gstin,
        pan=data.pan,
        address=data.address,
        city=data.city,
        state=data.state,
        pincode=data.pincode,
        country=data.country,
        credit_limit=data.credit_limit,
        opening_balance=data.opening_balance,
        current_balance=data.opening_balance,
        account_id=account.id,
        notes=data.notes,
        user_id=user_id,
    )
    db.add(customer)
    db.commit()
    db.refresh(customer)
    return customer


@router.get("/{customer_id}", response_model=CustomerResponse)
def get_customer(customer_id: int, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    customer = db.query(Customer).filter(Customer.id == customer_id, Customer.user_id == user_id).first()
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found")
    return customer


@router.put("/{customer_id}", response_model=CustomerResponse)
def update_customer(customer_id: int, data: CustomerUpdate, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    customer = db.query(Customer).filter(Customer.id == customer_id, Customer.user_id == user_id).first()
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found")

    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(customer, field, value)

    db.commit()
    db.refresh(customer)
    return customer


@router.delete("/{customer_id}")
def delete_customer(customer_id: int, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    customer = db.query(Customer).filter(Customer.id == customer_id, Customer.user_id == user_id).first()
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found")
    db.delete(customer)
    db.commit()
    return {"message": "Customer deleted successfully"}


@router.get("/{customer_id}/statement")
def customer_statement(customer_id: int, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    customer = db.query(Customer).filter(Customer.id == customer_id, Customer.user_id == user_id).first()
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found")

    entries = db.query(AccountingEntry).join(Voucher).filter(
        AccountingEntry.account_id == customer.account_id,
        Voucher.user_id == user_id,
        Voucher.is_cancelled == False,
    ).order_by(Voucher.date).all()

    balance = customer.opening_balance
    statement = []
    for entry in entries:
        if entry.debit > 0:
            balance -= entry.debit
        if entry.credit > 0:
            balance += entry.credit
        statement.append({
            "date": entry.voucher.date.isoformat() if entry.voucher.date else None,
            "voucher_no": entry.voucher.voucher_no,
            "type": entry.voucher.voucher_type,
            "debit": entry.debit,
            "credit": entry.credit,
            "balance": balance,
        })

    return {
        "customer": {"id": customer.id, "name": customer.name},
        "opening_balance": customer.opening_balance,
        "current_balance": customer.current_balance,
        "outstanding": customer.outstanding_amount,
        "statement": statement,
    }
