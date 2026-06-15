import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../providers/expense_provider.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadExpenses();
      context.read<ExpenseProvider>().loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Expenses'),
          actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => Navigator.pushNamed(context, AppRoutes.addExpense))],
        ),
        body: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.expenses.isEmpty
                ? const Center(child: Text('No expenses'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.expenses.length,
                    itemBuilder: (_, i) {
                      final e = provider.expenses[i];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: AppTheme.errorColor.withOpacity(0.1), child: const Icon(Icons.money_off, color: AppTheme.errorColor)),
                          title: Text(e['category_name'] ?? 'Expense', style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${e['expense_date']} | ${e['description'] ?? ''}'),
                          trailing: Text('₹${(e['amount'] ?? 0).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.errorColor)),
                        ),
                      );
                    },
                  ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.addExpense),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
