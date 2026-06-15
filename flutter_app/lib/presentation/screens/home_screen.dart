import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/search_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/sidebar_menu.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/accounts/chart_of_accounts_screen.dart';
import '../screens/customers/customer_list_screen.dart';
import '../screens/inventory/product_list_screen.dart';
import '../screens/invoices/invoice_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ChartOfAccountsScreen(),
    const CustomerListScreen(),
    const ProductListScreen(),
    const InvoiceListScreen(),
  ];

  void _onMenuItemSelected(String route) {
    Navigator.pushNamed(context, route);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        if (isWide) {
          return Scaffold(
            body: Row(
              children: [
                SidebarMenu(
                  selectedIndex: _selectedIndex,
                  onItemSelected: (index, route) {
                    if (index >= 0 && index < _screens.length) {
                      setState(() => _selectedIndex = index);
                    }
                    if (route != null) _onMenuItemSelected(route);
                  },
                ),
                Expanded(child: _buildBody(theme)),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: _buildAppBar(theme),
          drawer: SidebarMenu(
            selectedIndex: _selectedIndex,
            onItemSelected: (index, route) {
              if (index >= 0 && index < _screens.length) {
                setState(() => _selectedIndex = index);
              }
              Navigator.pop(context);
              if (route != null) _onMenuItemSelected(route);
            },
          ),
          body: _buildBody(theme),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setState(() => _selectedIndex = index),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
              NavigationDestination(icon: Icon(Icons.account_balance), label: 'Accounts'),
              NavigationDestination(icon: Icon(Icons.people), label: 'Customers'),
              NavigationDestination(icon: Icon(Icons.inventory), label: 'Products'),
              NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Invoices'),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: Text('Arynoxtech Tally', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
      actions: [
        IconButton(icon: const Icon(Icons.search), onPressed: () => _showSearchDialog(context)),
        IconButton(icon: const Icon(Icons.support_agent), onPressed: () => Navigator.pushNamed(context, AppRoutes.aiChat)),
        IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.pushNamed(context, AppRoutes.settings)),
      ],
    );
  }

  Widget _buildBody(ThemeData theme) {
    return Column(
      children: [
        _buildSearchBar(theme),
        Expanded(child: _screens[_selectedIndex]),
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search customers, products, invoices...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear())
              : null,
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: (value) {
          setState(() {});
          context.read<SearchProvider>().search(value);
        },
        onSubmitted: (value) => _showSearchResults(context, value),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showSearch(context: context, delegate: GlobalSearchDelegate());
  }

  void _showSearchResults(BuildContext context, String query) {
    if (query.isEmpty) return;
    context.read<SearchProvider>().search(query);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Consumer<SearchProvider>(
        builder: (_, search, __) => ListView(
          padding: const EdgeInsets.all(16),
          children: search.results.map((r) => ListTile(
            leading: _getIcon(r['type']),
            title: Text(r['title'] ?? ''),
            subtitle: Text(r['subtitle'] ?? ''),
            onTap: () {
              Navigator.pop(ctx);
              _navigateToResult(r);
            },
          )).toList(),
        ),
      ),
    );
  }

  Widget _getIcon(String type) {
    switch (type) {
      case 'customer': return const CircleAvatar(child: Icon(Icons.person));
      case 'supplier': return const CircleAvatar(child: Icon(Icons.business));
      case 'product': return const CircleAvatar(child: Icon(Icons.inventory));
      case 'invoice': return const CircleAvatar(child: Icon(Icons.receipt));
      default: return const CircleAvatar(child: Icon(Icons.search));
    }
  }

  void _navigateToResult(dynamic result) {
    final type = result['type'] as String;
    final id = result['id'] as int;
    switch (type) {
      case 'customer': Navigator.pushNamed(context, AppRoutes.customerDetail, arguments: id);
      case 'supplier': Navigator.pushNamed(context, AppRoutes.supplierDetail, arguments: id);
      case 'product': Navigator.pushNamed(context, AppRoutes.productDetail, arguments: id);
      case 'invoice': Navigator.pushNamed(context, AppRoutes.invoiceDetail, arguments: id);
    }
  }
}

class GlobalSearchDelegate extends SearchDelegate<String?> {
  @override
  List<Widget>? buildActions(BuildContext context) => [];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => const Center(child: Text('Search'));

  @override
  Widget buildSuggestions(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (_, search, __) {
        if (query.isEmpty) return const Center(child: Text('Start typing to search'));
        if (search.isLoading) return const Center(child: CircularProgressIndicator());
        return ListView.builder(
          itemCount: search.results.length,
          itemBuilder: (_, i) {
            final r = search.results[i];
            return ListTile(
              leading: CircleAvatar(child: Icon(_getIcon(r['type']))),
              title: Text(r['title'] ?? ''),
              subtitle: Text(r['subtitle'] ?? ''),
              onTap: () => close(context, null),
            );
          },
        );
      },
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'customer': return Icons.person;
      case 'supplier': return Icons.business;
      case 'product': return Icons.inventory;
      case 'invoice': return Icons.receipt;
      default: return Icons.search;
    }
  }
}
