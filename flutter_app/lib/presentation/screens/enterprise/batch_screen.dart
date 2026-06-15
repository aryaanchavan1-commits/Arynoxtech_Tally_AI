import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/enterprise_provider.dart';
import '../../providers/inventory_provider.dart';

class BatchScreen extends StatefulWidget {
  const BatchScreen({super.key});

  @override
  State<BatchScreen> createState() => _BatchScreenState();
}

class _BatchScreenState extends State<BatchScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EnterpriseProvider>().loadBatches();
      context.read<InventoryProvider>().loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ep = context.watch<EnterpriseProvider>();
    final inv = context.watch<InventoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch & Expiry'),
        actions: [
          IconButton(icon: const Icon(Icons.warning_amber), onPressed: () async {
            final batches = await ep.getExpiringBatches(30);
            if (!mounted) return;
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Expiring Soon (30 days)'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: batches.length,
                    itemBuilder: (_, i) {
                      final b = batches[i];
                      return ListTile(
                        title: Text(b['product_name'] ?? ''),
                        subtitle: Text('Batch: ${b['batch_no']} | Exp: ${b['expiry_date']} | Qty: ${b['quantity']}'),
                        trailing: const Icon(Icons.warning, color: Colors.orange),
                      );
                    },
                  ),
                ),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
              ),
            );
          }),
        ],
      ),
      body: ep.batches.isEmpty
          ? const Center(child: Text('No batches'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ep.batches.length,
              itemBuilder: (_, i) {
                final b = ep.batches[i];
                final isExpiring = b['expiry_date'] != null;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isExpiring ? AppTheme.warningColor.withOpacity(0.1) : AppTheme.successColor.withOpacity(0.1),
                      child: Icon(Icons.inventory, color: isExpiring ? AppTheme.warningColor : AppTheme.successColor),
                    ),
                    title: Text(b['product_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Batch: ${b['batch_no']}\nExp: ${b['expiry_date'] ?? 'N/A'} | Qty: ${b['quantity']}'),
                    isThreeLine: true,
                    trailing: Text('₹${(b['mrp'] ?? 0).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final batchCtrl = TextEditingController();
          final mfgCtrl = TextEditingController();
          final expCtrl = TextEditingController();
          final qtyCtrl = TextEditingController();
          int? productId;

          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Add Batch'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField(
                      items: inv.products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                      onChanged: (v) => productId = v as int?,
                      decoration: const InputDecoration(labelText: 'Product *'),
                    ),
                    TextField(controller: batchCtrl, decoration: const InputDecoration(labelText: 'Batch No *')),
                    TextField(controller: mfgCtrl, decoration: const InputDecoration(labelText: 'Manufacturing Date (YYYY-MM-DD)')),
                    TextField(controller: expCtrl, decoration: const InputDecoration(labelText: 'Expiry Date (YYYY-MM-DD)')),
                    TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(onPressed: () async {
                  if (productId == null || batchCtrl.text.isEmpty) return;
                  await context.read<EnterpriseProvider>().createBatch({
                    'product_id': productId, 'batch_no': batchCtrl.text.trim(),
                    'manufacturing_date': mfgCtrl.text.trim(),
                    'expiry_date': expCtrl.text.trim(),
                    'quantity': double.tryParse(qtyCtrl.text) ?? 0,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                }, child: const Text('Save')),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
