from sqlalchemy import Column, Integer, String, Float, DateTime, Text, ForeignKey, Boolean, Date, Enum as SAEnum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum
from app.database import Base


class Company(Base):
    __tablename__ = "companies"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    alias = Column(String(100), nullable=True)
    address = Column(Text, nullable=True)
    city = Column(String(100), nullable=True)
    state = Column(String(100), nullable=True)
    pincode = Column(String(20), nullable=True)
    country = Column(String(100), default="India")
    phone = Column(String(50), nullable=True)
    mobile = Column(String(50), nullable=True)
    email = Column(String(255), nullable=True)
    website = Column(String(255), nullable=True)
    gstin = Column(String(50), nullable=True)
    pan = Column(String(50), nullable=True)
    cin = Column(String(50), nullable=True)
    tan = Column(String(50), nullable=True)
    registration_type = Column(String(50), default="Regular")
    financial_year_from = Column(Date, nullable=True)
    financial_year_to = Column(Date, nullable=True)
    books_beginning_from = Column(Date, nullable=True)
    base_currency = Column(String(10), default="INR")
    logo_path = Column(String(500), nullable=True)
    is_active = Column(Boolean, default=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    user = relationship("User")


class Godown(Base):
    __tablename__ = "godowns"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    alias = Column(String(100), nullable=True)
    address = Column(Text, nullable=True)
    city = Column(String(100), nullable=True)
    state = Column(String(100), nullable=True)
    pincode = Column(String(20), nullable=True)
    country = Column(String(100), default="India")
    phone = Column(String(50), nullable=True)
    email = Column(String(255), nullable=True)
    is_active = Column(Boolean, default=True)
    parent_id = Column(Integer, ForeignKey("godowns.id"), nullable=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User")
    parent = relationship("Godown", remote_side=[id], backref="children")


class StockGroup(Base):
    __tablename__ = "stock_groups"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    alias = Column(String(100), nullable=True)
    parent_id = Column(Integer, ForeignKey("stock_groups.id"), nullable=True)
    is_active = Column(Boolean, default=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User")
    parent = relationship("StockGroup", remote_side=[id], backref="children")


class ProductBatch(Base):
    __tablename__ = "product_batches"

    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    batch_no = Column(String(100), nullable=False)
    manufacturing_date = Column(Date, nullable=True)
    expiry_date = Column(Date, nullable=True)
    godown_id = Column(Integer, ForeignKey("godowns.id"), nullable=True)
    quantity = Column(Float, default=0.0)
    purchase_rate = Column(Float, default=0.0)
    selling_rate = Column(Float, default=0.0)
    mrp = Column(Float, default=0.0)
    is_active = Column(Boolean, default=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    product = relationship("Product")
    godown = relationship("Godown")
    user = relationship("User")


class StockValuation(Base):
    __tablename__ = "stock_valuations"

    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    godown_id = Column(Integer, ForeignKey("godowns.id"), nullable=True)
    valuation_method = Column(String(50), default="FIFO")
    quantity = Column(Float, default=0.0)
    rate = Column(Float, default=0.0)
    value = Column(Float, default=0.0)
    as_on_date = Column(Date, nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    product = relationship("Product")
    godown = relationship("Godown")
    user = relationship("User")


class CostCategory(Base):
    __tablename__ = "cost_categories"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User")
    centers = relationship("CostCenter", back_populates="category")


class CostCenter(Base):
    __tablename__ = "cost_centers"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    category_id = Column(Integer, ForeignKey("cost_categories.id"), nullable=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User")
    category = relationship("CostCategory", back_populates="centers")


class CostCenterAllocation(Base):
    __tablename__ = "cost_center_allocations"

    id = Column(Integer, primary_key=True, index=True)
    cost_center_id = Column(Integer, ForeignKey("cost_centers.id"), nullable=False)
    voucher_id = Column(Integer, ForeignKey("vouchers.id"), nullable=False)
    account_id = Column(Integer, ForeignKey("accounts.id"), nullable=True)
    amount = Column(Float, default=0.0)
    percentage = Column(Float, default=0.0)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    cost_center = relationship("CostCenter")
    voucher = relationship("Voucher")
    account = relationship("Account")
    user = relationship("User")


class BillWiseDetail(Base):
    __tablename__ = "bill_wise_details"

    id = Column(Integer, primary_key=True, index=True)
    voucher_id = Column(Integer, ForeignKey("vouchers.id"), nullable=False)
    bill_type = Column(String(50), nullable=False)
    bill_name = Column(String(255), nullable=True)
    due_date = Column(Date, nullable=True)
    reference_voucher_id = Column(Integer, ForeignKey("vouchers.id"), nullable=True)
    amount = Column(Float, default=0.0)
    adjusted_amount = Column(Float, default=0.0)
    balance_amount = Column(Float, default=0.0)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    voucher = relationship("Voucher", foreign_keys=[voucher_id])
    reference_voucher = relationship("Voucher", foreign_keys=[reference_voucher_id])
    user = relationship("User")


class BankTransaction(Base):
    __tablename__ = "bank_transactions"

    id = Column(Integer, primary_key=True, index=True)
    account_id = Column(Integer, ForeignKey("accounts.id"), nullable=False)
    transaction_date = Column(Date, nullable=False)
    transaction_type = Column(String(50), nullable=False)
    amount = Column(Float, default=0.0)
    cheque_no = Column(String(100), nullable=True)
    cheque_date = Column(Date, nullable=True)
    bank_reference = Column(String(255), nullable=True)
    narration = Column(Text, nullable=True)
    is_reconciled = Column(Boolean, default=False)
    reconciliation_date = Column(Date, nullable=True)
    voucher_id = Column(Integer, ForeignKey("vouchers.id"), nullable=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    account = relationship("Account")
    voucher = relationship("Voucher")
    user = relationship("User")


class TDSDeduction(Base):
    __tablename__ = "tds_deductions"

    id = Column(Integer, primary_key=True, index=True)
    voucher_id = Column(Integer, ForeignKey("vouchers.id"), nullable=False)
    section = Column(String(50), nullable=False)
    nature_of_payment = Column(String(255), nullable=True)
    party_name = Column(String(255), nullable=False)
    party_pan = Column(String(50), nullable=True)
    amount = Column(Float, default=0.0)
    tds_rate = Column(Float, default=0.0)
    tds_amount = Column(Float, default=0.0)
    surcharge = Column(Float, default=0.0)
    cess = Column(Float, default=0.0)
    total_tds = Column(Float, default=0.0)
    transaction_date = Column(Date, nullable=False)
    due_date = Column(Date, nullable=True)
    challan_no = Column(String(100), nullable=True)
    challan_date = Column(Date, nullable=True)
    is_filed = Column(Boolean, default=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    voucher = relationship("Voucher")
    user = relationship("User")


class Budget(Base):
    __tablename__ = "budgets"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    financial_year = Column(String(20), nullable=False)
    account_id = Column(Integer, ForeignKey("accounts.id"), nullable=True)
    cost_center_id = Column(Integer, ForeignKey("cost_centers.id"), nullable=True)
    budgeted_amount = Column(Float, default=0.0)
    actual_amount = Column(Float, default=0.0)
    variance = Column(Float, default=0.0)
    variance_percentage = Column(Float, default=0.0)
    period = Column(String(50), default="Yearly")
    is_active = Column(Boolean, default=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    account = relationship("Account")
    cost_center = relationship("CostCenter")
    user = relationship("User")


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    action = Column(String(100), nullable=False)
    entity_type = Column(String(100), nullable=False)
    entity_id = Column(Integer, nullable=True)
    old_value = Column(Text, nullable=True)
    new_value = Column(Text, nullable=True)
    ip_address = Column(String(50), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User")


class Cheque(Base):
    __tablename__ = "cheques"

    id = Column(Integer, primary_key=True, index=True)
    account_id = Column(Integer, ForeignKey("accounts.id"), nullable=False)
    cheque_no = Column(String(100), nullable=False)
    cheque_date = Column(Date, nullable=False)
    party_name = Column(String(255), nullable=True)
    amount = Column(Float, default=0.0)
    status = Column(String(50), default="Issued")
    bank_name = Column(String(255), nullable=True)
    branch = Column(String(255), nullable=True)
    micr_code = Column(String(50), nullable=True)
    deposited_date = Column(Date, nullable=True)
    cleared_date = Column(Date, nullable=True)
    bounce_date = Column(Date, nullable=True)
    bounce_reason = Column(Text, nullable=True)
    voucher_id = Column(Integer, ForeignKey("vouchers.id"), nullable=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    account = relationship("Account")
    voucher = relationship("Voucher")
    user = relationship("User")


class PriceLevel(Base):
    __tablename__ = "price_levels"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=True)
    customer_id = Column(Integer, ForeignKey("customers.id"), nullable=True)
    price = Column(Float, default=0.0)
    discount_percentage = Column(Float, default=0.0)
    is_active = Column(Boolean, default=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    product = relationship("Product")
    customer = relationship("Customer")
    user = relationship("User")


class BillOfMaterial(Base):
    __tablename__ = "bill_of_materials"

    id = Column(Integer, primary_key=True, index=True)
    finished_product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    raw_product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    quantity_required = Column(Float, default=1.0)
    wastage_percentage = Column(Float, default=0.0)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    finished_product = relationship("Product", foreign_keys=[finished_product_id])
    raw_product = relationship("Product", foreign_keys=[raw_product_id])
    user = relationship("User")


class POSSession(Base):
    __tablename__ = "pos_sessions"

    id = Column(Integer, primary_key=True, index=True)
    session_no = Column(String(50), unique=True, nullable=False)
    opened_at = Column(DateTime, nullable=False)
    closed_at = Column(DateTime, nullable=True)
    opening_balance = Column(Float, default=0.0)
    closing_balance = Column(Float, default=0.0)
    total_sales = Column(Float, default=0.0)
    total_cash = Column(Float, default=0.0)
    total_card = Column(Float, default=0.0)
    total_upi = Column(Float, default=0.0)
    status = Column(String(50), default="Open")
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User")


class GodownStock(Base):
    __tablename__ = "godown_stocks"

    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    godown_id = Column(Integer, ForeignKey("godowns.id"), nullable=False)
    quantity = Column(Float, default=0.0)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    product = relationship("Product")
    godown = relationship("Godown")
    user = relationship("User")


class StockTransfer(Base):
    __tablename__ = "stock_transfers"

    id = Column(Integer, primary_key=True, index=True)
    transfer_no = Column(String(50), unique=True, nullable=False)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    quantity = Column(Float, nullable=False)
    from_godown_id = Column(Integer, ForeignKey("godowns.id"), nullable=False)
    to_godown_id = Column(Integer, ForeignKey("godowns.id"), nullable=False)
    transfer_date = Column(Date, nullable=False)
    narration = Column(Text, nullable=True)
    status = Column(String(50), default="Completed")
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    product = relationship("Product")
    from_godown = relationship("Godown", foreign_keys=[from_godown_id])
    to_godown = relationship("Godown", foreign_keys=[to_godown_id])
    user = relationship("User")


class GSTReturn(Base):
    __tablename__ = "gst_returns"

    id = Column(Integer, primary_key=True, index=True)
    return_type = Column(String(20), nullable=False)
    period = Column(String(20), nullable=False)
    financial_year = Column(String(20), nullable=False)
    generated_at = Column(DateTime, server_default=func.now())
    total_invoices = Column(Integer, default=0)
    total_taxable = Column(Float, default=0.0)
    total_cgst = Column(Float, default=0.0)
    total_sgst = Column(Float, default=0.0)
    total_igst = Column(Float, default=0.0)
    total_cess = Column(Float, default=0.0)
    status = Column(String(50), default="Draft")
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User")
