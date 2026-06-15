import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/account_provider.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  String _selectedGroup = AppConstants.accountGroups.first;
  String _selectedType = 'Assets';

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await context.read<AccountProvider>().createAccount({
      'name': _nameController.text.trim(),
      'group_name': _selectedGroup,
      'account_type': _selectedType,
      'opening_balance': double.tryParse(_balanceController.text) ?? 0,
    });
    if (mounted) {
      if (success) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Account created' : 'Failed to create')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Account Name'), validator: (v) => v?.isEmpty == true ? 'Required' : null),
            const SizedBox(height: 16),
            DropdownButtonFormField(value: _selectedGroup, items: AppConstants.accountGroups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(), onChanged: (v) => setState(() => _selectedGroup = v!), decoration: const InputDecoration(labelText: 'Group')),
            const SizedBox(height: 16),
            DropdownButtonFormField(value: _selectedType, items: ['Assets', 'Liabilities', 'Equity', 'Income', 'Expenses', 'Bank', 'Cash'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => _selectedType = v!), decoration: const InputDecoration(labelText: 'Type')),
            const SizedBox(height: 16),
            TextFormField(controller: _balanceController, decoration: const InputDecoration(labelText: 'Opening Balance'), keyboardType: TextInputType.number),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _save, child: const Text('Create Account')),
          ],
        ),
      ),
    );
  }
}
