from pydantic import BaseModel, Field, ConfigDict
from typing import Optional, List
from datetime import datetime


class CategoryCreate(BaseModel):
    name: str
    description: Optional[str] = None


class CategoryResponse(BaseModel):
    id: int
    name: str
    description: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class ProductCreate(BaseModel):
    name: str
    sku: Optional[str] = None
    barcode: Optional[str] = None
    description: Optional[str] = None
    category_id: Optional[int] = None
    unit: str = "Pieces"
    purchase_price: float = 0.0
    selling_price: float = 0.0
    mrp: float = 0.0
    gst_rate: float = 0.0
    hsn_code: Optional[str] = None
    opening_stock: float = 0.0
    reorder_level: float = 0.0


class ProductUpdate(BaseModel):
    name: Optional[str] = None
    sku: Optional[str] = None
    barcode: Optional[str] = None
    description: Optional[str] = None
    category_id: Optional[int] = None
    unit: Optional[str] = None
    purchase_price: Optional[float] = None
    selling_price: Optional[float] = None
    mrp: Optional[float] = None
    gst_rate: Optional[float] = None
    hsn_code: Optional[str] = None
    reorder_level: Optional[float] = None


class ProductResponse(BaseModel):
    id: int
    name: str
    sku: Optional[str] = None
    barcode: Optional[str] = None
    description: Optional[str] = None
    category_id: Optional[int] = None
    category_name: Optional[str] = None
    unit: str
    purchase_price: float
    selling_price: float
    mrp: float
    gst_rate: float
    hsn_code: Optional[str] = None
    current_stock: float
    reorder_level: float
    is_active: bool

    model_config = ConfigDict(from_attributes=True)


class ProductLowStock(BaseModel):
    id: int
    name: str
    sku: Optional[str] = None
    current_stock: float
    reorder_level: float
