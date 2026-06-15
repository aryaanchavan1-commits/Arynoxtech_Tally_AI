import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

class SidebarMenu extends StatefulWidget {
  final int selectedIndex;
  final Function(int, String?) onItemSelected;

  const SidebarMenu({super.key, required this.selectedIndex, required this.onItemSelected});

  @override
  State<SidebarMenu> createState() => _SidebarMenuState();
}

class _SidebarMenuState extends State<SidebarMenu> {
  bool _showGateway = false;
  bool _showInventory = false;
  bool _showAccounting = false;
  bool _showTransactions = false;
  bool _showEnterprise = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(right: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
              ),
            ),
            child: Column(
              children: [
                const CircleAvatar(radius: 28, backgroundColor: Colors.white24, child: Icon(Icons.account_balance, color: Colors.white, size: 28)),
                const SizedBox(height: 12),
                Text('Arynoxtech Tally', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(auth.user?.fullName ?? '', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                _menuItem(Icons.dashboard, 'Dashboard', 0, route: AppRoutes.dashboard),
                _sectionHeader('MASTER'),
                _menuItem(Icons.business, 'Companies', -1, route: AppRoutes.companies),
                _menuItem(Icons.account_balance, 'Chart of Accounts', -1, route: AppRoutes.chartOfAccounts),
                _menuItem(Icons.group_work, 'Stock Groups', -1, route: AppRoutes.categories),
                _menuItem(Icons.warehouse, 'Godowns', -1, route: AppRoutes.godowns),
                _menuItem(Icons.local_offer, 'Price Levels', -1, route: AppRoutes.priceLevels),
                _sectionHeader('TRANSACTIONS'),
                _menuItem(Icons.description, 'Vouchers', -1, route: AppRoutes.vouchers),
                _menuItem(Icons.shopping_cart, 'POS Billing (F8)', -1, route: AppRoutes.pos),
                _menuItem(Icons.receipt_long, 'Invoices', -1, route: AppRoutes.invoices),
                _menuItem(Icons.money_off, 'Expenses', -1, route: AppRoutes.expenses),
                _menuItem(Icons.payment, 'Cheques', -1, route: AppRoutes.cheques),
                _sectionHeader('ACCOUNTING'),
                _menuItem(Icons.people, 'Customers', -1, route: AppRoutes.customers),
                _menuItem(Icons.business, 'Suppliers', -1, route: AppRoutes.suppliers),
                _menuItem(Icons.inventory, 'Products', -1, route: AppRoutes.products),
                _menuItem(Icons.batch_prediction, 'Batches & Expiry', -1, route: AppRoutes.batches),
                _menuItem(Icons.precision_manufacturing, 'BOM / Mfg', -1, route: AppRoutes.bom),
                _sectionHeader('REPORTS'),
                _menuItem(Icons.assessment, 'Trial Balance (F10)', -1, route: AppRoutes.trialBalance),
                _menuItem(Icons.trending_up, 'Profit & Loss (F11)', -1, route: AppRoutes.profitLoss),
                _menuItem(Icons.account_balance, 'Balance Sheet (F12)', -1, route: AppRoutes.balanceSheet),
                _menuItem(Icons.analytics, 'Enhanced Reports', -1, route: AppRoutes.enhancedReports),
                _menuItem(Icons.receipt, 'GST Returns', -1, route: AppRoutes.gstReturns),
                _menuItem(Icons.money, 'TDS Reports', -1, route: AppRoutes.tds),
                _sectionHeader('TOOLS'),
                _menuItem(Icons.support_agent, 'AI Assistant (F2)', -1, route: AppRoutes.aiChat),
                _menuItem(Icons.compare_arrows, 'Bank Recon', -1, route: AppRoutes.bankReconciliation),
                _menuItem(Icons.analytics_outlined, 'Cost Centers', -1, route: AppRoutes.costCenters),
                _menuItem(Icons.account_balance_wallet, 'Budgets', -1, route: AppRoutes.budgets),
                _menuItem(Icons.history, 'Audit Logs', -1, route: AppRoutes.auditLogs),
                _menuItem(Icons.backup, 'Backup & Restore', -1, route: AppRoutes.backup),
                _menuItem(Icons.settings, 'Settings', -1, route: AppRoutes.settings),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.logout, size: 16),
                    label: const Text('Logout'),
                    onPressed: () async {
                      await auth.logout();
                      if (context.mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
                    },
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.errorColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(title,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 1.5)),
    );
  }

  Widget _menuItem(IconData icon, String label, int index, {String? route}) {
    final isSelected = widget.selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: Material(
        color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          leading: Icon(icon, size: 18, color: isSelected ? Theme.of(context).colorScheme.primary : null),
          title: Text(label, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
          dense: true,
          onTap: () => widget.onItemSelected(index, route),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
