import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class EnhancedReportsScreen extends StatefulWidget {
  const EnhancedReportsScreen({super.key});

  @override
  State<EnhancedReportsScreen> createState() => _EnhancedReportsScreenState();
}

class _EnhancedReportsScreenState extends State<EnhancedReportsScreen> {
  final _api = ApiClient();
  final _fromCtrl = TextEditingController(text: '${DateTime.now().year}-04-01');
  final _toCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
  Map<String, dynamic>? _stockValuation;
  Map<String, dynamic>? _cashFlow;
  Map<String, dynamic>? _ratioAnalysis;

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enhanced Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(child: TextField(controller: _fromCtrl, decoration: const InputDecoration(labelText: 'From', isDense: true))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _toCtrl, decoration: const InputDecoration(labelText: 'To', isDense: true))),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAllReports),
            ]),
          )),

          const SizedBox(height: 8),

          Text('Cash Flow Statement', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          _buildCashFlowCard(),

          const SizedBox(height: 12),

          Text('Ratio Analysis', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          _buildRatioCard(),

          const SizedBox(height: 12),

          Text('Stock Valuation', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          _buildStockValuationCard(),
        ],
      ),
    );
  }

  Future<void> _loadAllReports() async {
    final stockR = await _api.get('${ApiConstants.baseUrl}/api/enterprise/reports/stock-valuation');
    if (stockR.statusCode == 200) setState(() => _stockValuation = jsonDecode(stockR.body));

    final cashR = await _api.get('${ApiConstants.baseUrl}/api/enterprise/reports/cash-flow',
        queryParams: {'from_date': _fromCtrl.text, 'to_date': _toCtrl.text});
    if (cashR.statusCode == 200) setState(() => _cashFlow = jsonDecode(cashR.body));

    final ratioR = await _api.get('${ApiConstants.baseUrl}/api/enterprise/reports/ratio-analysis',
        queryParams: {'from_date': _fromCtrl.text, 'to_date': _toCtrl.text});
    if (ratioR.statusCode == 200) setState(() => _ratioAnalysis = jsonDecode(ratioR.body));
  }

  Widget _buildCashFlowCard() {
    final c = _cashFlow;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row('Opening Balance', '₹${(c?['opening_balance'] ?? 0).toStringAsFixed(2)}'),
            _row('Cash Inflow', '₹${(c?['cash_inflow'] ?? 0).toStringAsFixed(2)}', valueColor: AppTheme.successColor),
            _row('Cash Outflow', '₹${(c?['cash_outflow'] ?? 0).toStringAsFixed(2)}', valueColor: AppTheme.errorColor),
            _row('Net Flow', '₹${(c?['net_flow'] ?? 0).toStringAsFixed(2)}', valueColor: (c?['net_flow'] ?? 0) >= 0 ? AppTheme.successColor : AppTheme.errorColor),
            const Divider(),
            _row('Closing Balance', '₹${(c?['closing_balance'] ?? 0).toStringAsFixed(2)}', bold: true, valueColor: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildRatioCard() {
    final r = _ratioAnalysis;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row('Current Ratio', (r?['current_ratio'] ?? 0).toStringAsFixed(2)),
            _row('Debt-Equity Ratio', (r?['debt_equity_ratio'] ?? 0).toStringAsFixed(2)),
            _row('Profit Margin', '${(r?['profit_margin_pct'] ?? 0).toStringAsFixed(2)}%',
                valueColor: (r?['profit_margin_pct'] ?? 0) >= 0 ? AppTheme.successColor : AppTheme.errorColor),
            const Divider(),
            _row('Total Assets', '₹${(r?['total_assets'] ?? 0).toStringAsFixed(2)}'),
            _row('Total Liabilities', '₹${(r?['total_liabilities'] ?? 0).toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildStockValuationCard() {
    final s = _stockValuation;
    final items = (s?['items'] as List?) ?? [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ...items.take(5).map((i) => _row(i['product_name'] ?? '', '₹${(i['value'] ?? 0).toStringAsFixed(2)}')),
            const Divider(),
            _row('Total Value', '₹${(s?['total_value'] ?? 0).toStringAsFixed(2)}', bold: true, valueColor: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? valueColor}) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: valueColor)),
      ]));
  }
}
