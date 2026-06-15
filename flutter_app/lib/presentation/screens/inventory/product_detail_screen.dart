import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import 'dart:convert';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _api = ApiClient();
  Map<String, dynamic>? _product;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await _api.get('${ApiConstants.inventoryProducts}/${widget.productId}');
    if (res.statusCode == 200 && mounted) setState(() { _product = jsonDecode(res.body); _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: AppBar(title: const Text('Product')), body: const Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: Text(_product?['name'] ?? 'Product')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _row('SKU', _product?['sku'] ?? 'N/A'),
                  _row('Barcode', _product?['barcode'] ?? 'N/A'),
                  _row('Category', _product?['category_name'] ?? 'N/A'),
                  _row('Unit', _product?['unit'] ?? 'Pieces'),
                  const Divider(),
                  _row('Purchase Price', '₹${(_product?['purchase_price'] ?? 0).toStringAsFixed(2)}'),
                  _row('Selling Price', '₹${(_product?['selling_price'] ?? 0).toStringAsFixed(2)}'),
                  _row('MRP', '₹${(_product?['mrp'] ?? 0).toStringAsFixed(2)}'),
                  _row('GST', '${_product?['gst_rate'] ?? 0}%'),
                  const Divider(),
                  _row('Current Stock', '${_product?['current_stock'] ?? 0}', valueColor: (_product?['current_stock'] ?? 0) <= (_product?['reorder_level'] ?? 0) ? Colors.red : Colors.green),
                  _row('Reorder Level', '${_product?['reorder_level'] ?? 0}'),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: valueColor)),
        ],
      ),
    );
  }
}
