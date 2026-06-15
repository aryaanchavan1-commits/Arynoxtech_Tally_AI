from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware
from contextlib import asynccontextmanager
from app.database import init_db
from app.config import settings
import re
from app.routes.auth import router as auth_router
from app.routes.accounts import router as accounts_router
from app.routes.vouchers import router as vouchers_router
from app.routes.reports import router as reports_router
from app.routes.customers import router as customers_router
from app.routes.suppliers import router as suppliers_router
from app.routes.inventory import router as inventory_router
from app.routes.invoices import router as invoices_router
from app.routes.expenses import router as expenses_router
from app.routes.dashboard import router as dashboard_router
from app.routes.ai_assistant import router as ai_router
from app.routes.backup import router as backup_router
from app.routes.search import router as search_router
from app.routes.enterprise import router as enterprise_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    yield


app = FastAPI(
    title=settings.APP_NAME,
    description=settings.TAGLINE,
    version="2.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

routers = [
    auth_router, accounts_router, vouchers_router, reports_router,
    customers_router, suppliers_router, inventory_router, invoices_router,
    expenses_router, dashboard_router, ai_router, backup_router,
    search_router, enterprise_router,
]
for r in routers:
    app.include_router(r)


@app.get("/")
def root():
    return {
        "app": settings.APP_NAME,
        "owner": settings.OWNER,
        "company": settings.COMPANY,
        "tagline": settings.TAGLINE,
        "version": "2.0.0",
    }


@app.get("/health")
def health_check():
    return {"status": "healthy", "timestamp": "ok"}
