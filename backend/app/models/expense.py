from sqlalchemy import Column, Integer, String, Float, DateTime, Text, ForeignKey, Boolean, Date
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base


class ExpenseCategory(Base):
    __tablename__ = "expense_categories"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User")


class Expense(Base):
    __tablename__ = "expenses"

    id = Column(Integer, primary_key=True, index=True)
    category_id = Column(Integer, ForeignKey("expense_categories.id"), nullable=False)
    amount = Column(Float, nullable=False)
    expense_date = Column(Date, nullable=False)
    payment_mode = Column(String(50), nullable=True)
    reference_no = Column(String(100), nullable=True)
    description = Column(Text, nullable=True)
    is_recurring = Column(Boolean, default=False)
    recurring_frequency = Column(String(50), nullable=True)
    recurring_end_date = Column(Date, nullable=True)
    attachment_path = Column(String(500), nullable=True)
    voucher_id = Column(Integer, ForeignKey("vouchers.id"), nullable=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User")
    category = relationship("ExpenseCategory")
    voucher = relationship("Voucher")
