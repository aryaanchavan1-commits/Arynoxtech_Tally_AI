from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func, extract
from datetime import datetime, date, timedelta
from app.database import get_db
from app.models.accounting import Account, Voucher, AccountingEntry
from app.models.invoice import Invoice
from app.models.customer import Customer
from app.models.supplier import Supplier
from app.models.inventory import Product
from app.models.expense import Expense
from app.schemas.dashboard import DashboardSummary, RevenueChartData, DashboardData
from app.routes.auth import get_current_user

router = APIRouter(prefix="/api/dashboard", tags=["Dashboard"])


@router.get("/summary")
def get_dashboard_summary(db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    today = date.today()
    first_day = today.replace(day=1)

    revenue = db.query(func.coalesce(func.sum(Invoice.grand_total), 0)).filter(
        Invoice.user_id == user_id,
        Invoice.invoice_date >= first_day,
    ).scalar()

    expenses = db.query(func.coalesce(func.sum(Expense.amount), 0)).filter(
        Expense.user_id == user_id,
        Expense.expense_date >= first_day,
    ).scalar()

    cash_accounts = db.query(Account).filter(
        Account.user_id == user_id,
        Account.account_type.in_(["Cash", "Bank"]),
    ).all()
    cash_position = sum(a.current_balance for a in cash_accounts)

    receivables = db.query(func.coalesce(func.sum(Customer.outstanding_amount), 0)).filter(
        Customer.user_id == user_id,
    ).scalar()

    payables = db.query(func.coalesce(func.sum(Supplier.outstanding_amount), 0)).filter(
        Supplier.user_id == user_id,
    ).scalar()

    customers = db.query(func.count(Customer.id)).filter(Customer.user_id == user_id).scalar()
    suppliers = db.query(func.count(Supplier.id)).filter(Supplier.user_id == user_id).scalar()
    products = db.query(func.count(Product.id)).filter(Product.user_id == user_id).scalar()
    low_stock = db.query(func.count(Product.id)).filter(
        Product.user_id == user_id,
        Product.current_stock <= Product.reorder_level,
    ).scalar()

    total_invoices = db.query(func.count(Invoice.id)).filter(Invoice.user_id == user_id).scalar()
    pending = db.query(func.count(Invoice.id)).filter(
        Invoice.user_id == user_id, Invoice.status != "Paid"
    ).scalar()

    return DashboardSummary(
        total_revenue=revenue,
        total_expenses=expenses,
        net_profit=revenue - expenses,
        cash_position=cash_position,
        total_receivables=receivables,
        total_payables=payables,
        total_customers=customers,
        total_suppliers=suppliers,
        total_products=products,
        low_stock_count=low_stock,
        total_invoices=total_invoices,
        pending_invoices=pending,
    )


@router.get("/chart")
def get_chart_data(db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    today = date.today()
    labels = []
    revenue_values = []
    expense_values = []

    for i in range(5, -1, -1):
        month = today.month - i
        year = today.year
        if month <= 0:
            month += 12
            year -= 1

        labels.append(datetime(year, month, 1).strftime("%b %y"))

        monthly_revenue = db.query(func.coalesce(func.sum(Invoice.grand_total), 0)).filter(
            Invoice.user_id == user_id,
            extract("month", Invoice.invoice_date) == month,
            extract("year", Invoice.invoice_date) == year,
        ).scalar()
        revenue_values.append(float(monthly_revenue))

        monthly_expense = db.query(func.coalesce(func.sum(Expense.amount), 0)).filter(
            Expense.user_id == user_id,
            extract("month", Expense.expense_date) == month,
            extract("year", Expense.expense_date) == year,
        ).scalar()
        expense_values.append(float(monthly_expense))

    return {
        "labels": labels,
        "revenue": revenue_values,
        "expenses": expense_values,
    }


@router.get("/top-customers")
def get_top_customers(limit: int = 5, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    customers = db.query(Customer).filter(Customer.user_id == user_id).order_by(
        Customer.outstanding_amount.desc()
    ).limit(limit).all()

    return [
        {"id": c.id, "name": c.name, "outstanding": c.outstanding_amount, "phone": c.mobile}
        for c in customers
    ]


@router.get("/top-products")
def get_top_products(limit: int = 5, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    products = db.query(Product).filter(Product.user_id == user_id).order_by(
        Product.current_stock.desc()
    ).limit(limit).all()

    return [
        {"id": p.id, "name": p.name, "stock": p.current_stock, "price": p.selling_price}
        for p in products
    ]
