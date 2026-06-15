import os
import shutil
import json
from datetime import datetime, date
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db, engine, SessionLocal
from app.models.backup import Backup
from app.schemas.backup import BackupResponse
from app.routes.auth import get_current_user

router = APIRouter(prefix="/api/backup", tags=["Backup & Restore"])

BACKUP_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "backups")
os.makedirs(BACKUP_DIR, exist_ok=True)


@router.post("/create")
def create_backup(description: str = "", db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"arynoxtech_backup_{timestamp}.db"
    filepath = os.path.join(BACKUP_DIR, filename)

    db_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "data", "arynoxtech_tally.db")
    if os.path.exists(db_path):
        shutil.copy2(db_path, filepath)
    else:
        raise HTTPException(status_code=404, detail="Database file not found")

    size_bytes = os.path.getsize(filepath)
    backup = Backup(
        filename=filename, filepath=filepath,
        size_bytes=size_bytes, backup_type="manual",
        description=description, user_id=user_id,
    )
    db.add(backup)
    db.commit()
    db.refresh(backup)

    return {
        "message": "Backup created successfully",
        "backup": BackupResponse.model_validate(backup),
    }


@router.get("/list", response_model=List[BackupResponse])
def list_backups(db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    backups = db.query(Backup).filter(Backup.user_id == user_id).order_by(Backup.created_at.desc()).all()
    return [BackupResponse.model_validate(b) for b in backups]


@router.post("/restore/{backup_id}")
def restore_backup(backup_id: int, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    backup = db.query(Backup).filter(Backup.id == backup_id, Backup.user_id == user_id).first()
    if not backup:
        raise HTTPException(status_code=404, detail="Backup not found")
    if not os.path.exists(backup.filepath):
        raise HTTPException(status_code=404, detail="Backup file not found")

    db_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "data", "arynoxtech_tally.db")
    shutil.copy2(backup.filepath, db_path)

    return {"message": "Backup restored successfully. Please restart the application."}


@router.delete("/{backup_id}")
def delete_backup(backup_id: int, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    backup = db.query(Backup).filter(Backup.id == backup_id, Backup.user_id == user_id).first()
    if not backup:
        raise HTTPException(status_code=404, detail="Backup not found")
    if os.path.exists(backup.filepath):
        os.remove(backup.filepath)
    db.delete(backup)
    db.commit()
    return {"message": "Backup deleted"}


@router.get("/download/{backup_id}")
def download_backup(backup_id: int, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    backup = db.query(Backup).filter(Backup.id == backup_id, Backup.user_id == user_id).first()
    if not backup:
        raise HTTPException(status_code=404, detail="Backup not found")
    if not os.path.exists(backup.filepath):
        raise HTTPException(status_code=404, detail="Backup file not found")
    return FileResponse(backup.filepath, filename=backup.filename)


@router.post("/export")
def export_data(data_type: str, db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    from app.models.accounting import Account, Voucher, AccountingEntry
    from app.models.customer import Customer
    from app.models.supplier import Supplier
    from app.models.inventory import Product, ProductCategory
    from app.models.invoice import Invoice, InvoiceItem
    from app.models.expense import Expense, ExpenseCategory

    export_map = {
        "accounts": (Account, ["id", "name", "group_name", "account_type", "opening_balance", "current_balance"]),
        "customers": (Customer, ["id", "name", "email", "phone", "mobile", "gstin", "city", "state", "current_balance", "outstanding_amount"]),
        "suppliers": (Supplier, ["id", "name", "email", "phone", "mobile", "gstin", "city", "state", "current_balance", "outstanding_amount"]),
        "products": (Product, ["id", "name", "sku", "barcode", "unit", "purchase_price", "selling_price", "current_stock", "gst_rate"]),
        "invoices": (Invoice, ["id", "invoice_no", "invoice_type", "invoice_date", "grand_total", "status"]),
        "expenses": (Expense, ["id", "amount", "expense_date", "payment_mode", "description"]),
    }

    if data_type not in export_map:
        raise HTTPException(status_code=400, detail=f"Invalid data type. Choose from: {list(export_map.keys())}")

    model, fields = export_map[data_type]
    records = db.query(model).filter(model.user_id == user_id).all()

    export_list = []
    for record in records:
        row = {}
        for field in fields:
            value = getattr(record, field, None)
            if isinstance(value, (datetime, date)):
                value = value.isoformat()
            row[field] = value
        export_list.append(row)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"{data_type}_{timestamp}.json"
    filepath = os.path.join(BACKUP_DIR, filename)

    with open(filepath, "w") as f:
        json.dump(export_list, f, indent=2, default=str)

    return FileResponse(filepath, filename=filename, media_type="application/json")


@router.post("/import")
async def import_data(file: UploadFile = File(...), db: Session = Depends(get_db), user_id: int = Depends(get_current_user)):
    from app.models.accounting import Account
    from app.models.customer import Customer
    from app.models.supplier import Supplier
    from app.models.inventory import Product
    from app.models.invoice import Invoice, InvoiceItem
    from app.models.expense import Expense, ExpenseCategory

    content = await file.read()
    data = json.loads(content)

    if not isinstance(data, list):
        raise HTTPException(status_code=400, detail="Expected a JSON array")

    records_imported = 0
    for row in data:
        model_name = row.pop("_model", None)
        if not model_name:
            continue

        row["user_id"] = user_id
        if "date" in row and isinstance(row["date"], str):
            row["date"] = datetime.strptime(row["date"], "%Y-%m-%d").date()
        if "expense_date" in row and isinstance(row["expense_date"], str):
            row["expense_date"] = datetime.strptime(row["expense_date"], "%Y-%m-%d").date()
        if "invoice_date" in row and isinstance(row["invoice_date"], str):
            row["invoice_date"] = datetime.strptime(row["invoice_date"], "%Y-%m-%d").date()

        model_map = {
            "account": Account, "customer": Customer, "supplier": Supplier,
            "product": Product, "invoice": Invoice, "expense": Expense,
        }
        model_cls = model_map.get(model_name)
        if not model_cls:
            continue

        try:
            obj = model_cls(**row)
            db.add(obj)
            records_imported += 1
        except Exception:
            continue

    db.commit()
    return {
        "message": f"Import completed",
        "records_imported": records_imported,
    }
