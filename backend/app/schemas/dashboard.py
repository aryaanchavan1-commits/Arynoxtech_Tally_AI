from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


class DashboardSummary(BaseModel):
    total_revenue: float
    total_expenses: float
    net_profit: float
    cash_position: float
    total_receivables: float
    total_payables: float
    total_customers: int
    total_suppliers: int
    total_products: int
    low_stock_count: int
    total_invoices: int
    pending_invoices: int


class RevenueChartData(BaseModel):
    labels: List[str]
    values: List[float]


class DashboardData(BaseModel):
    summary: DashboardSummary
    revenue_chart: RevenueChartData
    expense_chart: RevenueChartData
    top_customers: List[dict]
    top_products: List[dict]
