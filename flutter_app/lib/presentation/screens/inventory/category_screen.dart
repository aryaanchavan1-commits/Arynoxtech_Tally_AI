import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventory_provider.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<InventoryProvider>().loadCategories());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, provider, _) => Scaffold(
        appBar: AppBar(title: const Text('Categories')),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.categories.length,
          itemBuilder: (_, i) {
            final c = provider.categories[i];
            return Card(child: ListTile(
              leading: const Icon(Icons.folder),
              title: Text(c['name'] ?? ''),
              subtitle: Text(c['description'] ?? ''),
            ));
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            final ctrl = TextEditingController();
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Add Category'),
                content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Name')),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  ElevatedButton(onPressed: () async {
                    await provider.createCategory({'name': ctrl.text.trim()});
                    if (ctx.mounted) Navigator.pop(ctx);
                  }, child: const Text('Save')),
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
