import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../providers/inventory_provider.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().loadProducts();
      context.read<InventoryProvider>().loadLowStock();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, provider, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Products'),
          actions: [
            IconButton(icon: const Icon(Icons.category), onPressed: () => Navigator.pushNamed(context, AppRoutes.categories)),
            IconButton(icon: const Icon(Icons.warning_amber), onPressed: () => _showLowStock(context, provider.lowStockItems)),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); provider.loadProducts(); })
                      : null,
                ),
                onChanged: (v) => provider.loadProducts(search: v),
              ),
            ),
            if (provider.lowStockItems.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text('${provider.lowStockItems.length} products low in stock', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.products.isEmpty
                      ? const Center(child: Text('No products'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: provider.products.length,
                          itemBuilder: (_, i) {
                            final p = provider.products[i];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(child: Text(p.name[0])),
                                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text('SKU: ${p.sku ?? 'N/A'} | Stock: ${p.currentStock.toStringAsFixed(1)} ${p.unit}'),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('₹${p.sellingPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text('MRP: ₹${p.mrp.toStringAsFixed(2)}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                  ],
                                ),
                                onTap: () => Navigator.pushNamed(context, AppRoutes.productDetail, arguments: p.id),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddProductDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showLowStock(BuildContext context, List<dynamic> items) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Low Stock Alerts'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(items[i]['name'] ?? ''),
              subtitle: Text('Stock: ${items[i]['current_stock']} | Reorder: ${items[i]['reorder_level']}'),
              trailing: const Icon(Icons.warning, color: Colors.orange),
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    final skuCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name *')),
              TextField(controller: skuCtrl, decoration: const InputDecoration(labelText: 'SKU')),
              TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Selling Price'), keyboardType: TextInputType.number),
              TextField(controller: stockCtrl, decoration: const InputDecoration(labelText: 'Opening Stock'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            if (nameCtrl.text.isEmpty) return;
            await context.read<InventoryProvider>().createProduct({
              'name': nameCtrl.text.trim(),
              'sku': skuCtrl.text.trim(),
              'selling_price': double.tryParse(priceCtrl.text) ?? 0,
              'opening_stock': double.tryParse(stockCtrl.text) ?? 0,
            });
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: const Text('Save')),
        ],
      ),
    );
  }
}
