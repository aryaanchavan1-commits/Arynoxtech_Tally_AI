import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';

class ProfitLossScreen extends StatefulWidget {
  const ProfitLossScreen({super.key});

  @override
  State<ProfitLossScreen> createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends State<ProfitLossScreen> {
  final _api = ApiClient();
  Map<String, dynamic>? _data;
  bool _loading = true;
  final _fromCtrl = TextEditingController(text: '${DateTime.now().year}-04-01');
  final _toCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _api.get(ApiConstants.reportsProfitLoss, queryParams: {'from_date': _fromCtrl.text, 'to_date': _toCtrl.text});
    if (res.statusCode == 200) setState(() { _data = jsonDecode(res.body); _loading = false; });
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profit & Loss')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(children: [
                  Expanded(child: TextField(controller: _fromCtrl, decoration: const InputDecoration(labelText: 'From', isDense: true),
                    onTap: () async {
                      final d = await showDatePicker(context: context, firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (d != null) _fromCtrl.text = d.toIso8601String().substring(0, 10);
                    },
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _toCtrl, decoration: const InputDecoration(labelText: 'To', isDense: true),
                    onTap: () async {
                      final d = await showDatePicker(context: context, firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (d != null) _toCtrl.text = d.toIso8601String().substring(0, 10);
                    },
                  )),
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
                ]),
                const SizedBox(height: 16),
                Card(child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Income', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.successColor)),
                      ...(_data?['income_items'] as List? ?? []).map((i) => _row(i['account_name'], i['amount'])),
                      const Divider(),
                      _row('Total Income', _data?['total_income'] ?? 0, bold: true),
                    ],
                  ),
                )),
                const SizedBox(height: 12),
                Card(child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Expenses', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.errorColor)),
                      ...(_data?['expense_items'] as List? ?? []).map((i) => _row(i['account_name'], i['amount'])),
                      const Divider(),
                      _row('Total Expenses', _data?['total_expenses'] ?? 0, bold: true),
                    ],
                  ),
                )),
                const SizedBox(height: 12),
                Card(
                  color: (_data?['net_profit'] ?? 0) >= 0 ? AppTheme.successColor.withOpacity(0.1) : AppTheme.errorColor.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Net ${(_data?['net_profit'] ?? 0) >= 0 ? 'Profit' : 'Loss'}: ₹${(_data?['net_profit'] ?? 0).toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: (_data?['net_profit'] ?? 0) >= 0 ? AppTheme.successColor : AppTheme.errorColor),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _row(String label, dynamic amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        Text('₹${(amount ?? 0).toStringAsFixed(2)}', style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      ]),
    );
  }
}
