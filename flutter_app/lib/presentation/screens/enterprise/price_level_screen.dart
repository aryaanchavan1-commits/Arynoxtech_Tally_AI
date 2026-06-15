import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../providers/enterprise_provider.dart';

class PriceLevelScreen extends StatefulWidget {
  const PriceLevelScreen({super.key});

  @override
  State<PriceLevelScreen> createState() => _PriceLevelScreenState();
}

class _PriceLevelScreenState extends State<PriceLevelScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<EnterpriseProvider>().loadPriceLevels());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnterpriseProvider>(
      builder: (context, ep, _) => Scaffold(
        appBar: AppBar(title: const Text('Price Levels')),
        body: ep.priceLevels.isEmpty
            ? const Center(child: Text('No price levels configured'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: ep.priceLevels.length,
                itemBuilder: (_, i) {
                  final pl = ep.priceLevels[i];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.local_offer)),
                      title: Text(pl['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('Product: ${pl['product_name'] ?? 'All'} | Customer: ${pl['customer_name'] ?? 'All'}'),
                      trailing: Text('₹${(pl['price'] ?? 0).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            final nameCtrl = TextEditingController();
            final priceCtrl = TextEditingController();
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Add Price Level'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name *')),
                  TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
                ]),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  ElevatedButton(onPressed: () async {
                    if (nameCtrl.text.isEmpty) return;
                    await ep.createPriceLevel({'name': nameCtrl.text.trim(), 'price': double.tryParse(priceCtrl.text) ?? 0});
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

extension PriceLevelExt on EnterpriseProvider {
  Future<void> createPriceLevel(Map<String, dynamic> data) async {
    final r = await ApiClient().post('$baseUrl/api/enterprise/price-levels', body: data);
    if (r.statusCode == 200) await loadPriceLevels();
  }
}
