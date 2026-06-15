import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/expense_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _dateCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
  final _refCtrl = TextEditingController();
  int? _categoryId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ExpenseProvider>().loadCategories());
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _dateCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_categoryId == null || _amountCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    final success = await context.read<ExpenseProvider>().createExpense({
      'category_id': _categoryId,
      'amount': double.tryParse(_amountCtrl.text) ?? 0,
      'expense_date': _dateCtrl.text,
      'description': _descCtrl.text,
      'reference_no': _refCtrl.text,
    });
    setState(() => _loading = false);
    if (mounted) {
      if (success) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Expense added' : 'Failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ExpenseProvider>().categories;
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField(
            value: _categoryId,
            items: categories.map((c) => DropdownMenuItem(value: c['id'], child: Text(c['name']))).toList(),
            onChanged: (v) => setState(() => _categoryId = v as int?),
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          const SizedBox(height: 12),
          TextFormField(controller: _amountCtrl, decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ '), keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          TextFormField(controller: _dateCtrl, decoration: const InputDecoration(labelText: 'Date', prefixIcon: Icon(Icons.calendar_today)),
            onTap: () async {
              final d = await showDatePicker(context: context, firstDate: DateTime(2000), lastDate: DateTime(2100));
              if (d != null) _dateCtrl.text = d.toIso8601String().substring(0, 10);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(controller: _refCtrl, decoration: const InputDecoration(labelText: 'Reference No.')),
          const SizedBox(height: 12),
          TextFormField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _save,
            child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save Expense'),
          ),
        ],
      ),
    );
  }
}
