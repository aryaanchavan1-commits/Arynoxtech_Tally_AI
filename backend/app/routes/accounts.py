from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, date
from app.database import get_db
from app.models.accounting import Account, Voucher, AccountingEntry
from app.schemas.accounting import (
    AccountCreate, AccountResponse, VoucherCreate, VoucherResponse,
    TrialBalanceResponse, TrialBalanceItem,
    ProfitLossResponse, ProfitLossItem,
    BalanceSheetResponse, BalanceSheetItem,
)
from app.routes.auth import get_current_user

router = APIRouter(prefix="/api/accounts", tags=["Chart of Accounts"])


@router.get("/", response_model=List[AccountResponse])
def list_accounts(
    group_name: Optional[str] = None,
    search: Optional[str] = None,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user),
):
    query = db.query(Account).filter(Account.user_id == user_id)
    if group_name:
        query = query.filter(Account.group_name == group_name)
    if search:
        query = query.filter(Account.name.ilike(f"%{search}%"))
    return query.order_by(Account.name).all()


@router.post("/", response_model=AccountResponse, status_code=201)
def create_account(data: AccountCreate, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    existing = db.query(Account).filter(
        Account.user_id == user_id,
        Account.name == data.name
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Account already exists")

    account = Account(
        name=data.name,
        group_name=data.group_name,
        account_type=data.account_type,
        opening_balance=data.opening_balance,
        current_balance=data.opening_balance,
        description=data.description,
        user_id=user_id,
    )
    db.add(account)
    db.commit()
    db.refresh(account)
    return account


@router.get("/{account_id}", response_model=AccountResponse)
def get_account(account_id: int, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    account = db.query(Account).filter(Account.id == account_id, Account.user_id == user_id).first()
    if not account:
        raise HTTPException(status_code=404, detail="Account not found")
    return account


@router.put("/{account_id}", response_model=AccountResponse)
def update_account(account_id: int, data: AccountCreate, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    account = db.query(Account).filter(Account.id == account_id, Account.user_id == user_id).first()
    if not account:
        raise HTTPException(status_code=404, detail="Account not found")

    account.name = data.name
    account.group_name = data.group_name
    account.account_type = data.account_type
    account.description = data.description
    db.commit()
    db.refresh(account)
    return account


@router.delete("/{account_id}")
def delete_account(account_id: int, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    account = db.query(Account).filter(Account.id == account_id, Account.user_id == user_id).first()
    if not account:
        raise HTTPException(status_code=404, detail="Account not found")

    entry_count = db.query(AccountingEntry).filter(AccountingEntry.account_id == account_id).count()
    if entry_count > 0:
        raise HTTPException(status_code=400, detail="Cannot delete account with transactions")

    db.delete(account)
    db.commit()
    return {"message": "Account deleted successfully"}


@router.get("/groups/list")
def get_account_groups():
    from app.models.accounting import AccountGroupEnum
    return {"groups": [g.value for g in AccountGroupEnum]}


@router.get("/types/list")
def get_account_types():
    return {
        "types": [
            "Assets", "Liabilities", "Equity",
            "Income", "Expenses", "Bank", "Cash"
        ]
    }
