import os
from datetime import datetime
from jinja2 import Template
from app.config import settings


def generate_invoice_pdf(invoice, db):
    from app.models.invoice import InvoiceItem
    from app.models.customer import Customer

    items = db.query(InvoiceItem).filter(InvoiceItem.invoice_id == invoice.id).all()
    customer = db.query(Customer).filter(Customer.id == invoice.customer_id).first() if invoice.customer_id else None

    pdf_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "invoices")
    os.makedirs(pdf_dir, exist_ok=True)
    filename = f"Invoice_{invoice.invoice_no}.html"
    filepath = os.path.join(pdf_dir, filename)

    template_str = """<!DOCTYPE html>
<html>
<head>
<style>
  body { font-family: Arial, sans-serif; margin: 40px; }
  .header { text-align: center; margin-bottom: 30px; }
  .header h1 { color: #1a237e; margin: 0; font-size: 24px; }
  .header h2 { color: #333; margin: 5px 0; font-size: 18px; }
  .invoice-title { text-align: center; font-size: 22px; font-weight: bold; margin: 20px 0; color: #1a237e; }
  .info-table { width: 100%; margin-bottom: 20px; }
  .info-table td { padding: 5px; vertical-align: top; }
  table.items { width: 100%; border-collapse: collapse; margin: 20px 0; }
  table.items th { background: #1a237e; color: white; padding: 10px; text-align: left; }
  table.items td { padding: 8px; border-bottom: 1px solid #ddd; }
  table.items tr:nth-child(even) { background: #f5f5f5; }
  .totals { width: 300px; margin-left: auto; }
  .totals td { padding: 5px; }
  .totals .grand { font-size: 18px; font-weight: bold; color: #1a237e; }
  .footer { margin-top: 40px; text-align: center; font-size: 12px; color: #666; }
  .status { color: #e65100; font-weight: bold; }
  .company-details { margin-bottom: 20px; }
</style>
</head>
<body>
<div class="header">
  <h1>{{ company }}</h1>
  <h2>AI-Powered Smart Accounting for Small Businesses</h2>
  <p>Owner: {{ owner }}</p>
</div>

<div class="invoice-title">TAX INVOICE</div>

<table class="info-table">
<tr><td><strong>Invoice No:</strong> {{ invoice.invoice_no }}</td>
    <td><strong>Date:</strong> {{ invoice.invoice_date }}</td></tr>
{% if invoice.due_date %}
<tr><td><strong>Due Date:</strong> {{ invoice.due_date }}</td>
    <td><strong>Status:</strong> <span class="status">{{ invoice.status }}</span></td></tr>
{% endif %}
</table>

{% if customer %}
<div class="company-details">
<strong>Bill To:</strong><br>
{{ customer.name }}<br>
{% if customer.company_name %}{{ customer.company_name }}<br>{% endif %}
{% if customer.address %}{{ customer.address }}<br>{% endif %}
{% if customer.city or customer.state %}{{ customer.city }}{% if customer.city and customer.state %}, {% endif %}{{ customer.state }}<br>{% endif %}
{% if customer.gstin %}<strong>GSTIN:</strong> {{ customer.gstin }}{% endif %}
</div>
{% endif %}

<table class="items">
<tr>
  <th>#</th>
  <th>Description</th>
  <th>Qty</th>
  <th>Rate</th>
  <th>Discount</th>
  <th>Taxable</th>
  <th>Total</th>
</tr>
{% for item in items %}
<tr>
  <td>{{ loop.index }}</td>
  <td>{{ item.description or item.product.name if item.product else 'Item' }}</td>
  <td>{{ item.quantity }}</td>
  <td>{{ "%.2f"|format(item.rate) }}</td>
  <td>{{ "%.2f"|format(item.discount_amount) }}</td>
  <td>{{ "%.2f"|format(item.taxable_value) }}</td>
  <td>{{ "%.2f"|format(item.total) }}</td>
</tr>
{% endfor %}
</table>

<table class="totals">
<tr><td>Subtotal:</td><td align="right">{{ "%.2f"|format(invoice.subtotal) }}</td></tr>
<tr><td>Discount:</td><td align="right">{{ "%.2f"|format(invoice.discount_amount) }}</td></tr>
<tr><td>Taxable Amount:</td><td align="right">{{ "%.2f"|format(invoice.taxable_amount) }}</td></tr>
{% if invoice.cgst_amount > 0 %}
<tr><td>CGST @ {{ "%.2f"|format(invoice.cgst_rate) }}%:</td><td align="right">{{ "%.2f"|format(invoice.cgst_amount) }}</td></tr>
{% endif %}
{% if invoice.sgst_amount > 0 %}
<tr><td>SGST @ {{ "%.2f"|format(invoice.sgst_rate) }}%:</td><td align="right">{{ "%.2f"|format(invoice.sgst_amount) }}</td></tr>
{% endif %}
{% if invoice.igst_amount > 0 %}
<tr><td>IGST @ {{ "%.2f"|format(invoice.igst_rate) }}%:</td><td align="right">{{ "%.2f"|format(invoice.igst_amount) }}</td></tr>
{% endif %}
<tr><td>Shipping:</td><td align="right">{{ "%.2f"|format(invoice.shipping_charge) }}</td></tr>
<tr class="grand"><td>Grand Total:</td><td align="right">{{ "%.2f"|format(invoice.grand_total) }}</td></tr>
</table>

{% if invoice.terms_conditions %}
<div style="margin-top:20px">
  <strong>Terms & Conditions:</strong><br>
  {{ invoice.terms_conditions }}
</div>
{% endif %}

{% if invoice.notes %}
<div style="margin-top:10px">
  <strong>Notes:</strong><br>
  {{ invoice.notes }}
</div>
{% endif %}

<div class="footer">
  <p>This is a computer-generated invoice</p>
  <p>{{ company }} - {{ tagline }}</p>
</div>
</body>
</html>"""

    template = Template(template_str)
    html_content = template.render(
        company=settings.COMPANY,
        owner=settings.OWNER,
        tagline=settings.TAGLINE,
        invoice=invoice,
        customer=customer,
        items=items,
    )

    with open(filepath, "w", encoding="utf-8") as f:
        f.write(html_content)

    try:
        from weasyprint import HTML
        pdf_path = filepath.replace(".html", ".pdf")
        HTML(filename=filepath).write_pdf(pdf_path)
        return pdf_path
    except ImportError:
        return filepath
