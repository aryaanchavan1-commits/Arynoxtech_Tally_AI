import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/enterprise_provider.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<EnterpriseProvider>().loadBudgets());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnterpriseProvider>(
      builder: (context, ep, _) => Scaffold(
        appBar: AppBar(title: const Text('Budgets')),
        body: ep.budgets.isEmpty
            ? const Center(child: Text('No budgets created'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: ep.budgets.length,
                itemBuilder: (_, i) {
                  final b = ep.budgets[i];
                  final overBudget = (b['variance'] ?? 0) < 0;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(child: Text(b['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                            Chip(label: Text(b['financial_year'] ?? '', style: const TextStyle(fontSize: 10))),
                          ]),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: (b['budgeted_amount'] ?? 0) > 0 ? ((b['actual_amount'] ?? 0) / (b['budgeted_amount'] ?? 1)).clamp(0, 1) : 0,
                            color: overBudget ? AppTheme.errorColor : AppTheme.successColor,
                            backgroundColor: Colors.grey[200],
                          ),
                          const SizedBox(height: 8),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text('Budget: ₹${(b['budgeted_amount'] ?? 0).toStringAsFixed(2)}', style: TextStyle(color: Colors.grey[600])),
                            Text('Actual: ₹${(b['actual_amount'] ?? 0).toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w600, color: overBudget ? AppTheme.errorColor : AppTheme.successColor)),
                          ]),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text('Variance: ₹${(b['variance'] ?? 0).toStringAsFixed(2)}', style: TextStyle(color: overBudget ? AppTheme.errorColor : AppTheme.successColor)),
                            Text('${(b['variance_pct'] ?? 0).toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold, color: overBudget ? AppTheme.errorColor : AppTheme.successColor)),
                          ]),
                        ],
                      ),
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            final nameCtrl = TextEditingController();
            final fyCtrl = TextEditingController(text: '${DateTime.now().year}-${DateTime.now().year + 1}');
            final amountCtrl = TextEditingController();

            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Create Budget'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name *')),
                    TextField(controller: fyCtrl, decoration: const InputDecoration(labelText: 'Financial Year')),
                    TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Budgeted Amount'), keyboardType: TextInputType.number),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  ElevatedButton(onPressed: () async {
                    if (nameCtrl.text.isEmpty || amountCtrl.text.isEmpty) return;
                    await context.read<EnterpriseProvider>().createBudget({
                      'name': nameCtrl.text.trim(), 'financial_year': fyCtrl.text.trim(),
                      'budgeted_amount': double.tryParse(amountCtrl.text) ?? 0,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                  }, child: const Text('Create')),
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
