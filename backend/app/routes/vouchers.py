from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, date
from app.database import get_db
from app.models.accounting import Account, Voucher, AccountingEntry
from app.schemas.accounting import VoucherCreate, VoucherResponse
from app.routes.auth import get_current_user

router = APIRouter(prefix="/api/vouchers", tags=["Vouchers"])


def generate_voucher_no(db: Session, voucher_type: str, user_id: int) -> str:
    prefix = {
        "Payment": "PMT", "Receipt": "RCT", "Sales": "SAL",
        "Purchase": "PUR", "Contra": "CTR", "Journal": "JRN",
        "Debit Note": "DBN", "Credit Note": "CRN"
    }.get(voucher_type, "VCH")

    today = date.today()
    count = db.query(Voucher).filter(
        Voucher.user_id == user_id,
        Voucher.voucher_type == voucher_type,
    ).count() + 1

    return f"{prefix}-{today.strftime('%Y%m%d')}-{count:04d}"


@router.get("/", response_model=List[VoucherResponse])
def list_vouchers(
    voucher_type: Optional[str] = None,
    date_from: Optional[str] = None,
    date_to: Optional[str] = None,
    limit: int = 100,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user),
):
    query = db.query(Voucher).filter(Voucher.user_id == user_id)
    if voucher_type:
        query = query.filter(Voucher.voucher_type == voucher_type)
    if date_from:
        query = query.filter(Voucher.date >= datetime.strptime(date_from, "%Y-%m-%d"))
    if date_to:
        query = query.filter(Voucher.date <= datetime.strptime(date_to, "%Y-%m-%d"))
    return query.order_by(Voucher.date.desc()).limit(limit).all()


@router.post("/", response_model=VoucherResponse, status_code=201)
def create_voucher(data: VoucherCreate, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    total_debit = sum(e.debit for e in data.entries)
    total_credit = sum(e.credit for e in data.entries)

    if abs(total_debit - total_credit) > 0.01:
        raise HTTPException(status_code=400, detail="Debit and credit totals must match")

    voucher_no = generate_voucher_no(db, data.voucher_type, user_id)
    voucher_date = datetime.strptime(data.date, "%Y-%m-%d")

    voucher = Voucher(
        voucher_no=voucher_no,
        voucher_type=data.voucher_type,
        date=voucher_date,
        narration=data.narration,
        reference_no=data.reference_no,
        total_amount=total_debit,
        user_id=user_id,
    )
    db.add(voucher)
    db.flush()

    for entry_data in data.entries:
        account = db.query(Account).filter(
            Account.id == entry_data.account_id,
            Account.user_id == user_id
        ).first()
        if not account:
            raise HTTPException(status_code=404, detail=f"Account {entry_data.account_id} not found")

        entry = AccountingEntry(
            voucher_id=voucher.id,
            account_id=entry_data.account_id,
            debit=entry_data.debit,
            credit=entry_data.credit,
            particular=entry_data.particular,
        )
        db.add(entry)

        if entry_data.debit > 0:
            account.current_balance -= entry_data.debit
        if entry_data.credit > 0:
            account.current_balance += entry_data.credit

    db.commit()
    db.refresh(voucher)
    return voucher


@router.get("/{voucher_id}", response_model=VoucherResponse)
def get_voucher(voucher_id: int, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    voucher = db.query(Voucher).filter(Voucher.id == voucher_id, Voucher.user_id == user_id).first()
    if not voucher:
        raise HTTPException(status_code=404, detail="Voucher not found")
    return voucher


@router.delete("/{voucher_id}")
def delete_voucher(voucher_id: int, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    voucher = db.query(Voucher).filter(Voucher.id == voucher_id, Voucher.user_id == user_id).first()
    if not voucher:
        raise HTTPException(status_code=404, detail="Voucher not found")

    for entry in voucher.entries:
        account = db.query(Account).filter(Account.id == entry.account_id).first()
        if account:
            if entry.debit > 0:
                account.current_balance += entry.debit
            if entry.credit > 0:
                account.current_balance -= entry.credit

    db.delete(voucher)
    db.commit()
    return {"message": "Voucher deleted successfully"}


@router.get("/types/list")
def get_voucher_types():
    from app.models.accounting import VoucherTypeEnum
    return {"types": [v.value for v in VoucherTypeEnum]}
