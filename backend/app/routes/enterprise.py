from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, date, timedelta
from sqlalchemy import func, extract, and_
import json
from app.database import get_db
from app.models.enterprise import (
    Company, Godown, StockGroup, ProductBatch, StockValuation,
    CostCategory, CostCenter, CostCenterAllocation, BillWiseDetail,
    BankTransaction, TDSDeduction, Budget, AuditLog, Cheque,
    PriceLevel, BillOfMaterial, POSSession, GodownStock,
    StockTransfer, GSTReturn,
)
from app.models.inventory import Product, StockMovement
from app.models.accounting import Account, Voucher, AccountingEntry
from app.models.customer import Customer
from app.models.expense import Expense
from app.models.invoice import Invoice
from app.routes.auth import get_current_user
from pydantic import BaseModel, ConfigDict


class CompanyResponse(BaseModel):
    id: int
    name: str
    alias: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    pincode: Optional[str] = None
    country: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    gstin: Optional[str] = None
    pan: Optional[str] = None
    is_active: bool = True

    model_config = ConfigDict(from_attributes=True)


router = APIRouter(prefix="/api/enterprise", tags=["Enterprise"])


def _log_audit(db: Session, user_id: int, action: str, entity_type: str, entity_id: int = None, old_value: str = None, new_value: str = None):
    log = AuditLog(user_id=user_id, action=action, entity_type=entity_type, entity_id=entity_id, old_value=old_value, new_value=new_value)
    db.add(log)


# ==================== COMPANY ====================
@router.post("/companies", response_model=CompanyResponse, status_code=201)
def create_company(data: dict, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    company = Company(name=data["name"], alias=data.get("alias"), address=data.get("address"),
        city=data.get("city"), state=data.get("state"), pincode=data.get("pincode"),
        phone=data.get("phone"), email=data.get("email"), gstin=data.get("gstin"),
        pan=data.get("pan"), user_id=user_id)
    db.add(company); db.commit(); db.refresh(company)
    _log_audit(db, user_id, "CREATE", "Company", company.id)
    db.commit()
    return company


@router.get("/companies")
def list_companies(db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    return db.query(Company).filter(Company.user_id == user_id).order_by(Company.name).all()


@router.get("/companies/{company_id}")
def get_company(company_id: int, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    c = db.query(Company).filter(Company.id == company_id, Company.user_id == user_id).first()
    if not c: raise HTTPException(status_code=404, detail="Company not found")
    return c


@router.put("/companies/{company_id}")
def update_company(company_id: int, data: dict, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    c = db.query(Company).filter(Company.id == company_id, Company.user_id == user_id).first()
    if not c: raise HTTPException(status_code=404, detail="Company not found")
    for k, v in data.items():
        if hasattr(c, k) and k not in ["id", "user_id", "created_at"]:
            setattr(c, k, v)
    db.commit(); db.refresh(c)
    _log_audit(db, user_id, "UPDATE", "Company", company_id, new_value=json.dumps(data))
    db.commit()
    return c


# ==================== GODOWN ====================
@router.post("/godowns")
def create_godown(data: dict, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    g = Godown(name=data["name"], parent_id=data.get("parent_id"), address=data.get("address"),
        city=data.get("city"), state=data.get("state"), phone=data.get("phone"), user_id=user_id)
    db.add(g); db.commit(); db.refresh(g)
    return g


@router.get("/godowns")
def list_godowns(db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    return db.query(Godown).filter(Godown.user_id == user_id).order_by(Godown.name).all()


@router.get("/godowns/tree")
def godown_tree(db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    all_godowns = db.query(Godown).filter(Godown.user_id == user_id).all()

    def build_tree(parent_id=None):
        children = [g for g in all_godowns if g.parent_id == parent_id]
        return [{"id": g.id, "name": g.name, "children": build_tree(g.id)} for g in children]

    return build_tree()


@router.post("/stock-transfers")
def create_stock_transfer(data: dict, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    today = date.today()
    count = db.query(StockTransfer).filter(StockTransfer.user_id == user_id).count() + 1
    transfer_no = f"STN-{today.strftime('%Y%m%d')}-{count:04d}"

    product = db.query(Product).filter(Product.id == data["product_id"], Product.user_id == user_id).first()
    if not product: raise HTTPException(status_code=404, detail="Product not found")

    from_stock = db.query(GodownStock).filter(
        GodownStock.product_id == data["product_id"], GodownStock.godown_id == data["from_godown_id"]
    ).first()
    if not from_stock or from_stock.quantity < data["quantity"]:
        raise HTTPException(status_code=400, detail="Insufficient stock in source godown")

    transfer = StockTransfer(transfer_no=transfer_no, product_id=data["product_id"],
        quantity=data["quantity"], from_godown_id=data["from_godown_id"],
        to_godown_id=data["to_godown_id"], transfer_date=datetime.strptime(data["transfer_date"], "%Y-%m-%d"),
        narration=data.get("narration"), user_id=user_id)
    db.add(transfer)

    from_stock.quantity -= data["quantity"]
    to_stock = db.query(GodownStock).filter(
        GodownStock.product_id == data["product_id"], GodownStock.godown_id == data["to_godown_id"]
    ).first()
    if to_stock:
        to_stock.quantity += data["quantity"]
    else:
        db.add(GodownStock(product_id=data["product_id"], godown_id=data["to_godown_id"], quantity=data["quantity"], user_id=user_id))

    movement = StockMovement(product_id=data["product_id"], quantity=-data["quantity"],
        type="Stock Transfer Out", reference_type="StockTransfer", reference_id=transfer.id,
        narration=f"Transfer to godown {data['to_godown_id']}", user_id=user_id)
    db.add(movement)

    movement2 = StockMovement(product_id=data["product_id"], quantity=data["quantity"],
        type="Stock Transfer In", reference_type="StockTransfer", reference_id=transfer.id,
        narration=f"Transfer from godown {data['from_godown_id']}", user_id=user_id)
    db.add(movement2)

    db.commit(); db.refresh(transfer)
    return transfer


# ==================== STOCK GROUPS ====================
@router.post("/stock-groups")
def create_stock_group(data: dict, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    sg = StockGroup(name=data["name"], parent_id=data.get("parent_id"), user_id=user_id)
    db.add(sg); db.commit(); db.refresh(sg)
    return sg


@router.get("/stock-groups")
def list_stock_groups(db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    return db.query(StockGroup).filter(StockGroup.user_id == user_id).order_by(StockGroup.name).all()


# ==================== BATCH & EXPIRY ====================
@router.post("/batches")
def create_batch(data: dict, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    batch = ProductBatch(product_id=data["product_id"], batch_no=data["batch_no"],
        manufacturing_date=datetime.strptime(data["manufacturing_date"], "%Y-%m-%d").date() if data.get("manufacturing_date") else None,
        expiry_date=datetime.strptime(data["expiry_date"], "%Y-%m-%d").date() if data.get("expiry_date") else None,
        godown_id=data.get("godown_id"), quantity=data.get("quantity", 0),
        purchase_rate=data.get("purchase_rate", 0), selling_rate=data.get("selling_rate", 0),
        mrp=data.get("mrp", 0), user_id=user_id)
    db.add(batch); db.commit(); db.refresh(batch)
    return batch


@router.get("/batches")
def list_batches(product_id: Optional[int] = None, godown_id: Optional[int] = None,
    expiring_soon: Optional[bool] = None, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    query = db.query(ProductBatch).filter(ProductBatch.user_id == user_id)
    if product_id: query = query.filter(ProductBatch.product_id == product_id)
    if godown_id: query = query.filter(ProductBatch.godown_id == godown_id)
    if expiring_soon:
        thirty_days = date.today() + timedelta(days=30)
        query = query.filter(ProductBatch.expiry_date <= thirty_days, ProductBatch.expiry_date >= date.today())
    return query.order_by(ProductBatch.expiry_date).all()


@router.get("/batches/expiring")
def expiring_batches(days: int = 30, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    expiry_date = date.today() + timedelta(days=days)
    batches = db.query(ProductBatch).join(Product).filter(
        ProductBatch.user_id == user_id,
        ProductBatch.expiry_date <= expiry_date,
        ProductBatch.expiry_date >= date.today(),
        ProductBatch.quantity > 0,
    ).all()
    return [{"id": b.id, "product_name": b.product.name if b.product else None, "batch_no": b.batch_no,
        "expiry_date": b.expiry_date.isoformat() if b.expiry_date else None,
        "quantity": b.quantity, "godown": b.godown.name if b.godown else None} for b in batches]


# ==================== COST CENTERS ====================
@router.post("/cost-categories")
def create_cost_category(data: dict, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    cc = CostCategory(name=data["name"], user_id=user_id)
    db.add(cc); db.commit(); db.refresh(cc)
    return cc


@router.get("/cost-categories")
def list_cost_categories(db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    return db.query(CostCategory).filter(CostCategory.user_id == user_id).all()


@router.post("/cost-centers")
def create_cost_center(data: dict, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    cc = CostCenter(name=data["name"], category_id=data.get("category_id"), user_id=user_id)
    db.add(cc); db.commit(); db.refresh(cc)
    return cc


@router.get("/cost-centers")
def list_cost_centers(db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    centers = db.query(CostCenter).filter(CostCenter.user_id == user_id).order_by(CostCenter.name).all()
    return [{"id": c.id, "name": c.name, "category_id": c.category_id,
        "category_name": c.category.name if c.category else None} for c in centers]


# ==================== BILL-WISE ====================
@router.post("/bill-wise")
def create_bill_wise(data: dict, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    bw = BillWiseDetail(voucher_id=data["voucher_id"], bill_type=data["bill_type"],
        bill_name=data.get("bill_name"), due_date=datetime.strptime(data["due_date"], "%Y-%m-%d").date() if data.get("due_date") else None,
        reference_voucher_id=data.get("reference_voucher_id"), amount=data["amount"],
        adjusted_amount=data.get("adjusted_amount", 0), balance_amount=data.get("balance_amount", data["amount"]),
        user_id=user_id)
    db.add(bw); db.commit(); db.refresh(bw)
    return bw


@router.get("/bill-wise/outstanding")
def outstanding_bills(party_account_id: Optional[int] = None, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    query = db.query(BillWiseDetail).filter(BillWiseDetail.user_id == user_id, BillWiseDetail.balance_amount > 0)
    if party_account_id:
        query = query.join(Voucher, BillWiseDetail.voucher_id == Voucher.id).filter(
            AccountingEntry.account_id == party_account_id)
    return query.order_by(BillWiseDetail.due_date).all()


# ==================== BANK RECONCILIATION ====================
@router.post("/bank-transactions")
def create_bank_transaction(data: dict, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    bt = BankTransaction(account_id=data["account_id"],
        transaction_date=datetime.strptime(data["transaction_date"], "%Y-%m-%d").date(),
        transaction_type=data["transaction_type"], amount=data["amount"],
        cheque_no=data.get("cheque_no"), cheque_date=datetime.strptime(data["cheque_date"], "%Y-%m-%d").date() if data.get("cheque_date") else None,
        bank_reference=data.get("bank_reference"), narration=data.get("narration"),
        user_id=user_id)
    db.add(bt); db.commit(); db.refresh(bt)
    return bt


@router.get("/bank-transactions")
def list_bank_transactions(account_id: Optional[int] = None, reconciled: Optional[bool] = None,
    db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    query = db.query(BankTransaction).filter(BankTransaction.user_id == user_id)
    if account_id: query = query.filter(BankTransaction.account_id == account_id)
    if reconciled is not None: query = query.filter(BankTransaction.is_reconciled == reconciled)
    return query.order_by(BankTransaction.transaction_date.desc()).all()


@router.post("/bank-reconciliation/{transaction_id}")
def reconcile_transaction(transaction_id: int, data: dict, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    bt = db.query(BankTransaction).filter(BankTransaction.id == transaction_id, BankTransaction.user_id == user_id).first()
    if not bt: raise HTTPException(status_code=404, detail="Transaction not found")
    bt.is_reconciled = True
    bt.reconciliation_date = datetime.strptime(data.get("reconciliation_date", date.today().isoformat()), "%Y-%m-%d").date()
    bt.voucher_id = data.get("voucher_id")
    db.commit()
    _log_audit(db, user_id, "RECONCILE", "BankTransaction", transaction_id)
    db.commit()
    return bt


# ==================== TDS ====================
@router.post("/tds-deductions")
def create_tds_deduction(data: dict, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    tds = TDSDeduction(voucher_id=data["voucher_id"], section=data["section"],
        nature_of_payment=data.get("nature_of_payment"), party_name=data["party_name"],
        party_pan=data.get("party_pan"), amount=data["amount"],
        tds_rate=data.get("tds_rate", 0), tds_amount=data.get("tds_amount", 0),
        surcharge=data.get("surcharge", 0), cess=data.get("cess", 0),
        total_tds=data.get("total_tds", data.get("tds_amount", 0)),
        transaction_date=datetime.strptime(data["transaction_date"], "%Y-%m-%d").date(),
        due_date=datetime.strptime(data["due_date"], "%Y-%m-%d").date() if data.get("due_date") else None,
        user_id=user_id)
    db.add(tds); db.commit(); db.refresh(tds)
    return tds


@router.get("/tds-deductions")
def list_tds_deductions(section: Optional[str] = None, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    query = db.query(TDSDeduction).filter(TDSDeduction.user_id == user_id)
    if section: query = query.filter(TDSDeduction.section == section)
    return query.order_by(TDSDeduction.transaction_date.desc()).all()


@router.get("/tds-report")
def tds_report(financial_year: str = None, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    year = financial_year or f"{date.today().year}-{date.today().year + 1}"
    deductions = db.query(TDSDeduction).filter(TDSDeduction.user_id == user_id).all()
    total_amount = sum(d.amount for d in deductions)
    total_tds = sum(d.total_tds for d in deductions)
    section_wise = {}
    for d in deductions:
        section_wise[d.section] = section_wise.get(d.section, 0) + d.total_tds
    return {"financial_year": year, "total_amount": total_amount, "total_tds": total_tds,
        "section_wise": section_wise, "deductions_count": len(deductions)}


# ==================== BUDGET ====================
@router.post("/budgets")
def create_budget(data: dict, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    budget = Budget(name=data["name"], financial_year=data["financial_year"],
        account_id=data.get("account_id"), cost_center_id=data.get("cost_center_id"),
        budgeted_amount=data["budgeted_amount"], period=data.get("period", "Yearly"), user_id=user_id)
    db.add(budget); db.commit(); db.refresh(budget)
    return budget


@router.get("/budgets")
def list_budgets(financial_year: Optional[str] = None, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    query = db.query(Budget).filter(Budget.user_id == user_id)
    if financial_year: query = query.filter(Budget.financial_year == financial_year)
    budgets = query.all()

    for b in budgets:
        if b.account_id:
            debit = db.query(func.coalesce(func.sum(AccountingEntry.debit), 0)).join(Voucher).filter(
                AccountingEntry.account_id == b.account_id, Voucher.user_id == user_id,
                Voucher.is_cancelled == False).scalar()
            credit = db.query(func.coalesce(func.sum(AccountingEntry.credit), 0)).join(Voucher).filter(
                AccountingEntry.account_id == b.account_id, Voucher.user_id == user_id,
                Voucher.is_cancelled == False).scalar()
            actual = credit - debit
            b.actual_amount = abs(actual)
            b.variance = b.budgeted_amount - b.actual_amount
            b.variance_percentage = ((b.variance / b.budgeted_amount) * 100) if b.budgeted_amount > 0 else 0
    db.commit()
    return budgets


@router.get("/budgets/variance")
def budget_variance_report(financial_year: Optional[str] = None, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    budgets = db.query(Budget).filter(Budget.user_id == user_id)
    if financial_year: budgets = budgets.filter(Budget.financial_year == financial_year)
    budgets = budgets.all()

    result = []
    for b in budgets:
        over_budget = b.variance < 0
        result.append({"id": b.id, "name": b.name, "budgeted": b.budgeted_amount,
            "actual": b.actual_amount, "variance": b.variance,
            "variance_pct": b.variance_percentage, "over_budget": over_budget})
    return result


# ==================== AUDIT LOGS ====================
@router.get("/audit-logs")
def list_audit_logs(entity_type: Optional[str] = None, action: Optional[str] = None,
    limit: int = 100, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    query = db.query(AuditLog).filter(AuditLog.user_id == user_id)
    if entity_type: query = query.filter(AuditLog.entity_type == entity_type)
    if action: query = query.filter(AuditLog.action == action)
    return query.order_by(AuditLog.created_at.desc()).limit(limit).all()


# ==================== CHEQUE ====================
@router.post("/cheques")
def create_cheque(data: dict, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    chq = Cheque(account_id=data["account_id"], cheque_no=data["cheque_no"],
        cheque_date=datetime.strptime(data["cheque_date"], "%Y-%m-%d").date(),
        party_name=data.get("party_name"), amount=data["amount"],
        bank_name=data.get("bank_name"), branch=data.get("branch"),
        micr_code=data.get("micr_code"), user_id=user_id)
    db.add(chq); db.commit(); db.refresh(chq)
    return chq


@router.get("/cheques")
def list_cheques(status: Optional[str] = None, account_id: Optional[int] = None,
    db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    query = db.query(Cheque).filter(Cheque.user_id == user_id)
    if status: query = query.filter(Cheque.status == status)
    if account_id: query = query.filter(Cheque.account_id == account_id)
    return query.order_by(Cheque.cheque_date.desc()).all()


@router.put("/cheques/{cheque_id}/status")
def update_cheque_status(cheque_id: int, data: dict, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    chq = db.query(Cheque).filter(Cheque.id == cheque_id, Cheque.user_id == user_id).first()
    if not chq: raise HTTPException(status_code=404, detail="Cheque not found")
    chq.status = data["status"]
    if data["status"] == "Deposited":
        chq.deposited_date = datetime.strptime(data.get("date", date.today().isoformat()), "%Y-%m-%d").date()
    elif data["status"] == "Cleared":
        chq.cleared_date = datetime.strptime(data.get("date", date.today().isoformat()), "%Y-%m-%d").date()
    elif data["status"] == "Bounced":
        chq.bounce_date = datetime.strptime(data.get("date", date.today().isoformat()), "%Y-%m-%d").date()
        chq.bounce_reason = data.get("reason")
    db.commit()
    _log_audit(db, user_id, "UPDATE_STATUS", "Cheque", cheque_id, new_value=data["status"])
    db.commit()
    return chq


# ==================== PRICE LEVELS ====================
@router.post("/price-levels")
def create_price_level(data: dict, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    pl = PriceLevel(name=data["name"], product_id=data.get("product_id"),
        customer_id=data.get("customer_id"), price=data.get("price", 0),
        discount_percentage=data.get("discount_percentage", 0), user_id=user_id)
    db.add(pl); db.commit(); db.refresh(pl)
    return pl


@router.get("/price-levels")
def list_price_levels(product_id: Optional[int] = None, customer_id: Optional[int] = None,
    db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    query = db.query(PriceLevel).filter(PriceLevel.user_id == user_id)
    if product_id: query = query.filter(PriceLevel.product_id == product_id)
    if customer_id: query = query.filter(PriceLevel.customer_id == customer_id)
    return query.all()


# ==================== BOM (Bill of Materials) ====================
@router.post("/bom")
def create_bom(data: dict, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    bom = BillOfMaterial(finished_product_id=data["finished_product_id"],
        raw_product_id=data["raw_product_id"], quantity_required=data.get("quantity_required", 1),
        wastage_percentage=data.get("wastage_percentage", 0), user_id=user_id)
    db.add(bom); db.commit(); db.refresh(bom)
    return bom


@router.get("/bom")
def list_bom(finished_product_id: Optional[int] = None, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    query = db.query(BillOfMaterial).filter(BillOfMaterial.user_id == user_id)
    if finished_product_id: query = query.filter(BillOfMaterial.finished_product_id == finished_product_id)
    boms = query.all()
    return [{"id": b.id, "finished_product_id": b.finished_product_id,
        "finished_product_name": b.finished_product.name if b.finished_product else None,
        "raw_product_id": b.raw_product_id,
        "raw_product_name": b.raw_product.name if b.raw_product else None,
        "quantity_required": b.quantity_required, "wastage_pct": b.wastage_percentage} for b in boms]


# ==================== POS ====================
@router.post("/pos/session/open")
def open_pos_session(data: dict, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    today = date.today()
    count = db.query(POSSession).filter(POSSession.user_id == user_id, func.date(POSSession.opened_at) == today).count() + 1
    session_no = f"POS-{today.strftime('%Y%m%d')}-{count:04d}"
    session = POSSession(session_no=session_no, opened_at=datetime.utcnow(),
        opening_balance=data.get("opening_balance", 0), user_id=user_id)
    db.add(session); db.commit(); db.refresh(session)
    return session


@router.post("/pos/session/close/{session_id}")
def close_pos_session(session_id: int, data: dict, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    session = db.query(POSSession).filter(POSSession.id == session_id, POSSession.user_id == user_id).first()
    if not session: raise HTTPException(status_code=404, detail="Session not found")
    session.closed_at = datetime.utcnow()
    session.closing_balance = data.get("closing_balance", 0)
    session.total_cash = data.get("total_cash", 0)
    session.total_card = data.get("total_card", 0)
    session.total_upi = data.get("total_upi", 0)
    session.total_sales = data.get("total_sales", 0)
    session.status = "Closed"
    db.commit()
    return session


@router.get("/pos/sessions")
def list_pos_sessions(db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    return db.query(POSSession).filter(POSSession.user_id == user_id).order_by(POSSession.opened_at.desc()).all()


@router.get("/pos/active-session")
def get_active_pos_session(db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    session = db.query(POSSession).filter(POSSession.user_id == user_id, POSSession.status == "Open").first()
    return session


# ==================== GST RETURNS ====================
@router.post("/gst/generate")
def generate_gst_return(data: dict, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    return_type = data["return_type"]
    period = data["period"]
    financial_year = data["financial_year"]

    month_map = {"Apr": 4, "May": 5, "Jun": 6, "Jul": 7, "Aug": 8, "Sep": 9,
                 "Oct": 10, "Nov": 11, "Dec": 12, "Jan": 1, "Feb": 2, "Mar": 3}

    if return_type == "GSTR-1":
        month_num = month_map.get(period)
        year_parts = financial_year.split("-")
        year = int(year_parts[0]) if month_num >= 4 else int(year_parts[1])

        invoices = db.query(Invoice).filter(
            Invoice.user_id == user_id,
            extract("month", Invoice.invoice_date) == month_num,
            extract("year", Invoice.invoice_date) == year,
        ).all()

        total_taxable = sum(i.taxable_amount for i in invoices)
        total_cgst = sum(i.cgst_amount for i in invoices)
        total_sgst = sum(i.sgst_amount for i in invoices)
        total_igst = sum(i.igst_amount for i in invoices)

        gst_return = GSTReturn(
            return_type=return_type, period=period, financial_year=financial_year,
            total_invoices=len(invoices), total_taxable=total_taxable,
            total_cgst=total_cgst, total_sgst=total_sgst, total_igst=total_igst,
            status="Generated", user_id=user_id)
        db.add(gst_return)
        db.commit()
        db.refresh(gst_return)

        invoice_data = [{"invoice_no": i.invoice_no, "date": i.invoice_date.isoformat(),
            "customer": i.customer.name if i.customer else None,
            "taxable": i.taxable_amount, "cgst": i.cgst_amount, "sgst": i.sgst_amount,
            "igst": i.igst_amount, "total": i.grand_total} for i in invoices]

        return {"return": gst_return, "invoices": invoice_data}

    elif return_type == "GSTR-3B":
        month_num = month_map.get(period)
        year_parts = financial_year.split("-")
        year = int(year_parts[0]) if month_num >= 4 else int(year_parts[1])

        sales = db.query(func.coalesce(func.sum(Invoice.grand_total), 0)).filter(
            Invoice.user_id == user_id,
            extract("month", Invoice.invoice_date) == month_num,
            extract("year", Invoice.invoice_date) == year,
        ).scalar()

        sales_taxable = db.query(func.coalesce(func.sum(Invoice.taxable_amount), 0)).filter(
            Invoice.user_id == user_id,
            extract("month", Invoice.invoice_date) == month_num,
            extract("year", Invoice.invoice_date) == year,
        ).scalar()

        sales_cgst = db.query(func.coalesce(func.sum(Invoice.cgst_amount), 0)).filter(
            Invoice.user_id == user_id,
            extract("month", Invoice.invoice_date) == month_num,
            extract("year", Invoice.invoice_date) == year,
        ).scalar()

        sales_sgst = db.query(func.coalesce(func.sum(Invoice.sgst_amount), 0)).filter(
            Invoice.user_id == user_id,
            extract("month", Invoice.invoice_date) == month_num,
            extract("year", Invoice.invoice_date) == year,
        ).scalar()

        sales_igst = db.query(func.coalesce(func.sum(Invoice.igst_amount), 0)).filter(
            Invoice.user_id == user_id,
            extract("month", Invoice.invoice_date) == month_num,
            extract("year", Invoice.invoice_date) == year,
        ).scalar()

        gst_return = GSTReturn(
            return_type=return_type, period=period, financial_year=financial_year,
            total_invoices=int(sales or 0), total_taxable=sales_taxable,
            total_cgst=sales_cgst, total_sgst=sales_sgst, total_igst=sales_igst,
            status="Generated", user_id=user_id)
        db.add(gst_return)
        db.commit()

        return {
            "return": gst_return,
            "summary": {
                "sales_total": sales, "taxable_value": sales_taxable,
                "cgst": sales_cgst, "sgst": sales_sgst, "igst": sales_igst,
            }
        }

    raise HTTPException(status_code=400, detail="Invalid return type")


@router.get("/gst/returns")
def list_gst_returns(return_type: Optional[str] = None, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    query = db.query(GSTReturn).filter(GSTReturn.user_id == user_id)
    if return_type: query = query.filter(GSTReturn.return_type == return_type)
    return query.order_by(GSTReturn.created_at.desc()).all()


# ==================== ENHANCED REPORTS ====================
@router.get("/reports/stock-valuation")
def stock_valuation_report(godown_id: Optional[int] = None, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    query = db.query(Product).filter(Product.user_id == user_id)
    products = query.all()
    result = []
    total_value = 0
    for p in products:
        if godown_id:
            gs = db.query(GodownStock).filter(GodownStock.product_id == p.id, GodownStock.godown_id == godown_id).first()
            qty = gs.quantity if gs else 0
        else:
            qty = p.current_stock
        value = qty * p.purchase_price
        total_value += value
        result.append({"product_id": p.id, "product_name": p.name, "sku": p.sku,
            "quantity": qty, "rate": p.purchase_price, "value": value})
    return {"items": result, "total_value": total_value}


@router.get("/reports/cost-center/{cost_center_id}")
def cost_center_report(cost_center_id: int, from_date: Optional[str] = None, to_date: Optional[str] = None,
    db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    query = db.query(CostCenterAllocation).filter(
        CostCenterAllocation.cost_center_id == cost_center_id,
        CostCenterAllocation.user_id == user_id)
    if from_date: query = query.join(Voucher).filter(Voucher.date >= datetime.strptime(from_date, "%Y-%m-%d"))
    if to_date: query = query.join(Voucher).filter(Voucher.date <= datetime.strptime(to_date, "%Y-%m-%d"))

    allocations = query.all()
    total = sum(a.amount for a in allocations)
    cc = db.query(CostCenter).filter(CostCenter.id == cost_center_id).first()

    return {"cost_center": cc.name if cc else "Unknown", "total_amount": total,
        "allocations": [{"voucher_no": a.voucher.voucher_no if a.voucher else None,
            "account": a.account.name if a.account else None, "amount": a.amount,
            "percentage": a.percentage} for a in allocations]}


@router.get("/reports/cash-flow")
def cash_flow_report(from_date: str, to_date: str, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    start = datetime.strptime(from_date, "%Y-%m-%d")
    end = datetime.strptime(to_date, "%Y-%m-%d")

    cash_accounts = db.query(Account).filter(
        Account.user_id == user_id, Account.account_type.in_(["Cash", "Bank"])).all()
    cash_ids = [a.id for a in cash_accounts]

    cash_in = db.query(func.coalesce(func.sum(AccountingEntry.debit), 0)).join(Voucher).filter(
        AccountingEntry.account_id.in_(cash_ids), Voucher.user_id == user_id,
        Voucher.date >= start, Voucher.date <= end, Voucher.is_cancelled == False).scalar()

    cash_out = db.query(func.coalesce(func.sum(AccountingEntry.credit), 0)).join(Voucher).filter(
        AccountingEntry.account_id.in_(cash_ids), Voucher.user_id == user_id,
        Voucher.date >= start, Voucher.date <= end, Voucher.is_cancelled == False).scalar()

    opening = sum(a.opening_balance for a in cash_accounts)
    closing = opening + (cash_in or 0) - (cash_out or 0)

    return {"period": {"from": from_date, "to": to_date}, "opening_balance": opening,
        "cash_inflow": cash_in, "cash_outflow": cash_out, "net_flow": (cash_in or 0) - (cash_out or 0),
        "closing_balance": closing}


@router.get("/reports/ratio-analysis")
def ratio_analysis(from_date: str, to_date: str, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    start = datetime.strptime(from_date, "%Y-%m-%d")
    end = datetime.strptime(to_date, "%Y-%m-%d")

    sales = db.query(func.coalesce(func.sum(Invoice.grand_total), 0)).filter(
        Invoice.user_id == user_id, Invoice.invoice_date >= start.date(),
        Invoice.invoice_date <= end.date()).scalar()

    total_assets = db.query(func.coalesce(func.sum(Account.current_balance), 0)).filter(
        Account.user_id == user_id, Account.account_type == "Assets").scalar()

    total_liabilities = db.query(func.coalesce(func.sum(Account.current_balance), 0)).filter(
        Account.user_id == user_id, Account.account_type == "Liabilities").scalar()

    current_assets = db.query(func.coalesce(func.sum(Account.current_balance), 0)).filter(
        Account.user_id == user_id, Account.group_name.in_(["Current Assets", "Cash in Hand", "Bank Accounts"])).scalar()

    current_liabilities = db.query(func.coalesce(func.sum(Account.current_balance), 0)).filter(
        Account.user_id == user_id, Account.group_name == "Current Liabilities").scalar()

    current_ratio = (current_assets / current_liabilities) if current_liabilities and current_liabilities > 0 else 0
    debt_equity = (total_liabilities / (total_assets - total_liabilities)) if (total_assets - total_liabilities) > 0 else 0
    profit_margin = 0

    expenses = db.query(func.coalesce(func.sum(Expense.amount), 0)).filter(
        Expense.user_id == user_id, Expense.expense_date >= start.date(),
        Expense.expense_date <= end.date()).scalar()

    if sales and sales > 0:
        profit_margin = ((sales - expenses) / sales) * 100

    return {"current_ratio": round(current_ratio, 2), "debt_equity_ratio": round(debt_equity, 2),
        "profit_margin_pct": round(profit_margin, 2),
        "total_assets": total_assets, "total_liabilities": total_liabilities,
        "current_assets": current_assets, "current_liabilities": current_liabilities,
        "sales": sales, "expenses": expenses}

