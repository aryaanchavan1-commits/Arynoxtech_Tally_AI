import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../providers/supplier_provider.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<SupplierProvider>().loadSuppliers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SupplierProvider>(
      builder: (context, provider, _) => Scaffold(
        appBar: AppBar(title: const Text('Suppliers')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search suppliers...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); provider.loadSuppliers(); })
                      : null,
                ),
                onChanged: (v) => provider.loadSuppliers(search: v),
              ),
            ),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.suppliers.isEmpty
                      ? const Center(child: Text('No suppliers'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: provider.suppliers.length,
                          itemBuilder: (_, i) {
                            final s = provider.suppliers[i];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(child: Text(s.name[0])),
                                title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text('${s.mobile ?? s.email ?? ''}'),
                                trailing: Text('₹${s.outstandingAmount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: s.outstandingAmount > 0 ? Colors.orange : Colors.green)),
                                onTap: () => Navigator.pushNamed(context, AppRoutes.supplierDetail, arguments: s.id),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddSupplierDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showAddSupplierDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Supplier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name *')),
            TextField(controller: mobileCtrl, decoration: const InputDecoration(labelText: 'Mobile'), keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            if (nameCtrl.text.isEmpty) return;
            await context.read<SupplierProvider>().createSupplier({'name': nameCtrl.text.trim(), 'mobile': mobileCtrl.text.trim()});
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: const Text('Save')),
        ],
      ),
    );
  }
}
