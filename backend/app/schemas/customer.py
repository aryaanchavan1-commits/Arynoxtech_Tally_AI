from pydantic import BaseModel, Field, field_validator, ConfigDict
from typing import Optional
import re

GSTIN_PATTERN = re.compile(r"^\d{2}[A-Z]{5}\d{4}[A-Z]{1}\d[Z]{1}[A-Z\d]{1}$")


class CustomerCreate(BaseModel):
    name: str
    company_name: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    mobile: Optional[str] = None
    gstin: Optional[str] = None
    pan: Optional[str] = None

    @field_validator("gstin")
    @classmethod
    def validate_gstin(cls, v):
        if v is not None and not GSTIN_PATTERN.match(v):
            raise ValueError("Invalid GSTIN format")
        return v
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    pincode: Optional[str] = None
    country: str = "India"
    credit_limit: float = 0.0
    opening_balance: float = 0.0
    notes: Optional[str] = None


class CustomerUpdate(BaseModel):
    name: Optional[str] = None
    company_name: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    mobile: Optional[str] = None
    gstin: Optional[str] = None
    pan: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    pincode: Optional[str] = None
    country: Optional[str] = None
    credit_limit: Optional[float] = None
    notes: Optional[str] = None


class CustomerResponse(BaseModel):
    id: int
    name: str
    company_name: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    mobile: Optional[str] = None
    gstin: Optional[str] = None
    pan: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    pincode: Optional[str] = None
    country: str = "India"
    credit_limit: float
    opening_balance: float
    current_balance: float
    outstanding_amount: float
    is_active: bool

    model_config = ConfigDict(from_attributes=True)
