from pydantic import BaseModel, Field, ConfigDict
from typing import Optional
from datetime import date


class ExpenseCategoryCreate(BaseModel):
    name: str
    description: Optional[str] = None


class ExpenseCategoryResponse(BaseModel):
    id: int
    name: str
    description: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class ExpenseCreate(BaseModel):
    category_id: int
    amount: float
    expense_date: str
    payment_mode: Optional[str] = None
    reference_no: Optional[str] = None
    description: Optional[str] = None
    is_recurring: bool = False
    recurring_frequency: Optional[str] = None
    recurring_end_date: Optional[str] = None


class ExpenseResponse(BaseModel):
    id: int
    category_id: int
    category_name: Optional[str] = None
    amount: float
    expense_date: date
    payment_mode: Optional[str] = None
    reference_no: Optional[str] = None
    description: Optional[str] = None
    is_recurring: bool

    model_config = ConfigDict(from_attributes=True)


class ExpenseReport(BaseModel):
    total_expenses: float
    category_wise: dict
    monthly_total: float
