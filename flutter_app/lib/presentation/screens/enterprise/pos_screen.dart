import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../providers/enterprise_provider.dart';
import '../../providers/inventory_provider.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  final _api = ApiClient();
  List<Map<String, dynamic>> _cart = [];
  double _total = 0;
  double _cashReceived = 0;
  double _changeDue = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().loadProducts();
      context.read<EnterpriseProvider>().loadActivePosSession();
    });
  }

  void _addToCart(dynamic product) {
    setState(() {
      _cart.add({
        'product_id': product['id'],
        'name': product['name'],
        'quantity': 1.0,
        'rate': (product['selling_price'] ?? 0).toDouble(),
        'total': (product['selling_price'] ?? 0).toDouble(),
      });
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    _total = _cart.fold(0.0, (s, i) => s + (i['total'] as double));
    _changeDue = _cashReceived - _total;
  }

  Future<void> _completeSale() async {
    if (_cart.isEmpty) return;
    final ep = context.read<EnterpriseProvider>();

    if (ep.activePosSession == null) {
      final result = await ep.openPosSession(0);
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to open POS session')));
        return;
      }
    }

    final invoiceData = {
      'invoice_type': 'Sales',
      'invoice_date': DateTime.now().toIso8601String().substring(0, 10),
      'items': _cart.map((i) => {
        'product_id': i['product_id'],
        'description': i['name'],
        'quantity': i['quantity'],
        'rate': i['rate'],
      }).toList(),
    };

    final r = await _api.post(ApiConstants.invoices, body: invoiceData);
    if (r.statusCode == 201) {
      setState(() { _cart.clear(); _total = 0; _cashReceived = 0; _changeDue = 0; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sale completed!'), backgroundColor: AppTheme.successColor));
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Point of Sale')),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search products (Alt+P)',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (v) => inv.loadProducts(search: v),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, childAspectRatio: 1.2, crossAxisSpacing: 8, mainAxisSpacing: 8,
                    ),
                    itemCount: inv.products.length,
                    itemBuilder: (_, i) {
                      final p = inv.products[i];
                      return Card(
                        child: InkWell(
                          onTap: () => _addToCart({
                            'id': p.id, 'name': p.name, 'selling_price': p.sellingPrice,
                          }),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(p.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text('₹${p.sellingPrice.toStringAsFixed(2)}', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
                                Text('Stock: ${p.currentStock.toStringAsFixed(0)}', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 350,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(left: BorderSide(color: Colors.grey.withOpacity(0.2))),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  color: AppTheme.primaryColor,
                  child: const Text('Current Sale', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Expanded(
                  child: _cart.isEmpty
                      ? const Center(child: Text('No items in cart'))
                      : ListView.builder(
                          itemCount: _cart.length,
                          itemBuilder: (_, i) {
                            final item = _cart[i];
                            return Dismissible(
                              key: Key('$i'),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) { setState(() { _cart.removeAt(i); _calculateTotal(); }); },
                              background: Container(color: AppTheme.errorColor, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.delete, color: Colors.white)),
                              child: ListTile(
                                title: Text(item['name'] ?? ''),
                                subtitle: Text('${item['quantity']} x ₹${(item['rate'] as double).toStringAsFixed(2)}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () {
                                      setState(() {
                                        if (item['quantity'] > 1) { item['quantity']--; item['total'] = item['quantity'] * item['rate']; _calculateTotal(); }
                                      });
                                    }),
                                    Text('${item['quantity']}'),
                                    IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () {
                                      setState(() { item['quantity']++; item['total'] = item['quantity'] * item['rate']; _calculateTotal(); });
                                    }),
                                    Text('₹${(item['total'] as double).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                dense: true,
                              ),
                            );
                          },
                        ),
                ),
                const Divider(height: 1),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('₹${_total.toStringAsFixed(2)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                      ]),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(labelText: 'Cash Received', prefixText: '₹ '),
                        keyboardType: TextInputType.number,
                        onChanged: (v) { _cashReceived = double.tryParse(v) ?? 0; _calculateTotal(); setState(() {}); },
                      ),
                      if (_changeDue > 0)
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Change:'),
                          Text('₹${_changeDue.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successColor)),
                        ]),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.shopping_cart_checkout),
                          label: Text('Complete Sale (F8)', style: const TextStyle(fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppTheme.successColor,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _cart.isEmpty ? null : _completeSale,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
