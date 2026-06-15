import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../providers/account_provider.dart';

class ChartOfAccountsScreen extends StatefulWidget {
  const ChartOfAccountsScreen({super.key});

  @override
  State<ChartOfAccountsScreen> createState() => _ChartOfAccountsScreenState();
}

class _ChartOfAccountsScreenState extends State<ChartOfAccountsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountProvider>().loadAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Chart of Accounts'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.createAccount),
              ),
            ],
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : provider.accounts.isEmpty
                  ? const Center(child: Text('No accounts. Add your first account.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.accounts.length,
                      itemBuilder: (_, i) {
                        final acc = provider.accounts[i];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: acc.currentBalance >= 0 ? AppTheme.successColor.withOpacity(0.1) : AppTheme.errorColor.withOpacity(0.1),
                              child: Icon(Icons.account_balance, color: acc.currentBalance >= 0 ? AppTheme.successColor : AppTheme.errorColor),
                            ),
                            title: Text(acc.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${acc.groupName} | ${acc.accountType}'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('₹${acc.currentBalance.toStringAsFixed(2)}', style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: acc.currentBalance >= 0 ? AppTheme.successColor : AppTheme.errorColor,
                                )),
                                Text('Open: ₹${acc.openingBalance.toStringAsFixed(2)}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.createAccount),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
