from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from sqlalchemy import func
from app.database import get_db
from app.models.supplier import Supplier
from app.models.accounting import Account, Voucher, AccountingEntry
from app.schemas.supplier import SupplierCreate, SupplierUpdate, SupplierResponse
from app.routes.auth import get_current_user

router = APIRouter(prefix="/api/suppliers", tags=["Suppliers"])


@router.get("/", response_model=List[SupplierResponse])
def list_suppliers(search: Optional[str] = None, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    query = db.query(Supplier).filter(Supplier.user_id == user_id)
    if search:
        query = query.filter(
            Supplier.name.ilike(f"%{search}%") |
            Supplier.mobile.ilike(f"%{search}%") |
            Supplier.email.ilike(f"%{search}%")
        )
    return query.order_by(Supplier.name).all()


@router.post("/", response_model=SupplierResponse, status_code=201)
def create_supplier(data: SupplierCreate, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    account = Account(
        name=data.name,
        group_name="Payables",
        account_type="Liabilities",
        opening_balance=data.opening_balance,
        current_balance=data.opening_balance,
        user_id=user_id,
    )
    db.add(account)
    db.flush()

    supplier = Supplier(
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
        opening_balance=data.opening_balance,
        current_balance=data.opening_balance,
        account_id=account.id,
        notes=data.notes,
        user_id=user_id,
    )
    db.add(supplier)
    db.commit()
    db.refresh(supplier)
    return supplier


@router.get("/{supplier_id}", response_model=SupplierResponse)
def get_supplier(supplier_id: int, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    supplier = db.query(Supplier).filter(Supplier.id == supplier_id, Supplier.user_id == user_id).first()
    if not supplier:
        raise HTTPException(status_code=404, detail="Supplier not found")
    return supplier


@router.put("/{supplier_id}", response_model=SupplierResponse)
def update_supplier(supplier_id: int, data: SupplierUpdate, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    supplier = db.query(Supplier).filter(Supplier.id == supplier_id, Supplier.user_id == user_id).first()
    if not supplier:
        raise HTTPException(status_code=404, detail="Supplier not found")

    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(supplier, field, value)

    db.commit()
    db.refresh(supplier)
    return supplier


@router.delete("/{supplier_id}")
def delete_supplier(supplier_id: int, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    supplier = db.query(Supplier).filter(Supplier.id == supplier_id, Supplier.user_id == user_id).first()
    if not supplier:
        raise HTTPException(status_code=404, detail="Supplier not found")
    db.delete(supplier)
    db.commit()
    return {"message": "Supplier deleted successfully"}


@router.get("/{supplier_id}/statement")
def supplier_statement(supplier_id: int, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    supplier = db.query(Supplier).filter(Supplier.id == supplier_id, Supplier.user_id == user_id).first()
    if not supplier:
        raise HTTPException(status_code=404, detail="Supplier not found")

    entries = db.query(AccountingEntry).join(Voucher).filter(
        AccountingEntry.account_id == supplier.account_id,
        Voucher.user_id == user_id,
        Voucher.is_cancelled == False,
    ).order_by(Voucher.date).all()

    balance = supplier.opening_balance
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
        "supplier": {"id": supplier.id, "name": supplier.name},
        "opening_balance": supplier.opening_balance,
        "current_balance": supplier.current_balance,
        "outstanding": supplier.outstanding_amount,
        "statement": statement,
    }
