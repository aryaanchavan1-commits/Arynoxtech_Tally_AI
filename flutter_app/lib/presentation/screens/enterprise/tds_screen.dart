import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/enterprise_provider.dart';

class TDSScreen extends StatefulWidget {
  const TDSScreen({super.key});

  @override
  State<TDSScreen> createState() => _TDSScreenState();
}

class _TDSScreenState extends State<TDSScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<EnterpriseProvider>().loadTDS());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnterpriseProvider>(
      builder: (context, ep, _) => Scaffold(
        appBar: AppBar(
          title: const Text('TDS Management'),
          actions: [IconButton(icon: const Icon(Icons.assessment), onPressed: () async {
            final report = await ep.getTDSReport();
            if (!mounted || report == null) return;
            showDialog(context: context, builder: (ctx) => AlertDialog(
              title: const Text('TDS Report'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                _r('Total Amount', '₹${(report['total_amount'] ?? 0).toStringAsFixed(2)}'),
                _r('Total TDS', '₹${(report['total_tds'] ?? 0).toStringAsFixed(2)}'),
                _r('Deductions', '${report['deductions_count'] ?? 0}'),
                const Divider(),
                Text('Section-wise', style: const TextStyle(fontWeight: FontWeight.bold)),
                ...(report['section_wise'] as Map? ?? {}).entries.map((e) => _r(e.key, '₹${(e.value as num).toStringAsFixed(2)}')),
              ]),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
            ));
          })],
        ),
        body: ep.tdsDeductions.isEmpty
            ? const Center(child: Text('No TDS deductions'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: ep.tdsDeductions.length,
                itemBuilder: (_, i) {
                  final t = ep.tdsDeductions[i];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: AppTheme.warningColor.withOpacity(0.1), child: const Icon(Icons.receipt, color: AppTheme.warningColor)),
                      title: Text('${t['party_name'] ?? ''} - Section ${t['section'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('₹${(t['amount'] ?? 0).toStringAsFixed(2)} | TDS: ₹${(t['total_tds'] ?? 0).toStringAsFixed(2)} | ${t['transaction_date'] ?? ''}'),
                      trailing: Text('${t['tds_rate'] ?? 0}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.warningColor)),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _r(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label), Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
    ]),
  );
}
