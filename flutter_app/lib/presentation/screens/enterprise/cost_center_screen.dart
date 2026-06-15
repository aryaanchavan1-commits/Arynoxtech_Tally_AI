import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../providers/enterprise_provider.dart';

class CostCenterScreen extends StatefulWidget {
  const CostCenterScreen({super.key});

  @override
  State<CostCenterScreen> createState() => _CostCenterScreenState();
}

class _CostCenterScreenState extends State<CostCenterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EnterpriseProvider>().loadCostCategories();
      context.read<EnterpriseProvider>().loadCostCenters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnterpriseProvider>(
      builder: (context, ep, _) => Scaffold(
        appBar: AppBar(title: const Text('Cost Centers')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (ep.costCategories.isNotEmpty) ...[
              Text('Categories', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ...ep.costCategories.map((c) => Card(child: ListTile(
                leading: const Icon(Icons.category),
                title: Text(c['name'] ?? ''),
              ))),
              const SizedBox(height: 16),
            ],
            Text('Cost Centers', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ...ep.costCenters.map((c) => Card(child: ListTile(
              leading: const Icon(Icons.analytics),
              title: Text(c['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('Category: ${c['category_name'] ?? 'None'}'),
            ))),
          ],
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.small(
              heroTag: 'category',
              onPressed: () {
                final ctrl = TextEditingController();
                showDialog(context: context, builder: (ctx) => AlertDialog(
                  title: const Text('Add Category'), content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Name')),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    ElevatedButton(onPressed: () async { await ep.createCostCategory({'name': ctrl.text.trim()}); if (ctx.mounted) Navigator.pop(ctx); }, child: const Text('Add'))],
                ));
              },
              child: const Icon(Icons.folder, size: 20),
            ),
            const SizedBox(height: 8),
            FloatingActionButton(
              onPressed: () {
                final ctrl = TextEditingController();
                int? catId;
                showDialog(context: context, builder: (ctx) => AlertDialog(
                  title: const Text('Add Cost Center'),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Name *')),
                    if (ep.costCategories.isNotEmpty)
                      DropdownButtonFormField(items: ep.costCategories.map((c) => DropdownMenuItem(value: c['id'], child: Text(c['name']))).toList(),
                        onChanged: (v) => catId = v as int?, decoration: const InputDecoration(labelText: 'Category')),
                  ]),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    ElevatedButton(onPressed: () async {
                      if (ctrl.text.isEmpty) return;
                      await ep.createCostCenter({'name': ctrl.text.trim(), 'category_id': catId});
                      if (ctx.mounted) Navigator.pop(ctx);
                    }, child: const Text('Add'))],
                ));
              },
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}

extension EnterpriseProviderX on EnterpriseProvider {
  Future<void> createCostCenter(Map<String, dynamic> data) async {
    final r = await ApiClient().post('${baseUrl}/api/enterprise/cost-centers', body: data);
    if (r.statusCode == 200) { await loadCostCenters(); }
  }
  Future<void> createCostCategory(Map<String, dynamic> data) async {
    final r = await ApiClient().post('${baseUrl}/api/enterprise/cost-categories', body: data);
    if (r.statusCode == 200) { await loadCostCategories(); }
  }
}
