from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from sqlalchemy import func, extract
from datetime import datetime, date
from app.database import get_db
from app.models.expense import Expense, ExpenseCategory
from app.models.accounting import Account, Voucher, AccountingEntry
from app.schemas.expense import (
    ExpenseCategoryCreate, ExpenseCategoryResponse,
    ExpenseCreate, ExpenseResponse,
)
from app.routes.auth import get_current_user

router = APIRouter(prefix="/api/expenses", tags=["Expenses"])


@router.get("/categories", response_model=List[ExpenseCategoryResponse])
def list_categories(db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    return db.query(ExpenseCategory).filter(ExpenseCategory.user_id == user_id).all()


@router.post("/categories", response_model=ExpenseCategoryResponse, status_code=201)
def create_category(data: ExpenseCategoryCreate, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    cat = ExpenseCategory(name=data.name, description=data.description, user_id=user_id)
    db.add(cat)
    db.commit()
    db.refresh(cat)
    return cat


@router.get("/", response_model=List[ExpenseResponse])
def list_expenses(
    category_id: Optional[int] = None,
    date_from: Optional[str] = None,
    date_to: Optional[str] = None,
    limit: int = 100,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user),
):
    query = db.query(Expense).filter(Expense.user_id == user_id)
    if category_id:
        query = query.filter(Expense.category_id == category_id)
    if date_from:
        query = query.filter(Expense.expense_date >= datetime.strptime(date_from, "%Y-%m-%d").date())
    if date_to:
        query = query.filter(Expense.expense_date <= datetime.strptime(date_to, "%Y-%m-%d").date())

    expenses = query.order_by(Expense.expense_date.desc()).limit(limit).all()
    return [
        ExpenseResponse(
            id=e.id, category_id=e.category_id,
            category_name=e.category.name if e.category else None,
            amount=e.amount, expense_date=e.expense_date,
            payment_mode=e.payment_mode, reference_no=e.reference_no,
            description=e.description, is_recurring=e.is_recurring,
        )
        for e in expenses
    ]


@router.post("/", response_model=ExpenseResponse, status_code=201)
def create_expense(data: ExpenseCreate, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    exp_date = datetime.strptime(data.expense_date, "%Y-%m-%d").date()
    expense = Expense(
        category_id=data.category_id,
        amount=data.amount,
        expense_date=exp_date,
        payment_mode=data.payment_mode,
        reference_no=data.reference_no,
        description=data.description,
        is_recurring=data.is_recurring,
        recurring_frequency=data.recurring_frequency,
        recurring_end_date=datetime.strptime(data.recurring_end_date, "%Y-%m-%d").date() if data.recurring_end_date else None,
        user_id=user_id,
    )
    db.add(expense)
    db.commit()
    db.refresh(expense)

    exp_category = db.query(ExpenseCategory).filter(ExpenseCategory.id == data.category_id).first()

    from app.models.accounting import Voucher, AccountingEntry, Account

    voucher = Voucher(
        voucher_no=f"EXP-{datetime.now().strftime('%Y%m%d')}-{expense.id:04d}",
        voucher_type="Payment",
        date=datetime.combine(exp_date, datetime.min.time()),
        narration=f"Expense: {exp_category.name if exp_category else 'N/A'}",
        total_amount=data.amount,
        user_id=user_id,
    )
    db.add(voucher)
    db.flush()

    expense_account_name = f"{exp_category.name if exp_category else 'Expenses'}"
    expense_account = db.query(Account).filter(
        Account.name == expense_account_name, Account.user_id == user_id
    ).first()
    if not expense_account:
        expense_account = Account(
            name=expense_account_name, group_name="Indirect Expenses",
            account_type="Expenses", user_id=user_id,
        )
        db.add(expense_account)
        db.flush()

    cash_account = db.query(Account).filter(
        Account.name == "Cash", Account.user_id == user_id
    ).first()
    if not cash_account:
        cash_account = Account(
            name="Cash", group_name="Cash in Hand",
            account_type="Cash", user_id=user_id,
        )
        db.add(cash_account)
        db.flush()

    entry1 = AccountingEntry(voucher_id=voucher.id, account_id=expense_account.id, debit=data.amount, particular=expense_account_name)
    entry2 = AccountingEntry(voucher_id=voucher.id, account_id=cash_account.id, credit=data.amount, particular="By Cash")
    db.add(entry1)
    db.add(entry2)
    db.commit()
    db.refresh(expense)

    return ExpenseResponse(
        id=expense.id, category_id=expense.category_id,
        category_name=exp_category.name if exp_category else None,
        amount=expense.amount, expense_date=expense.expense_date,
        payment_mode=expense.payment_mode, reference_no=expense.reference_no,
        description=expense.description, is_recurring=expense.is_recurring,
    )


@router.delete("/{expense_id}")
def delete_expense(expense_id: int, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    expense = db.query(Expense).filter(Expense.id == expense_id, Expense.user_id == user_id).first()
    if not expense:
        raise HTTPException(status_code=404, detail="Expense not found")

    if expense.voucher_id:
        db.query(AccountingEntry).filter(AccountingEntry.voucher_id == expense.voucher_id).delete()
        db.query(Voucher).filter(Voucher.id == expense.voucher_id).delete()

    db.delete(expense)
    db.commit()
    return {"message": "Expense deleted"}


@router.get("/report")
def expense_report(
    month: Optional[int] = None,
    year: Optional[int] = None,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user),
):
    today = date.today()
    month = month or today.month
    year = year or today.year

    expenses = db.query(Expense).filter(
        Expense.user_id == user_id,
        extract("month", Expense.expense_date) == month,
        extract("year", Expense.expense_date) == year,
    ).all()

    total = sum(e.amount for e in expenses)
    category_wise = {}
    for e in expenses:
        cat_name = e.category.name if e.category else "Uncategorized"
        category_wise[cat_name] = category_wise.get(cat_name, 0) + e.amount

    return {
        "month": month,
        "year": year,
        "total_expenses": total,
        "category_wise": category_wise,
        "expenses": [
            {
                "id": e.id,
                "category": e.category.name if e.category else "Uncategorized",
                "amount": e.amount,
                "date": e.expense_date.isoformat(),
                "description": e.description,
            }
            for e in expenses
        ],
    }
