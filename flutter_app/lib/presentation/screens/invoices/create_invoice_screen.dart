import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../providers/invoice_provider.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _api = ApiClient();
  final _dateCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
  final _noteCtrl = TextEditingController();
  String _invoiceType = 'Sales';
  int? _customerId;
  List<dynamic> _customers = [];
  List<Map<String, dynamic>> _items = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final res = await _api.get(ApiConstants.customers);
    if (res.statusCode == 200) setState(() => _customers = jsonDecode(res.body));
  }

  void _addItem() {
    setState(() => _items.add({
      'product_id': null, 'description': '',
      'quantity': 1.0, 'rate': 0.0, 'discount_percent': 0.0,
      'cgst_rate': 9.0, 'sgst_rate': 9.0, 'igst_rate': 0.0,
    }));
  }

  double get _subtotal => _items.fold(0.0, (s, i) => s + ((i['quantity'] as num) * (i['rate'] as num)));
  double get _discount => 0;
  double get _taxable => _subtotal - _discount;
  double get _cgst => _items.fold(0.0, (s, i) => s + ((i['quantity'] as num) * (i['rate'] as num) * (i['cgst_rate'] as num) / 100));
  double get _sgst => _items.fold(0.0, (s, i) => s + ((i['quantity'] as num) * (i['rate'] as num) * (i['sgst_rate'] as num) / 100));
  double get _grandTotal => _taxable + _cgst + _sgst;

  Future<void> _save() async {
    setState(() => _loading = true);
    final success = await context.read<InvoiceProvider>().createInvoice({
      'invoice_type': _invoiceType,
      'invoice_date': _dateCtrl.text,
      'customer_id': _customerId,
      'notes': _noteCtrl.text,
      'items': _items,
    });
    setState(() => _loading = false);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice created')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create invoice')));
      }
    }
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Invoice')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField(
            value: _invoiceType,
            items: ['Sales', 'Purchase'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _invoiceType = v!),
            decoration: const InputDecoration(labelText: 'Invoice Type'),
          ),
          const SizedBox(height: 12),
          TextFormField(controller: _dateCtrl, decoration: const InputDecoration(labelText: 'Date', prefixIcon: Icon(Icons.calendar_today)),
            onTap: () async {
              final d = await showDatePicker(context: context, firstDate: DateTime(2000), lastDate: DateTime(2100));
              if (d != null) _dateCtrl.text = d.toIso8601String().substring(0, 10);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField(
            value: _customerId,
            items: _customers.map((c) => DropdownMenuItem(value: c['id'], child: Text(c['name']))).toList(),
            onChanged: (v) => setState(() => _customerId = v as int?),
            decoration: const InputDecoration(labelText: 'Customer'),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Text('Items', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(icon: const Icon(Icons.add), label: const Text('Add Item'), onPressed: _addItem),
          ]),
          ..._items.asMap().entries.map((entry) => Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Description', isDense: true),
                    onChanged: (v) => entry.value['description'] = v,
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextField(
                      decoration: const InputDecoration(labelText: 'Qty', isDense: true),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() => entry.value['quantity'] = double.tryParse(v) ?? 1),
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(
                      decoration: const InputDecoration(labelText: 'Rate', isDense: true),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() => entry.value['rate'] = double.tryParse(v) ?? 0),
                    )),
                  ]),
                ],
              ),
            ),
          )),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _totalRow('Subtotal', _subtotal),
                  _totalRow('Taxable', _taxable),
                  _totalRow('CGST', _cgst),
                  _totalRow('SGST', _sgst),
                  const Divider(),
                  _totalRow('Grand Total', _grandTotal, bold: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(controller: _noteCtrl, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 2),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _save,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create Invoice', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, double amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text('₹${amount.toStringAsFixed(2)}', style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 18 : 14)),
        ],
      ),
    );
  }
}
