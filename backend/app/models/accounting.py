from sqlalchemy import Column, Integer, String, Float, DateTime, Text, ForeignKey, Enum, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum
from app.database import Base


class AccountGroupEnum(str, enum.Enum):
    CURRENT_ASSETS = "Current Assets"
    FIXED_ASSETS = "Fixed Assets"
    CURRENT_LIABILITIES = "Current Liabilities"
    LONG_TERM_LIABILITIES = "Long Term Liabilities"
    EQUITY = "Equity"
    REVENUE = "Revenue"
    EXPENSES = "Expenses"
    COST_OF_GOODS_SOLD = "Cost of Goods Sold"
    BANK_ACCOUNTS = "Bank Accounts"
    CASH_IN_HAND = "Cash in Hand"
    RECEIVABLES = "Receivables"
    PAYABLES = "Payables"
    DUTIES_TAXES = "Duties & Taxes"
    LOANS_ADVANCES = "Loans & Advances"
    DIRECT_INCOME = "Direct Income"
    INDIRECT_INCOME = "Indirect Income"
    DIRECT_EXPENSES = "Direct Expenses"
    INDIRECT_EXPENSES = "Indirect Expenses"


class Account(Base):
    __tablename__ = "accounts"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    group_name = Column(String(255), nullable=False)
    account_type = Column(String(100), nullable=False)
    opening_balance = Column(Float, default=0.0)
    current_balance = Column(Float, default=0.0)
    is_active = Column(Boolean, default=True)
    description = Column(Text, nullable=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    user = relationship("User")


class VoucherTypeEnum(str, enum.Enum):
    PAYMENT = "Payment"
    RECEIPT = "Receipt"
    SALES = "Sales"
    PURCHASE = "Purchase"
    CONTRA = "Contra"
    JOURNAL = "Journal"
    DEBIT_NOTE = "Debit Note"
    CREDIT_NOTE = "Credit Note"


class Voucher(Base):
    __tablename__ = "vouchers"

    id = Column(Integer, primary_key=True, index=True)
    voucher_no = Column(String(50), unique=True, nullable=False)
    voucher_type = Column(String(50), nullable=False)
    date = Column(DateTime, nullable=False)
    narration = Column(Text, nullable=True)
    reference_no = Column(String(100), nullable=True)
    total_amount = Column(Float, default=0.0)
    is_cancelled = Column(Boolean, default=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User")
    entries = relationship("AccountingEntry", back_populates="voucher", cascade="all, delete-orphan")


class AccountingEntry(Base):
    __tablename__ = "accounting_entries"

    id = Column(Integer, primary_key=True, index=True)
    voucher_id = Column(Integer, ForeignKey("vouchers.id"), nullable=False)
    account_id = Column(Integer, ForeignKey("accounts.id"), nullable=False)
    debit = Column(Float, default=0.0)
    credit = Column(Float, default=0.0)
    particular = Column(Text, nullable=True)

    voucher = relationship("Voucher", back_populates="entries")
    account = relationship("Account")
