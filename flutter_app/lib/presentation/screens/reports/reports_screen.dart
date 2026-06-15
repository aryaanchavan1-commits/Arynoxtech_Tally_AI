import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _reportCard(context, 'Trial Balance', Icons.balance, 'View trial balance', AppRoutes.trialBalance),
          _reportCard(context, 'Profit & Loss', Icons.trending_up, 'View profit and loss statement', AppRoutes.profitLoss),
          _reportCard(context, 'Balance Sheet', Icons.account_balance, 'View balance sheet', AppRoutes.balanceSheet),
          _reportCard(context, 'Day Book', Icons.book, 'View day book', AppRoutes.enhancedReports),
          _reportCard(context, 'General Ledger', Icons.receipt, 'View general ledger', AppRoutes.enhancedReports),
        ],
      ),
    );
  }

  Widget _reportCard(BuildContext context, String title, IconData icon, String subtitle, String route) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }
}
