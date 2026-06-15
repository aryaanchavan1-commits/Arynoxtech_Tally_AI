from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from sqlalchemy import func
from datetime import datetime
from app.database import get_db
from app.models.inventory import Product, ProductCategory, StockMovement
from app.schemas.inventory import (
    CategoryCreate, CategoryResponse,
    ProductCreate, ProductUpdate, ProductResponse, ProductLowStock,
)
from app.routes.auth import get_current_user

router = APIRouter(prefix="/api/inventory", tags=["Inventory"])


@router.get("/categories", response_model=List[CategoryResponse])
def list_categories(db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    return db.query(ProductCategory).filter(ProductCategory.user_id == user_id).all()


@router.post("/categories", response_model=CategoryResponse, status_code=201)
def create_category(data: CategoryCreate, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    cat = ProductCategory(name=data.name, description=data.description, user_id=user_id)
    db.add(cat)
    db.commit()
    db.refresh(cat)
    return cat


@router.delete("/categories/{category_id}")
def delete_category(category_id: int, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    cat = db.query(ProductCategory).filter(ProductCategory.id == category_id, ProductCategory.user_id == user_id).first()
    if not cat:
        raise HTTPException(status_code=404, detail="Category not found")
    product_count = db.query(Product).filter(Product.category_id == category_id).count()
    if product_count > 0:
        raise HTTPException(status_code=400, detail="Category has products, cannot delete")
    db.delete(cat)
    db.commit()
    return {"message": "Category deleted"}


@router.get("/products", response_model=List[ProductResponse])
def list_products(
    search: Optional[str] = None,
    category_id: Optional[int] = None,
    low_stock: Optional[bool] = None,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user),
):
    query = db.query(Product).filter(Product.user_id == user_id)
    if search:
        query = query.filter(
            Product.name.ilike(f"%{search}%") |
            Product.sku.ilike(f"%{search}%") |
            Product.barcode.ilike(f"%{search}%")
        )
    if category_id:
        query = query.filter(Product.category_id == category_id)
    if low_stock:
        query = query.filter(Product.current_stock <= Product.reorder_level)

    products = query.order_by(Product.name).all()
    result = []
    for p in products:
        result.append(ProductResponse(
            id=p.id,
            name=p.name,
            sku=p.sku,
            barcode=p.barcode,
            description=p.description,
            category_id=p.category_id,
            category_name=p.category.name if p.category else None,
            unit=p.unit,
            purchase_price=p.purchase_price,
            selling_price=p.selling_price,
            mrp=p.mrp,
            gst_rate=p.gst_rate,
            hsn_code=p.hsn_code,
            current_stock=p.current_stock,
            reorder_level=p.reorder_level,
            is_active=p.is_active,
        ))
    return result


@router.post("/products", response_model=ProductResponse, status_code=201)
def create_product(data: ProductCreate, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    if data.sku:
        existing = db.query(Product).filter(Product.sku == data.sku, Product.user_id == user_id).first()
        if existing:
            raise HTTPException(status_code=400, detail="SKU already exists")

    product = Product(
        name=data.name,
        sku=data.sku,
        barcode=data.barcode,
        description=data.description,
        category_id=data.category_id,
        unit=data.unit,
        purchase_price=data.purchase_price,
        selling_price=data.selling_price,
        mrp=data.mrp,
        gst_rate=data.gst_rate,
        hsn_code=data.hsn_code,
        opening_stock=data.opening_stock,
        current_stock=data.opening_stock,
        reorder_level=data.reorder_level,
        user_id=user_id,
    )
    db.add(product)
    db.commit()
    db.refresh(product)

    if data.opening_stock > 0:
        movement = StockMovement(
            product_id=product.id,
            quantity=data.opening_stock,
            type="Opening Stock",
            rate=data.purchase_price,
            total=data.opening_stock * data.purchase_price,
            user_id=user_id,
        )
        db.add(movement)
        db.commit()

    return ProductResponse(
        id=product.id, name=product.name, sku=product.sku, barcode=product.barcode,
        description=product.description, category_id=product.category_id,
        category_name=product.category.name if product.category else None,
        unit=product.unit, purchase_price=product.purchase_price,
        selling_price=product.selling_price, mrp=product.mrp,
        gst_rate=product.gst_rate, hsn_code=product.hsn_code,
        current_stock=product.current_stock, reorder_level=product.reorder_level,
        is_active=product.is_active,
    )


@router.get("/products/{product_id}", response_model=ProductResponse)
def get_product(product_id: int, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    product = db.query(Product).filter(Product.id == product_id, Product.user_id == user_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    return ProductResponse(
        id=product.id, name=product.name, sku=product.sku, barcode=product.barcode,
        description=product.description, category_id=product.category_id,
        category_name=product.category.name if product.category else None,
        unit=product.unit, purchase_price=product.purchase_price,
        selling_price=product.selling_price, mrp=product.mrp,
        gst_rate=product.gst_rate, hsn_code=product.hsn_code,
        current_stock=product.current_stock, reorder_level=product.reorder_level,
        is_active=product.is_active,
    )


@router.put("/products/{product_id}", response_model=ProductResponse)
def update_product(product_id: int, data: ProductUpdate, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    product = db.query(Product).filter(Product.id == product_id, Product.user_id == user_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")

    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(product, field, value)

    db.commit()
    db.refresh(product)
    return ProductResponse(
        id=product.id, name=product.name, sku=product.sku, barcode=product.barcode,
        description=product.description, category_id=product.category_id,
        category_name=product.category.name if product.category else None,
        unit=product.unit, purchase_price=product.purchase_price,
        selling_price=product.selling_price, mrp=product.mrp,
        gst_rate=product.gst_rate, hsn_code=product.hsn_code,
        current_stock=product.current_stock, reorder_level=product.reorder_level,
        is_active=product.is_active,
    )


@router.delete("/products/{product_id}")
def delete_product(product_id: int, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    product = db.query(Product).filter(Product.id == product_id, Product.user_id == user_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    db.delete(product)
    db.commit()
    return {"message": "Product deleted"}


@router.get("/products/low-stock/list")
def low_stock_products(db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    products = db.query(Product).filter(
        Product.user_id == user_id,
        Product.current_stock <= Product.reorder_level,
    ).all()
    return [
        {"id": p.id, "name": p.name, "sku": p.sku, "current_stock": p.current_stock, "reorder_level": p.reorder_level}
        for p in products
    ]
