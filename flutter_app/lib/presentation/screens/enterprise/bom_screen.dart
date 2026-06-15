import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../providers/enterprise_provider.dart';
import '../../providers/inventory_provider.dart';

class BOMScreen extends StatefulWidget {
  const BOMScreen({super.key});

  @override
  State<BOMScreen> createState() => _BOMScreenState();
}

class _BOMScreenState extends State<BOMScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EnterpriseProvider>().loadBOM();
      context.read<InventoryProvider>().loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnterpriseProvider>(
      builder: (context, ep, _) => Scaffold(
        appBar: AppBar(title: const Text('Bill of Materials')),
        body: ep.bom.isEmpty
            ? const Center(child: Text('No BOM defined'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: ep.bom.length,
                itemBuilder: (_, i) {
                  final b = ep.bom[i];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.precision_manufacturing)),
                      title: Text('${b['finished_product_name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('Raw: ${b['raw_product_name']} | Qty: ${b['quantity_required']} | Waste: ${b['wastage_pct']}%'),
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            int? finishedId;
            int? rawId;
            final qtyCtrl = TextEditingController(text: '1');
            final inv = context.read<InventoryProvider>();

            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Add BOM'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  DropdownButtonFormField(items: inv.products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                    onChanged: (v) => finishedId = v as int?, decoration: const InputDecoration(labelText: 'Finished Product *')),
                  DropdownButtonFormField(items: inv.products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                    onChanged: (v) => rawId = v as int?, decoration: const InputDecoration(labelText: 'Raw Material *')),
                  TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Quantity Required'), keyboardType: TextInputType.number),
                ]),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  ElevatedButton(onPressed: () async {
                    if (finishedId == null || rawId == null) return;
                    await ep.createBOM({
                      'finished_product_id': finishedId, 'raw_product_id': rawId,
                      'quantity_required': double.tryParse(qtyCtrl.text) ?? 1,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                  }, child: const Text('Add')),
                ],
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

extension BOMExt on EnterpriseProvider {
  Future<void> createBOM(Map<String, dynamic> data) async {
    final r = await ApiClient().post('$baseUrl/api/enterprise/bom', body: data);
    if (r.statusCode == 200) await loadBOM();
  }
}
