import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../providers/invoice_provider.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<InvoiceProvider>().loadInvoices());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InvoiceProvider>(
      builder: (context, provider, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Invoices'),
          actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => Navigator.pushNamed(context, AppRoutes.createInvoice))],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Unpaid', 'Paid', 'Overdue'].map((f) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(label: Text(f), selected: _filter == f, onSelected: (v) {
                      setState(() => _filter = f);
                      provider.loadInvoices(status: f == 'All' ? null : f);
                    }),
                  )).toList(),
                ),
              ),
            ),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.invoices.isEmpty
                      ? const Center(child: Text('No invoices'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: provider.invoices.length,
                          itemBuilder: (_, i) {
                            final inv = provider.invoices[i];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _statusColor(inv.status).withOpacity(0.1),
                                  child: Icon(Icons.receipt, color: _statusColor(inv.status)),
                                ),
                                title: Text('#${inv.invoiceNo}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text('${inv.customerName ?? 'N/A'} | ${inv.invoiceDate}'),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('₹${inv.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Chip(label: Text(inv.status, style: TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: _statusColor(inv.status), padding: EdgeInsets.zero, labelPadding: const EdgeInsets.symmetric(horizontal: 6), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                  ],
                                ),
                                onTap: () => Navigator.pushNamed(context, AppRoutes.invoiceDetail, arguments: inv.id),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.createInvoice),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Paid': return AppTheme.successColor;
      case 'Unpaid': return AppTheme.warningColor;
      case 'Overdue': return AppTheme.errorColor;
      case 'Partial': return AppTheme.infoColor;
      default: return Colors.grey;
    }
  }
}
