from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import Optional
from datetime import datetime, date, timezone
from app.database import get_db
from app.models.accounting import Account, Voucher, AccountingEntry
from app.schemas.accounting import (
    TrialBalanceResponse, TrialBalanceItem,
    ProfitLossResponse, ProfitLossItem,
    BalanceSheetResponse, BalanceSheetItem,
)
from app.routes.auth import get_current_user

router = APIRouter(prefix="/api/reports", tags=["Reports"])


@router.get("/trial-balance", response_model=TrialBalanceResponse)
def trial_balance(
    as_on_date: Optional[str] = None,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user),
):
    target_date = datetime.strptime(as_on_date, "%Y-%m-%d") if as_on_date else datetime.now(timezone.utc)

    accounts = db.query(Account).filter(Account.user_id == user_id).all()
    items = []
    total_debit = 0
    total_credit = 0

    for account in accounts:
        debit_total = db.query(func.coalesce(func.sum(AccountingEntry.debit), 0)).join(
            Voucher
        ).filter(
            AccountingEntry.account_id == account.id,
            Voucher.user_id == user_id,
            Voucher.date <= target_date,
            Voucher.is_cancelled == False,
        ).scalar()

        credit_total = db.query(func.coalesce(func.sum(AccountingEntry.credit), 0)).join(
            Voucher
        ).filter(
            AccountingEntry.account_id == account.id,
            Voucher.user_id == user_id,
            Voucher.date <= target_date,
            Voucher.is_cancelled == False,
        ).scalar()

        closing = account.opening_balance + credit_total - debit_total

        if closing != 0:
            item_debit = abs(closing) if closing < 0 else 0
            item_credit = closing if closing > 0 else 0

            items.append(TrialBalanceItem(
                account_id=account.id,
                account_name=account.name,
                group_name=account.group_name,
                opening_balance=account.opening_balance,
                debit=item_debit,
                credit=item_credit,
                closing_balance=closing,
            ))
            total_debit += item_debit
            total_credit += item_credit

    return TrialBalanceResponse(items=items, total_debit=total_debit, total_credit=total_credit)


@router.get("/profit-loss", response_model=ProfitLossResponse)
def profit_loss(
    from_date: str,
    to_date: str,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user),
):
    start_date = datetime.strptime(from_date, "%Y-%m-%d")
    end_date = datetime.strptime(to_date, "%Y-%m-%d")

    income_accounts = db.query(Account).filter(
        Account.user_id == user_id,
        Account.account_type.in_(["Income", "Revenue"]),
    ).all()

    expense_accounts = db.query(Account).filter(
        Account.user_id == user_id,
        Account.account_type.in_(["Expenses", "Cost of Goods Sold"]),
    ).all()

    income_items = []
    total_income = 0
    for acc in income_accounts:
        amount = db.query(func.coalesce(func.sum(AccountingEntry.credit), 0)).join(
            Voucher
        ).filter(
            AccountingEntry.account_id == acc.id,
            Voucher.user_id == user_id,
            Voucher.date >= start_date,
            Voucher.date <= end_date,
            Voucher.is_cancelled == False,
        ).scalar()
        amount -= db.query(func.coalesce(func.sum(AccountingEntry.debit), 0)).join(
            Voucher
        ).filter(
            AccountingEntry.account_id == acc.id,
            Voucher.user_id == user_id,
            Voucher.date >= start_date,
            Voucher.date <= end_date,
            Voucher.is_cancelled == False,
        ).scalar()
        if amount != 0:
            income_items.append(ProfitLossItem(
                account_id=acc.id, account_name=acc.name, group_name=acc.group_name, amount=amount
            ))
            total_income += amount

    expense_items = []
    total_expenses = 0
    for acc in expense_accounts:
        amount = db.query(func.coalesce(func.sum(AccountingEntry.debit), 0)).join(
            Voucher
        ).filter(
            AccountingEntry.account_id == acc.id,
            Voucher.user_id == user_id,
            Voucher.date >= start_date,
            Voucher.date <= end_date,
            Voucher.is_cancelled == False,
        ).scalar()
        amount -= db.query(func.coalesce(func.sum(AccountingEntry.credit), 0)).join(
            Voucher
        ).filter(
            AccountingEntry.account_id == acc.id,
            Voucher.user_id == user_id,
            Voucher.date >= start_date,
            Voucher.date <= end_date,
            Voucher.is_cancelled == False,
        ).scalar()
        if amount != 0:
            expense_items.append(ProfitLossItem(
                account_id=acc.id, account_name=acc.name, group_name=acc.group_name, amount=amount
            ))
            total_expenses += amount

    return ProfitLossResponse(
        income_items=income_items,
        expense_items=expense_items,
        total_income=total_income,
        total_expenses=total_expenses,
        net_profit=total_income - total_expenses,
    )


@router.get("/balance-sheet", response_model=BalanceSheetResponse)
def balance_sheet(
    as_on_date: Optional[str] = None,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user),
):
    target_date = datetime.strptime(as_on_date, "%Y-%m-%d") if as_on_date else datetime.now(timezone.utc)

    asset_accounts = db.query(Account).filter(
        Account.user_id == user_id,
        Account.account_type.in_(["Assets", "Bank", "Cash"]),
    ).all()

    liability_accounts = db.query(Account).filter(
        Account.user_id == user_id,
        Account.account_type == "Liabilities",
    ).all()

    equity_accounts = db.query(Account).filter(
        Account.user_id == user_id,
        Account.account_type == "Equity",
    ).all()

    def calc_balance(account):
        debit_total = db.query(func.coalesce(func.sum(AccountingEntry.debit), 0)).join(
            Voucher
        ).filter(
            AccountingEntry.account_id == account.id,
            Voucher.user_id == user_id,
            Voucher.date <= target_date,
            Voucher.is_cancelled == False,
        ).scalar()
        credit_total = db.query(func.coalesce(func.sum(AccountingEntry.credit), 0)).join(
            Voucher
        ).filter(
            AccountingEntry.account_id == account.id,
            Voucher.user_id == user_id,
            Voucher.date <= target_date,
            Voucher.is_cancelled == False,
        ).scalar()
        return account.opening_balance + credit_total - debit_total

    assets = []
    total_assets = 0
    for acc in asset_accounts:
        bal = calc_balance(acc)
        if bal != 0:
            amt = abs(bal)
            assets.append(BalanceSheetItem(
                account_id=acc.id, account_name=acc.name, group_name=acc.group_name, amount=amt
            ))
            total_assets += amt

    liabilities = []
    total_liabilities = 0
    for acc in liability_accounts:
        bal = calc_balance(acc)
        if bal != 0:
            amt = abs(bal)
            liabilities.append(BalanceSheetItem(
                account_id=acc.id, account_name=acc.name, group_name=acc.group_name, amount=amt
            ))
            total_liabilities += amt

    equity = []
    total_equity = 0
    for acc in equity_accounts:
        bal = calc_balance(acc)
        if bal != 0:
            amt = abs(bal)
            equity.append(BalanceSheetItem(
                account_id=acc.id, account_name=acc.name, group_name=acc.group_name, amount=amt
            ))
            total_equity += amt

    return BalanceSheetResponse(
        assets=assets, liabilities=liabilities, equity=equity,
        total_assets=total_assets, total_liabilities=total_liabilities, total_equity=total_equity,
    )


@router.get("/day-book")
def day_book(
    date: str,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user),
):
    target_date = datetime.strptime(date, "%Y-%m-%d")
    vouchers = db.query(Voucher).filter(
        Voucher.user_id == user_id,
        func.date(Voucher.date) == target_date.date(),
        Voucher.is_cancelled == False,
    ).order_by(Voucher.created_at).all()

    return [
        {
            "voucher_no": v.voucher_no,
            "voucher_type": v.voucher_type,
            "narration": v.narration,
            "total_amount": v.total_amount,
            "created_at": v.created_at.isoformat() if v.created_at else None,
            "entries": [
                {
                    "account_id": e.account_id,
                    "account_name": e.account.name if e.account else None,
                    "debit": e.debit,
                    "credit": e.credit,
                    "particular": e.particular,
                }
                for e in v.entries
            ],
        }
        for v in vouchers
    ]


@router.get("/general-ledger/{account_id}")
def general_ledger(
    account_id: int,
    from_date: Optional[str] = None,
    to_date: Optional[str] = None,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user),
):
    account = db.query(Account).filter(Account.id == account_id, Account.user_id == user_id).first()
    if not account:
        raise HTTPException(status_code=404, detail="Account not found")

    query = db.query(AccountingEntry).join(Voucher).filter(
        AccountingEntry.account_id == account_id,
        Voucher.user_id == user_id,
        Voucher.is_cancelled == False,
    )
    if from_date:
        query = query.filter(Voucher.date >= datetime.strptime(from_date, "%Y-%m-%d"))
    if to_date:
        query = query.filter(Voucher.date <= datetime.strptime(to_date, "%Y-%m-%d"))

    entries = query.order_by(Voucher.date).all()

    running_balance = account.opening_balance
    result = []
    for entry in entries:
        if entry.debit > 0:
            running_balance -= entry.debit
        if entry.credit > 0:
            running_balance += entry.credit
        result.append({
            "date": entry.voucher.date.isoformat() if entry.voucher.date else None,
            "voucher_no": entry.voucher.voucher_no,
            "voucher_type": entry.voucher.voucher_type,
            "particular": entry.particular,
            "debit": entry.debit,
            "credit": entry.credit,
            "balance": running_balance,
        })

    return {
        "account": {"id": account.id, "name": account.name, "group_name": account.group_name},
        "opening_balance": account.opening_balance,
        "closing_balance": running_balance,
        "entries": result,
    }


