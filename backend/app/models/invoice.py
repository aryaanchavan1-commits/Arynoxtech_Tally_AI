from sqlalchemy import Column, Integer, String, Float, DateTime, Text, ForeignKey, Boolean, Date
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base


class Invoice(Base):
    __tablename__ = "invoices"

    id = Column(Integer, primary_key=True, index=True)
    invoice_no = Column(String(50), unique=True, nullable=False)
    invoice_type = Column(String(20), nullable=False)
    invoice_date = Column(Date, nullable=False)
    due_date = Column(Date, nullable=True)
    customer_id = Column(Integer, ForeignKey("customers.id"), nullable=True)
    supplier_id = Column(Integer, ForeignKey("suppliers.id"), nullable=True)
    voucher_id = Column(Integer, ForeignKey("vouchers.id"), nullable=True)

    irn = Column(String(64), nullable=True, index=True)
    ack_no = Column(String(20), nullable=True)
    ack_date = Column(Date, nullable=True)
    qr_code = Column(Text, nullable=True)
    place_of_supply = Column(String(50), nullable=True)
    reverse_charge = Column(Boolean, default=False)
    ecommerce_gstin = Column(String(50), nullable=True)
    ref_invoice_no = Column(String(50), nullable=True)
    ref_invoice_date = Column(Date, nullable=True)
    doc_type = Column(String(20), default="INV")

    subtotal = Column(Float, default=0.0)
    discount_type = Column(String(20), default="percentage")
    discount_value = Column(Float, default=0.0)
    discount_amount = Column(Float, default=0.0)
    taxable_amount = Column(Float, default=0.0)
    tax_type = Column(String(20), default="gst")
    cgst_rate = Column(Float, default=0.0)
    sgst_rate = Column(Float, default=0.0)
    igst_rate = Column(Float, default=0.0)
    cgst_amount = Column(Float, default=0.0)
    sgst_amount = Column(Float, default=0.0)
    igst_amount = Column(Float, default=0.0)
    total_tax = Column(Float, default=0.0)
    cess_amount = Column(Float, default=0.0)
    shipping_charge = Column(Float, default=0.0)
    round_off = Column(Float, default=0.0)
    grand_total = Column(Float, default=0.0)
    grand_total_words = Column(String(500), nullable=True)
    paid_amount = Column(Float, default=0.0)
    balance_amount = Column(Float, default=0.0)
    status = Column(String(20), default="Unpaid")
    terms_conditions = Column(Text, nullable=True)
    notes = Column(Text, nullable=True)
    company_logo_path = Column(String(500), nullable=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User")
    customer = relationship("Customer")
    supplier = relationship("Supplier")
    voucher = relationship("Voucher")
    items = relationship("InvoiceItem", back_populates="invoice", cascade="all, delete-orphan")


class InvoiceItem(Base):
    __tablename__ = "invoice_items"

    id = Column(Integer, primary_key=True, index=True)
    invoice_id = Column(Integer, ForeignKey("invoices.id"), nullable=False)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=True)
    hsn_sac = Column(String(20), nullable=True)
    description = Column(String(500), nullable=True)
    quantity = Column(Float, default=1.0)
    unit = Column(String(20), default="NOS")
    rate = Column(Float, default=0.0)
    discount_percent = Column(Float, default=0.0)
    discount_amount = Column(Float, default=0.0)
    taxable_value = Column(Float, default=0.0)
    cgst_rate = Column(Float, default=0.0)
    sgst_rate = Column(Float, default=0.0)
    igst_rate = Column(Float, default=0.0)
    cgst_amount = Column(Float, default=0.0)
    sgst_amount = Column(Float, default=0.0)
    igst_amount = Column(Float, default=0.0)
    cess_rate = Column(Float, default=0.0)
    cess_amount = Column(Float, default=0.0)
    total = Column(Float, default=0.0)

    invoice = relationship("Invoice", back_populates="items")
    product = relationship("Product")
