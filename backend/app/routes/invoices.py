from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session, joinedload
from typing import List, Optional
from sqlalchemy import func
from datetime import datetime, date
from app.database import get_db
from app.models.invoice import Invoice, InvoiceItem
from app.models.inventory import Product, StockMovement
from app.models.customer import Customer
from app.models.supplier import Supplier
from app.models.accounting import Account, Voucher, AccountingEntry
from app.schemas.invoice import InvoiceCreate, InvoiceResponse, InvoiceItemResponse, InvoiceReport
from app.routes.auth import get_current_user
from app.routes.vouchers import generate_voucher_no

router = APIRouter(prefix="/api/invoices", tags=["Invoices"])


INDIAN_STATES = {
    "AP": "Andhra Pradesh", "AR": "Arunachal Pradesh", "AS": "Assam", "BR": "Bihar",
    "CG": "Chhattisgarh", "GA": "Goa", "GJ": "Gujarat", "HR": "Haryana",
    "HP": "Himachal Pradesh", "JH": "Jharkhand", "KA": "Karnataka", "KL": "Kerala",
    "MP": "Madhya Pradesh", "MH": "Maharashtra", "MN": "Manipur", "ML": "Meghalaya",
    "MZ": "Mizoram", "NL": "Nagaland", "OD": "Odisha", "PB": "Punjab",
    "RJ": "Rajasthan", "SK": "Sikkim", "TN": "Tamil Nadu", "TS": "Telangana",
    "TR": "Tripura", "UP": "Uttar Pradesh", "UK": "Uttarakhand", "WB": "West Bengal",
    "AN": "Andaman & Nicobar", "CH": "Chandigarh", "DN": "Dadra & Nagar Haveli",
    "DD": "Daman & Diu", "DL": "Delhi", "JK": "Jammu & Kashmir", "LA": "Ladakh",
    "LD": "Lakshadweep", "PY": "Puducherry",
}


def number_to_words(n: float) -> str:
    if n == 0:
        return "Zero Rupees Only"
    num = int(round(n))
    ones = ["", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine",
            "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen",
            "Seventeen", "Eighteen", "Nineteen"]
    tens = ["", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"]
    def _convert(n):
        if n < 20:
            return ones[n]
        if n < 100:
            return tens[n // 10] + (" " + ones[n % 10] if n % 10 else "")
        if n < 1000:
            return ones[n // 100] + " Hundred" + (" " + _convert(n % 100) if n % 100 else "")
        if n < 100000:
            return _convert(n // 1000) + " Thousand" + (" " + _convert(n % 1000) if n % 1000 else "")
        if n < 10000000:
            return _convert(n // 100000) + " Lakh" + (" " + _convert(n % 100000) if n % 100000 else "")
        return _convert(n // 10000000) + " Crore" + (" " + _convert(n % 10000000) if n % 10000000 else "")
    return _convert(num) + " Rupees Only"


def to_invoice_response(invoice: Invoice) -> InvoiceResponse:
    customer = invoice.customer if hasattr(invoice, "customer") else None
    supplier = invoice.supplier if hasattr(invoice, "supplier") else None
    items = invoice.items if hasattr(invoice, "items") else []
    return InvoiceResponse(
        id=invoice.id,
        invoice_no=invoice.invoice_no,
        invoice_type=invoice.invoice_type,
        invoice_date=invoice.invoice_date,
        due_date=invoice.due_date,
        customer_id=invoice.customer_id,
        customer_name=customer.name if customer else None,
        customer_gstin=customer.gstin if customer else None,
        supplier_id=invoice.supplier_id,
        supplier_name=supplier.name if supplier else None,
        supplier_gstin=supplier.gstin if supplier else None,
        irn=invoice.irn,
        ack_no=invoice.ack_no,
        ack_date=invoice.ack_date,
        place_of_supply=invoice.place_of_supply,
        reverse_charge=invoice.reverse_charge or False,
        ecommerce_gstin=invoice.ecommerce_gstin,
        ref_invoice_no=invoice.ref_invoice_no,
        ref_invoice_date=invoice.ref_invoice_date,
        doc_type=invoice.doc_type or "INV",
        subtotal=invoice.subtotal,
        discount_amount=invoice.discount_amount,
        taxable_amount=invoice.taxable_amount,
        cgst_amount=invoice.cgst_amount,
        sgst_amount=invoice.sgst_amount,
        igst_amount=invoice.igst_amount,
        total_tax=invoice.total_tax,
        cess_amount=invoice.cess_amount or 0,
        shipping_charge=invoice.shipping_charge,
        round_off=invoice.round_off or 0,
        grand_total=invoice.grand_total,
        grand_total_words=invoice.grand_total_words,
        paid_amount=invoice.paid_amount,
        balance_amount=invoice.balance_amount,
        status=invoice.status,
        items=[InvoiceItemResponse.model_validate(it) for it in items],
    )


def generate_invoice_no(db: Session, user_id: int) -> str:
    prefix = f"INV-{datetime.now().strftime('%Y%m')}-"
    result = db.query(func.max(Invoice.invoice_no)).filter(
        Invoice.invoice_no.like(f"{prefix}%"),
        Invoice.user_id == user_id
    ).scalar()
    if result:
        num = int(result.split("-")[-1]) + 1
    else:
        num = 1
    return f"{prefix}{num:04d}"


@router.get("/", response_model=List[InvoiceResponse])
def list_invoices(
    status: Optional[str] = None,
    invoice_type: Optional[str] = None,
    date_from: Optional[str] = None,
    date_to: Optional[str] = None,
    limit: int = 100,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user),
):
    query = db.query(Invoice).options(
        joinedload(Invoice.customer), joinedload(Invoice.supplier), joinedload(Invoice.items)
    ).filter(Invoice.user_id == user_id)
    if status:
        query = query.filter(Invoice.status == status)
    if invoice_type:
        query = query.filter(Invoice.invoice_type == invoice_type)
    if date_from:
        query = query.filter(Invoice.invoice_date >= datetime.strptime(date_from, "%Y-%m-%d").date())
    if date_to:
        query = query.filter(Invoice.invoice_date <= datetime.strptime(date_to, "%Y-%m-%d").date())
    invoices = query.order_by(Invoice.invoice_date.desc()).limit(limit).all()
    return [to_invoice_response(inv) for inv in invoices]


@router.post("/", response_model=InvoiceResponse, status_code=201)
def create_invoice(data: InvoiceCreate, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    invoice_no = generate_invoice_no(db, user_id)
    inv_date = datetime.strptime(data.invoice_date, "%Y-%m-%d").date()
    due = datetime.strptime(data.due_date, "%Y-%m-%d").date() if data.due_date else None

    subtotal = 0
    total_cgst = 0
    total_sgst = 0
    total_igst = 0
    total_cess = 0

    items_data = []
    for item_data in data.items:
        rate = item_data.rate
        qty = item_data.quantity
        discount_amt = (rate * qty * item_data.discount_percent) / 100 if item_data.discount_percent > 0 else 0
        taxable = (rate * qty) - discount_amt

        cgst_amt = (taxable * item_data.cgst_rate) / 100
        sgst_amt = (taxable * item_data.sgst_rate) / 100
        igst_amt = (taxable * item_data.igst_rate) / 100
        cess_amt = (taxable * item_data.cess_rate) / 100
        total_item = taxable + cgst_amt + sgst_amt + igst_amt + cess_amt

        subtotal += rate * qty
        total_cgst += cgst_amt
        total_sgst += sgst_amt
        total_igst += igst_amt
        total_cess += cess_amt

        items_data.append({
            "product_id": item_data.product_id,
            "hsn_sac": item_data.hsn_sac,
            "description": item_data.description or "",
            "quantity": qty,
            "unit": item_data.unit,
            "rate": rate,
            "discount_percent": item_data.discount_percent,
            "discount_amount": discount_amt,
            "taxable_value": taxable,
            "cgst_rate": item_data.cgst_rate,
            "sgst_rate": item_data.sgst_rate,
            "igst_rate": item_data.igst_rate,
            "cgst_amount": cgst_amt,
            "sgst_amount": sgst_amt,
            "igst_amount": igst_amt,
            "cess_rate": item_data.cess_rate,
            "cess_amount": cess_amt,
            "total": total_item,
        })

    discount_amount = 0
    if data.discount_value > 0:
        if data.discount_type == "percentage":
            discount_amount = (subtotal * data.discount_value) / 100
        else:
            discount_amount = data.discount_value

    taxable_amount = subtotal - discount_amount
    total_tax = total_cgst + total_sgst + total_igst
    grand_total = taxable_amount + total_tax + total_cess + data.shipping_charge
    round_off = round(grand_total) - grand_total
    grand_total = round(grand_total)
    grand_total_words = number_to_words(grand_total)

    customer = None
    if data.customer_id:
        customer = db.query(Customer).filter(Customer.id == data.customer_id).first()
    supplier = None
    if data.supplier_id:
        supplier = db.query(Supplier).filter(Supplier.id == data.supplier_id).first()

    place_of_supply = data.place_of_supply
    if not place_of_supply and customer:
        place_of_supply = customer.state

    invoice = Invoice(
        invoice_no=invoice_no,
        invoice_type=data.invoice_type,
        invoice_date=inv_date,
        due_date=due,
        customer_id=data.customer_id,
        supplier_id=data.supplier_id,
        place_of_supply=place_of_supply,
        reverse_charge=data.reverse_charge,
        ecommerce_gstin=data.ecommerce_gstin,
        ref_invoice_no=data.ref_invoice_no,
        ref_invoice_date=datetime.strptime(data.ref_invoice_date, "%Y-%m-%d").date() if data.ref_invoice_date else None,
        doc_type=data.doc_type,
        subtotal=subtotal,
        discount_type=data.discount_type,
        discount_value=data.discount_value,
        discount_amount=discount_amount,
        taxable_amount=taxable_amount,
        tax_type=data.tax_type,
        cgst_rate=data.items[0].cgst_rate if data.items else 0,
        sgst_rate=data.items[0].sgst_rate if data.items else 0,
        igst_rate=data.items[0].igst_rate if data.items else 0,
        cgst_amount=total_cgst,
        sgst_amount=total_sgst,
        igst_amount=total_igst,
        total_tax=total_tax,
        cess_amount=total_cess,
        shipping_charge=data.shipping_charge,
        round_off=round_off,
        grand_total=grand_total,
        grand_total_words=grand_total_words,
        paid_amount=0,
        balance_amount=grand_total,
        status="Unpaid",
        terms_conditions=data.terms_conditions,
        notes=data.notes,
        user_id=user_id,
    )
    db.add(invoice)
    db.flush()

    for item in items_data:
        invoice_item = InvoiceItem(
            invoice_id=invoice.id,
            product_id=item["product_id"],
            hsn_sac=item["hsn_sac"],
            description=item["description"],
            quantity=item["quantity"],
            unit=item["unit"],
            rate=item["rate"],
            discount_percent=item["discount_percent"],
            discount_amount=item["discount_amount"],
            taxable_value=item["taxable_value"],
            cgst_rate=item["cgst_rate"],
            sgst_rate=item["sgst_rate"],
            igst_rate=item["igst_rate"],
            cgst_amount=item["cgst_amount"],
            sgst_amount=item["sgst_amount"],
            igst_amount=item["igst_amount"],
            cess_rate=item["cess_rate"],
            cess_amount=item["cess_amount"],
            total=item["total"],
        )
        db.add(invoice_item)

        if item["product_id"]:
            product = db.query(Product).filter(Product.id == item["product_id"]).first()
            if product:
                movement = StockMovement(
                    product_id=product.id,
                    quantity=-item["quantity"],
                    type="Sales",
                    reference_type="Invoice",
                    reference_id=invoice.id,
                    rate=item["rate"],
                    total=item["total"],
                    user_id=user_id,
                )
                db.add(movement)
                product.current_stock -= item["quantity"]

    if data.invoice_type == "Sales" and customer:
        customer.outstanding_amount += grand_total
    elif data.invoice_type == "Purchase" and supplier:
        supplier.outstanding_amount += grand_total

    voucher_type_label = "Sales" if data.invoice_type == "Sales" else "Purchase"
    voucher_no = generate_voucher_no(db, voucher_type_label, user_id)
    voucher = Voucher(
        voucher_no=voucher_no,
        voucher_type=voucher_type_label,
        date=datetime.combine(inv_date, datetime.min.time()),
        narration=f"{data.invoice_type} Invoice {invoice_no}",
        total_amount=grand_total,
        user_id=user_id,
    )
    db.add(voucher)
    db.flush()
    invoice.voucher_id = voucher.id

    party_account_id = None
    party_name = ""
    if customer:
        if not customer.account_id:
            raise HTTPException(status_code=400, detail="Customer has no linked account")
        party_account_id = customer.account_id
        party_name = customer.name
    elif supplier:
        if not supplier.account_id:
            raise HTTPException(status_code=400, detail="Supplier has no linked account")
        party_account_id = supplier.account_id
        party_name = supplier.name

    if data.invoice_type == "Sales":
        counter_account = db.query(Account).filter(
            Account.name == "Sales Account", Account.user_id == user_id
        ).first()
        if not counter_account:
            counter_account = Account(
                name="Sales Account", group_name="Direct Income",
                account_type="Income", user_id=user_id,
            )
            db.add(counter_account)
            db.flush()

        entry1 = AccountingEntry(voucher_id=voucher.id, account_id=party_account_id, debit=grand_total, particular=f"Sales Invoice {invoice_no} - {party_name}")
        entry2 = AccountingEntry(voucher_id=voucher.id, account_id=counter_account.id, credit=grand_total, particular=f"Sales Invoice {invoice_no}")
    else:
        counter_account = db.query(Account).filter(
            Account.name == "Purchase Account", Account.user_id == user_id
        ).first()
        if not counter_account:
            counter_account = Account(
                name="Purchase Account", group_name="Direct Expenses",
                account_type="Expenses", user_id=user_id,
            )
            db.add(counter_account)
            db.flush()

        entry1 = AccountingEntry(voucher_id=voucher.id, account_id=counter_account.id, debit=grand_total, particular=f"Purchase Invoice {invoice_no}")
        entry2 = AccountingEntry(voucher_id=voucher.id, account_id=party_account_id, credit=grand_total, particular=f"Purchase Invoice {invoice_no} - {party_name}")

    db.add(entry1)
    db.add(entry2)

    db.commit()
    db.refresh(invoice)

    invoice = db.query(Invoice).options(
        joinedload(Invoice.customer), joinedload(Invoice.supplier), joinedload(Invoice.items)
    ).filter(Invoice.id == invoice.id).first()

    return to_invoice_response(invoice)


@router.get("/report", response_model=InvoiceReport)
def invoice_report(db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    today = date.today()
    first_day = date(today.year, today.month, 1)

    total = db.query(func.coalesce(func.sum(Invoice.grand_total), 0)).filter(
        Invoice.user_id == user_id
    ).scalar()

    total_paid = db.query(func.coalesce(func.sum(Invoice.grand_total), 0)).filter(
        Invoice.user_id == user_id, Invoice.status == "Paid"
    ).scalar()

    total_unpaid = db.query(func.coalesce(func.sum(Invoice.grand_total), 0)).filter(
        Invoice.user_id == user_id, Invoice.status == "Unpaid"
    ).scalar()

    total_overdue = db.query(func.coalesce(func.sum(Invoice.grand_total), 0)).filter(
        Invoice.user_id == user_id, Invoice.status == "Unpaid",
        Invoice.due_date < today,
    ).scalar()

    count = db.query(func.count(Invoice.id)).filter(Invoice.user_id == user_id).scalar()

    return InvoiceReport(
        total_invoices=count or 0,
        total_amount=total or 0,
        total_paid=total_paid or 0,
        total_unpaid=total_unpaid or 0,
        total_overdue=total_overdue or 0,
    )


@router.get("/{invoice_id}", response_model=InvoiceResponse)
def get_invoice(invoice_id: int, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    invoice = db.query(Invoice).options(
        joinedload(Invoice.customer), joinedload(Invoice.supplier), joinedload(Invoice.items)
    ).filter(Invoice.id == invoice_id, Invoice.user_id == user_id).first()
    if not invoice:
        raise HTTPException(status_code=404, detail="Invoice not found")
    return to_invoice_response(invoice)


@router.put("/{invoice_id}/status")
def update_invoice_status(invoice_id: int, status: str, paid_amount: float = 0, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    invoice = db.query(Invoice).filter(Invoice.id == invoice_id, Invoice.user_id == user_id).first()
    if not invoice:
        raise HTTPException(status_code=404, detail="Invoice not found")

    invoice.status = status
    if paid_amount > 0:
        invoice.paid_amount += paid_amount
        invoice.balance_amount = invoice.grand_total - invoice.paid_amount
        if invoice.balance_amount <= 0:
            invoice.status = "Paid"

    db.commit()
    return {"message": "Invoice status updated"}


@router.delete("/{invoice_id}")
def delete_invoice(invoice_id: int, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    invoice = db.query(Invoice).filter(Invoice.id == invoice_id, Invoice.user_id == user_id).first()
    if not invoice:
        raise HTTPException(status_code=404, detail="Invoice not found")

    for item in invoice.items:
        if item.product_id:
            product = db.query(Product).filter(Product.id == item.product_id).first()
            if product:
                product.current_stock += item.quantity

    if invoice.voucher_id:
        voucher = db.query(Voucher).filter(Voucher.id == invoice.voucher_id).first()
        if voucher:
            db.query(AccountingEntry).filter(AccountingEntry.voucher_id == voucher.id).delete()
            db.delete(voucher)

    db.delete(invoice)
    db.commit()
    return {"message": "Invoice deleted"}


@router.get("/{invoice_id}/pdf")
def download_invoice_pdf(invoice_id: int, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    invoice = db.query(Invoice).filter(Invoice.id == invoice_id, Invoice.user_id == user_id).first()
    if not invoice:
        raise HTTPException(status_code=404, detail="Invoice not found")

    from app.services.pdf_generator import generate_invoice_pdf
    pdf_path = generate_invoice_pdf(invoice, db)
    from fastapi.responses import FileResponse
    return FileResponse(pdf_path, media_type="application/pdf", filename=f"Invoice_{invoice.invoice_no}.pdf")
