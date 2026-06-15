class InvoiceModel {
  final int id;
  final String invoiceNo;
  final String invoiceType;
  final String invoiceDate;
  final String? dueDate;
  final int? customerId;
  final String? customerName;
  final double subtotal;
  final double discountAmount;
  final double taxableAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double totalTax;
  final double shippingCharge;
  final double grandTotal;
  final double paidAmount;
  final double balanceAmount;
  final String status;

  InvoiceModel({
    required this.id,
    required this.invoiceNo,
    required this.invoiceType,
    required this.invoiceDate,
    this.dueDate,
    this.customerId,
    this.customerName,
    required this.subtotal,
    required this.discountAmount,
    required this.taxableAmount,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.totalTax,
    required this.shippingCharge,
    required this.grandTotal,
    required this.paidAmount,
    required this.balanceAmount,
    required this.status,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'],
      invoiceNo: json['invoice_no'],
      invoiceType: json['invoice_type'],
      invoiceDate: json['invoice_date'],
      dueDate: json['due_date'],
      customerId: json['customer_id'],
      customerName: json['customer_name'],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      discountAmount: (json['discount_amount'] ?? 0).toDouble(),
      taxableAmount: (json['taxable_amount'] ?? 0).toDouble(),
      cgstAmount: (json['cgst_amount'] ?? 0).toDouble(),
      sgstAmount: (json['sgst_amount'] ?? 0).toDouble(),
      igstAmount: (json['igst_amount'] ?? 0).toDouble(),
      totalTax: (json['total_tax'] ?? 0).toDouble(),
      shippingCharge: (json['shipping_charge'] ?? 0).toDouble(),
      grandTotal: (json['grand_total'] ?? 0).toDouble(),
      paidAmount: (json['paid_amount'] ?? 0).toDouble(),
      balanceAmount: (json['balance_amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'Unpaid',
    );
  }
}
