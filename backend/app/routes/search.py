from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import Optional
from app.database import get_db
from app.models.customer import Customer
from app.models.supplier import Supplier
from app.models.inventory import Product
from app.models.invoice import Invoice
from app.schemas.search import SearchRequest, SearchResult, SearchResponse
from app.routes.auth import get_current_user

router = APIRouter(prefix="/api/search", tags=["Search"])


@router.get("/", response_model=SearchResponse)
def global_search(query: str = Query(..., min_length=1), db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    results = []

    customers = db.query(Customer).filter(
        Customer.user_id == user_id,
        Customer.name.ilike(f"%{query}%"),
    ).limit(10).all()
    for c in customers:
        results.append(SearchResult(type="customer", id=c.id, title=c.name, subtitle=c.mobile or c.email))

    suppliers = db.query(Supplier).filter(
        Supplier.user_id == user_id,
        Supplier.name.ilike(f"%{query}%"),
    ).limit(10).all()
    for s in suppliers:
        results.append(SearchResult(type="supplier", id=s.id, title=s.name, subtitle=s.mobile or s.email))

    products = db.query(Product).filter(
        Product.user_id == user_id,
        Product.name.ilike(f"%{query}%"),
    ).limit(10).all()
    for p in products:
        results.append(SearchResult(type="product", id=p.id, title=p.name, subtitle=f"SKU: {p.sku or 'N/A'} | Stock: {p.current_stock}"))

    invoices = db.query(Invoice).filter(
        Invoice.user_id == user_id,
        Invoice.invoice_no.ilike(f"%{query}%"),
    ).limit(10).all()
    for inv in invoices:
        results.append(SearchResult(type="invoice", id=inv.id, title=f"Invoice #{inv.invoice_no}", subtitle=f"Amount: {inv.grand_total} | Status: {inv.status}"))

    return SearchResponse(results=results, total_count=len(results))
