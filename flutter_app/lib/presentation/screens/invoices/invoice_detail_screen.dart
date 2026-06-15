import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final int invoiceId;
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  final _api = ApiClient();
  Map<String, dynamic>? _invoice;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await _api.get('${ApiConstants.invoices}/${widget.invoiceId}');
    if (res.statusCode == 200 && mounted) setState(() { _invoice = jsonDecode(res.body); _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: AppBar(title: const Text('Invoice')), body: const Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text('#${_invoice?['invoice_no'] ?? ''}'),
        actions: [IconButton(icon: const Icon(Icons.print), onPressed: () {}), IconButton(icon: const Icon(Icons.download), onPressed: () {})],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('₹${(_invoice?['grand_total'] ?? 0).toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Chip(label: Text(_invoice?['status'] ?? ''), backgroundColor: Colors.blue.withOpacity(0.1)),
                const SizedBox(height: 16),
                _row('Invoice No', _invoice?['invoice_no'] ?? ''),
                _row('Date', _invoice?['invoice_date'] ?? ''),
                _row('Customer', _invoice?['customer_name'] ?? 'N/A'),
                _row('Subtotal', '₹${(_invoice?['subtotal'] ?? 0).toStringAsFixed(2)}'),
                _row('CGST', '₹${(_invoice?['cgst_amount'] ?? 0).toStringAsFixed(2)}'),
                _row('SGST', '₹${(_invoice?['sgst_amount'] ?? 0).toStringAsFixed(2)}'),
                _row('Grand Total', '₹${(_invoice?['grand_total'] ?? 0).toStringAsFixed(2)}', bold: true),
                _row('Paid', '₹${(_invoice?['paid_amount'] ?? 0).toStringAsFixed(2)}'),
                _row('Balance', '₹${(_invoice?['balance_amount'] ?? 0).toStringAsFixed(2)}'),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      ]),
    );
  }
}
