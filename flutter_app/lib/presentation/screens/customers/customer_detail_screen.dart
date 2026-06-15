import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/customer_provider.dart';

class CustomerDetailScreen extends StatefulWidget {
  final int customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await context.read<CustomerProvider>().getCustomerStatement(widget.customerId);
    if (mounted) setState(() { _data = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: AppBar(title: const Text('Customer')), body: const Center(child: CircularProgressIndicator()));

    final customer = _data?['customer'];
    final statement = (_data?['statement'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(customer?['name'] ?? 'Customer')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Balance: ₹${(_data?['current_balance'] ?? 0).toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text('Outstanding: ₹${(_data?['outstanding'] ?? 0).toStringAsFixed(2)}', style: TextStyle(color: Colors.red, fontSize: 16)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Transactions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ...statement.map((s) => Card(
            child: ListTile(
              title: Text('${s['voucher_no']} (${s['type']})'),
              subtitle: Text(s['date'] ?? ''),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if ((s['debit'] ?? 0) > 0) Text('-₹${(s['debit'] as num).toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  if ((s['credit'] ?? 0) > 0) Text('+₹${(s['credit'] as num).toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  Text('Bal: ₹${(s['balance'] as num).toStringAsFixed(2)}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}
