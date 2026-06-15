from pydantic import BaseModel, Field, ConfigDict
from typing import Optional, List
from datetime import datetime


class AccountCreate(BaseModel):
    name: str
    group_name: str
    account_type: str
    opening_balance: float = 0.0
    description: Optional[str] = None


class AccountResponse(BaseModel):
    id: int
    name: str
    group_name: str
    account_type: str
    opening_balance: float
    current_balance: float
    is_active: bool
    description: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class EntryCreate(BaseModel):
    account_id: int
    debit: float = 0.0
    credit: float = 0.0
    particular: Optional[str] = None


class VoucherCreate(BaseModel):
    voucher_type: str
    date: str
    narration: Optional[str] = None
    reference_no: Optional[str] = None
    entries: List[EntryCreate]


class VoucherResponse(BaseModel):
    id: int
    voucher_no: str
    voucher_type: str
    date: datetime
    narration: Optional[str] = None
    reference_no: Optional[str] = None
    total_amount: float
    is_cancelled: bool
    created_at: Optional[datetime] = None
    entries: List[EntryCreate] = []

    model_config = ConfigDict(from_attributes=True)


class TrialBalanceItem(BaseModel):
    account_id: int
    account_name: str
    group_name: str
    opening_balance: float
    debit: float
    credit: float
    closing_balance: float


class TrialBalanceResponse(BaseModel):
    items: List[TrialBalanceItem]
    total_debit: float
    total_credit: float


class ProfitLossItem(BaseModel):
    account_id: int
    account_name: str
    group_name: str
    amount: float


class ProfitLossResponse(BaseModel):
    income_items: List[ProfitLossItem]
    expense_items: List[ProfitLossItem]
    total_income: float
    total_expenses: float
    net_profit: float


class BalanceSheetItem(BaseModel):
    account_id: int
    account_name: str
    group_name: str
    amount: float


class BalanceSheetResponse(BaseModel):
    assets: List[BalanceSheetItem]
    liabilities: List[BalanceSheetItem]
    equity: List[BalanceSheetItem]
    total_assets: float
    total_liabilities: float
    total_equity: float
