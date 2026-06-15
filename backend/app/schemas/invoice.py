from pydantic import BaseModel, Field, model_validator, ConfigDict
from typing import Optional, List
from datetime import date
import re


class InvoiceItemCreate(BaseModel):
    product_id: Optional[int] = None
    hsn_sac: Optional[str] = None
    description: Optional[str] = None
    quantity: float = 1.0
    unit: str = "NOS"
    rate: float = 0.0
    discount_percent: float = 0.0
    cgst_rate: float = 0.0
    sgst_rate: float = 0.0
    igst_rate: float = 0.0
    cess_rate: float = 0.0


class InvoiceCreate(BaseModel):
    invoice_type: str
    invoice_date: str
    due_date: Optional[str] = None
    customer_id: Optional[int] = None
    supplier_id: Optional[int] = None
    place_of_supply: Optional[str] = None
    reverse_charge: bool = False
    ecommerce_gstin: Optional[str] = None
    ref_invoice_no: Optional[str] = None
    ref_invoice_date: Optional[str] = None
    doc_type: str = "INV"
    discount_type: str = "percentage"
    discount_value: float = 0.0
    tax_type: str = "gst"
    shipping_charge: float = 0.0
    terms_conditions: Optional[str] = None
    notes: Optional[str] = None
    items: List[InvoiceItemCreate]

    @model_validator(mode="after")
    def validate_gst_fields(self):
        errors = {}
        if self.invoice_type not in ("Sales", "Purchase", "Credit Note", "Debit Note"):
            errors["invoice_type"] = "Must be Sales, Purchase, Credit Note, or Debit Note"
        try:
            date.fromisoformat(self.invoice_date)
        except ValueError:
            errors["invoice_date"] = "Invalid date format (use YYYY-MM-DD)"
        if self.ref_invoice_date:
            try:
                date.fromisoformat(self.ref_invoice_date)
            except ValueError:
                errors["ref_invoice_date"] = "Invalid date format (use YYYY-MM-DD)"
        if self.ecommerce_gstin and not re.match(r"^\d{2}[A-Z]{5}\d{4}[A-Z]{1}\d[Z]{1}[A-Z\d]{1}$", self.ecommerce_gstin):
            errors["ecommerce_gstin"] = "Invalid GSTIN format"
        if errors:
            raise ValueError(errors)
        return self


class InvoiceItemResponse(BaseModel):
    id: int
    product_id: Optional[int] = None
    hsn_sac: Optional[str] = None
    description: Optional[str] = None
    quantity: float
    unit: str = "NOS"
    rate: float
    discount_percent: float
    discount_amount: float
    taxable_value: float
    cgst_rate: float
    sgst_rate: float
    igst_rate: float
    cgst_amount: float
    sgst_amount: float
    igst_amount: float
    cess_rate: float
    cess_amount: float
    total: float

    model_config = ConfigDict(from_attributes=True)


class InvoiceResponse(BaseModel):
    id: int
    invoice_no: str
    invoice_type: str
    invoice_date: date
    due_date: Optional[date] = None
    customer_id: Optional[int] = None
    customer_name: Optional[str] = None
    customer_gstin: Optional[str] = None
    supplier_id: Optional[int] = None
    supplier_name: Optional[str] = None
    supplier_gstin: Optional[str] = None
    irn: Optional[str] = None
    ack_no: Optional[str] = None
    ack_date: Optional[date] = None
    place_of_supply: Optional[str] = None
    reverse_charge: bool = False
    ecommerce_gstin: Optional[str] = None
    ref_invoice_no: Optional[str] = None
    ref_invoice_date: Optional[date] = None
    doc_type: str = "INV"
    subtotal: float
    discount_amount: float
    taxable_amount: float
    cgst_amount: float
    sgst_amount: float
    igst_amount: float
    total_tax: float
    cess_amount: float
    shipping_charge: float
    round_off: float
    grand_total: float
    grand_total_words: Optional[str] = None
    paid_amount: float
    balance_amount: float
    status: str
    items: List[InvoiceItemResponse] = []

    model_config = ConfigDict(from_attributes=True)


class InvoiceReport(BaseModel):
    total_invoices: int
    total_amount: float
    total_paid: float
    total_unpaid: float
    total_overdue: float
