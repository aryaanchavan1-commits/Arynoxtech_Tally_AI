import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/enterprise_provider.dart';

class BankReconciliationScreen extends StatefulWidget {
  const BankReconciliationScreen({super.key});

  @override
  State<BankReconciliationScreen> createState() => _BankReconciliationScreenState();
}

class _BankReconciliationScreenState extends State<BankReconciliationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<EnterpriseProvider>().loadBankTransactions());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnterpriseProvider>(
      builder: (context, ep, _) => Scaffold(
        appBar: AppBar(title: const Text('Bank Reconciliation')),
        body: Column(
          children: [
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(child: _statBox('Total', ep.bankTransactions.length.toString(), Colors.blue)),
                    Expanded(child: _statBox('Reconciled', ep.bankTransactions.where((b) => b['is_reconciled'] == true).length.toString(), AppTheme.successColor)),
                    Expanded(child: _statBox('Pending', ep.bankTransactions.where((b) => b['is_reconciled'] != true).length.toString(), AppTheme.warningColor)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ep.bankTransactions.isEmpty
                  ? const Center(child: Text('No bank transactions'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: ep.bankTransactions.length,
                      itemBuilder: (_, i) {
                        final bt = ep.bankTransactions[i];
                        final isReconciled = bt['is_reconciled'] == true;
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isReconciled ? AppTheme.successColor.withOpacity(0.1) : AppTheme.warningColor.withOpacity(0.1),
                              child: Icon(isReconciled ? Icons.check_circle : Icons.pending, color: isReconciled ? AppTheme.successColor : AppTheme.warningColor),
                            ),
                            title: Text('${bt['transaction_type'] ?? ''} - ₹${(bt['amount'] ?? 0).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${bt['transaction_date'] ?? ''} | ${bt['cheque_no'] ?? 'No cheque'}'),
                            trailing: isReconciled
                                ? const Icon(Icons.check, color: AppTheme.successColor)
                                : TextButton(onPressed: () {
                                    ep.updateChequeStatus(bt['id'], {'status': 'Cleared'}); // simplified
                                  }, child: const Text('Reconcile')),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }
}
