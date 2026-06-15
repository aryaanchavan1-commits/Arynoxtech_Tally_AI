import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/enterprise_provider.dart';

class GSTReturnScreen extends StatefulWidget {
  const GSTReturnScreen({super.key});

  @override
  State<GSTReturnScreen> createState() => _GSTReturnScreenState();
}

class _GSTReturnScreenState extends State<GSTReturnScreen> {
  final _periods = ['Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar'];
  String _selectedPeriod = DateTime.now().month >= 4
      ? ['Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar'][DateTime.now().month - 4]
      : ['Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar'][DateTime.now().month + 8];
  String _fy = '${DateTime.now().year}-${DateTime.now().year + 1}';
  Map<String, dynamic>? _lastResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<EnterpriseProvider>().loadGSTReturns());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnterpriseProvider>(
      builder: (context, ep, _) => Scaffold(
        appBar: AppBar(title: const Text('GST Returns')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Generate GST Return', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField(value: _selectedPeriod, items: _periods.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                      onChanged: (v) => setState(() => _selectedPeriod = v!), decoration: const InputDecoration(labelText: 'Period', isDense: true)),
                    const SizedBox(height: 8),
                    TextField(controller: TextEditingController(text: _fy), decoration: const InputDecoration(labelText: 'Financial Year', isDense: true)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.summarize), label: const Text('GSTR-1'),
                        onPressed: () async {
                          final result = await ep.generateGSTReturn({
                            'return_type': 'GSTR-1', 'period': _selectedPeriod, 'financial_year': _fy,
                          });
                          if (result != null) setState(() => _lastResult = result);
                        })),
                      const SizedBox(width: 8),
                      Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.receipt), label: const Text('GSTR-3B'),
                        onPressed: () async {
                          final result = await ep.generateGSTReturn({
                            'return_type': 'GSTR-3B', 'period': _selectedPeriod, 'financial_year': _fy,
                          });
                          if (result != null) setState(() => _lastResult = result);
                        })),
                    ]),
                  ],
                ),
              ),
            ),
            if (_lastResult != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Return Generated', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Divider(),
                      _row('Period', _lastResult!['return']?['period'] ?? ''),
                      _row('Type', _lastResult!['return']?['return_type'] ?? ''),
                      _row('Invoices', '${_lastResult!['return']?['total_invoices'] ?? 0}'),
                      _row('Taxable Value', '₹${(_lastResult!['return']?['total_taxable'] ?? 0).toStringAsFixed(2)}'),
                      _row('CGST', '₹${(_lastResult!['return']?['total_cgst'] ?? 0).toStringAsFixed(2)}'),
                      _row('SGST', '₹${(_lastResult!['return']?['total_sgst'] ?? 0).toStringAsFixed(2)}'),
                      _row('IGST', '₹${(_lastResult!['return']?['total_igst'] ?? 0).toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text('Previous Returns', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ...ep.gstReturns.map((r) => Card(
              child: ListTile(
                leading: CircleAvatar(child: Icon(Icons.receipt, color: r['return_type'] == 'GSTR-1' ? AppTheme.infoColor : AppTheme.accentColor)),
                title: Text('${r['return_type']} - ${r['period']} ${r['financial_year']}'),
                subtitle: Text('Taxable: ₹${(r['total_taxable'] ?? 0).toStringAsFixed(2)} | Status: ${r['status']}'),
                trailing: const Icon(Icons.chevron_right),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]));
  }
}
