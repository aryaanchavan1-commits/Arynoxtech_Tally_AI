import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/enterprise_provider.dart';

class GodownScreen extends StatefulWidget {
  const GodownScreen({super.key});

  @override
  State<GodownScreen> createState() => _GodownScreenState();
}

class _GodownScreenState extends State<GodownScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<EnterpriseProvider>().loadGodowns());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnterpriseProvider>(
      builder: (context, ep, _) => Scaffold(
        appBar: AppBar(title: const Text('Godowns / Warehouses')),
        body: ep.godowns.isEmpty
            ? const Center(child: Text('No godowns configured'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: ep.godowns.length,
                itemBuilder: (_, i) {
                  final g = ep.godowns[i];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.warehouse)),
                      title: Text(g['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${g['city'] ?? ''} ${g['state'] ?? ''}'),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            final nameCtrl = TextEditingController();
            final cityCtrl = TextEditingController();
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Add Godown'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name *')),
                    TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'City')),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  ElevatedButton(onPressed: () async {
                    if (nameCtrl.text.isEmpty) return;
                    await context.read<EnterpriseProvider>().createGodown({
                      'name': nameCtrl.text.trim(), 'city': cityCtrl.text.trim(),
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
