import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/enterprise_provider.dart';

class ChequeScreen extends StatefulWidget {
  const ChequeScreen({super.key});

  @override
  State<ChequeScreen> createState() => _ChequeScreenState();
}

class _ChequeScreenState extends State<ChequeScreen> {
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<EnterpriseProvider>().loadCheques());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnterpriseProvider>(
      builder: (context, ep, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Cheque Management'),
          actions: [IconButton(icon: const Icon(Icons.print), onPressed: () {})],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Issued', 'Deposited', 'Cleared', 'Bounced'].map((f) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(label: Text(f), selected: _statusFilter == f, onSelected: (v) {
                      setState(() => _statusFilter = f);
                      ep.loadCheques(status: f == 'All' ? null : f);
                    }),
                  )).toList(),
                ),
              ),
            ),
            Expanded(
              child: ep.cheques.isEmpty
                  ? const Center(child: Text('No cheques'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: ep.cheques.length,
                      itemBuilder: (_, i) {
                        final ch = ep.cheques[i];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _statusColor(ch['status']).withOpacity(0.1),
                              child: Icon(Icons.payment, color: _statusColor(ch['status'])),
                            ),
                            title: Text('${ch['cheque_no']} - ${ch['party_name'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('₹${(ch['amount'] ?? 0).toStringAsFixed(2)} | ${ch['cheque_date'] ?? ''}'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Chip(label: Text(ch['status'] ?? '', style: TextStyle(fontSize: 10, color: Colors.white)),
                                  backgroundColor: _statusColor(ch['status']), padding: EdgeInsets.zero, labelPadding: const EdgeInsets.symmetric(horizontal: 6)),
                              ],
                            ),
                            onTap: () => _showChequeActions(context, ch, ep),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            final chqCtrl = TextEditingController();
            final dateCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
            final partyCtrl = TextEditingController();
            final amountCtrl = TextEditingController();
            final bankCtrl = TextEditingController();

            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Add Cheque'),
                content: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextField(controller: chqCtrl, decoration: const InputDecoration(labelText: 'Cheque No *')),
                    TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Date')),
                    TextField(controller: partyCtrl, decoration: const InputDecoration(labelText: 'Party Name')),
                    TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number),
                    TextField(controller: bankCtrl, decoration: const InputDecoration(labelText: 'Bank Name')),
                  ]),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  ElevatedButton(onPressed: () async {
                    if (chqCtrl.text.isEmpty) return;
                    await context.read<EnterpriseProvider>().createCheque({
                      'account_id': 1, 'cheque_no': chqCtrl.text.trim(),
                      'cheque_date': dateCtrl.text, 'party_name': partyCtrl.text.trim(),
                      'amount': double.tryParse(amountCtrl.text) ?? 0,
                      'bank_name': bankCtrl.text.trim(),
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

  Color _statusColor(String? status) {
    switch (status) {
      case 'Issued': return AppTheme.infoColor;
      case 'Deposited': return AppTheme.warningColor;
      case 'Cleared': return AppTheme.successColor;
      case 'Bounced': return AppTheme.errorColor;
      default: return Colors.grey;
    }
  }

  void _showChequeActions(BuildContext context, dynamic cheque, EnterpriseProvider ep) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: Text('Cheque #${cheque['cheque_no']}'), subtitle: Text('₹${(cheque['amount'] ?? 0).toStringAsFixed(2)}')),
          const Divider(),
          ListTile(leading: const Icon(Icons.account_balance, color: AppTheme.warningColor), title: const Text('Mark as Deposited'), onTap: () async {
            await ep.updateChequeStatus(cheque['id'], {'status': 'Deposited'}); Navigator.pop(ctx);
          }),
          ListTile(leading: const Icon(Icons.check_circle, color: AppTheme.successColor), title: const Text('Mark as Cleared'), onTap: () async {
            await ep.updateChequeStatus(cheque['id'], {'status': 'Cleared'}); Navigator.pop(ctx);
          }),
          ListTile(leading: const Icon(Icons.cancel, color: AppTheme.errorColor), title: const Text('Mark as Bounced'), onTap: () async {
            final reasonCtrl = TextEditingController();
            final result = await showDialog(context: context, builder: (dCtx) => AlertDialog(
              title: const Text('Bounce Reason'),
              content: TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Reason')),
              actions: [TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
                ElevatedButton(onPressed: () => Navigator.pop(dCtx, reasonCtrl.text), child: const Text('Confirm'))],
            ));
            if (result != null) {
              await ep.updateChequeStatus(cheque['id'], {'status': 'Bounced', 'reason': result});
              if (ctx.mounted) Navigator.pop(ctx);
            }
          }),
        ],
      ),
    );
  }
}
