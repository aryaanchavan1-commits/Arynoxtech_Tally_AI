import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/routes/app_routes.dart';
import '../../providers/customer_provider.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<CustomerProvider>().loadCustomers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerProvider>(
      builder: (context, provider, _) => Scaffold(
        appBar: AppBar(title: const Text('Customers')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search customers...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); provider.loadCustomers(); })
                      : null,
                ),
                onChanged: (v) => provider.loadCustomers(search: v),
              ),
            ),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.customers.isEmpty
                      ? const Center(child: Text('No customers found'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: provider.customers.length,
                          itemBuilder: (_, i) {
                            final c = provider.customers[i];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(child: Text(c.name[0])),
                                title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text('${c.mobile ?? c.email ?? ''} | Balance: ₹${c.currentBalance.toStringAsFixed(2)}'),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('₹${c.outstandingAmount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: c.outstandingAmount > 0 ? Colors.red : Colors.green)),
                                    Text('Due', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                  ],
                                ),
                                onTap: () => Navigator.pushNamed(context, AppRoutes.customerDetail, arguments: c.id),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddCustomerDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final gstCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Customer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name *')),
              TextField(controller: mobileCtrl, decoration: const InputDecoration(labelText: 'Mobile'), keyboardType: TextInputType.phone),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'City')),
              TextField(controller: gstCtrl, decoration: const InputDecoration(labelText: 'GSTIN')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            if (nameCtrl.text.isEmpty) return;
            await context.read<CustomerProvider>().createCustomer({
              'name': nameCtrl.text.trim(),
              'mobile': mobileCtrl.text.trim(),
              'email': emailCtrl.text.trim(),
              'city': cityCtrl.text.trim(),
              'gstin': gstCtrl.text.trim(),
            });
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: const Text('Save')),
        ],
      ),
    );
  }
}
