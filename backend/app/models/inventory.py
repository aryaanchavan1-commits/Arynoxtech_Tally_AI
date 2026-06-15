from sqlalchemy import Column, Integer, String, Float, DateTime, Text, ForeignKey, Boolean, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum
from app.database import Base


class ProductCategory(Base):
    __tablename__ = "product_categories"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User")
    products = relationship("Product", back_populates="category")


class UnitType(str, enum.Enum):
    PIECES = "Pieces"
    KILOGRAM = "Kilogram"
    GRAM = "Gram"
    LITRE = "Litre"
    MILLILITRE = "Millilitre"
    METER = "Meter"
    BOX = "Box"
    PACK = "Pack"
    DOZEN = "Dozen"
    BAG = "Bag"
    BOTTLE = "Bottle"
    PAIR = "Pair"
    SET = "Set"
    ROLL = "Roll"
    SHEET = "Sheet"
    OTHER = "Other"


class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    sku = Column(String(100), unique=True, nullable=True)
    barcode = Column(String(100), unique=True, nullable=True)
    description = Column(Text, nullable=True)
    category_id = Column(Integer, ForeignKey("product_categories.id"), nullable=True)
    unit = Column(String(50), default="Pieces")
    purchase_price = Column(Float, default=0.0)
    selling_price = Column(Float, default=0.0)
    mrp = Column(Float, default=0.0)
    gst_rate = Column(Float, default=0.0)
    hsn_code = Column(String(20), nullable=True)
    opening_stock = Column(Float, default=0.0)
    current_stock = Column(Float, default=0.0)
    reorder_level = Column(Float, default=0.0)
    is_active = Column(Boolean, default=True)
    image_path = Column(String(500), nullable=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    user = relationship("User")
    category = relationship("ProductCategory", back_populates="products")


class StockMovement(Base):
    __tablename__ = "stock_movements"

    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    quantity = Column(Float, nullable=False)
    type = Column(String(50), nullable=False)
    reference_type = Column(String(100), nullable=True)
    reference_id = Column(Integer, nullable=True)
    rate = Column(Float, default=0.0)
    total = Column(Float, default=0.0)
    narration = Column(Text, nullable=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    product = relationship("Product")
    user = relationship("User")
