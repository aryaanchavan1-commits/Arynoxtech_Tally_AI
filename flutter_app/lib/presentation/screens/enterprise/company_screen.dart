import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/enterprise_provider.dart';

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<EnterpriseProvider>().loadCompanies());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnterpriseProvider>(
      builder: (context, ep, _) => Scaffold(
        appBar: AppBar(title: const Text('Companies')),
        body: ep.companies.isEmpty
            ? const Center(child: Text('No companies. Create your first company.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: ep.companies.length,
                itemBuilder: (_, i) {
                  final c = ep.companies[i];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: const Icon(Icons.business, color: AppTheme.primaryColor),
                      ),
                      title: Text(c['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${c['city'] ?? ''} | ${c['state'] ?? ''}\n${c['gstin'] ?? 'No GSTIN'}'),
                      isThreeLine: true,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (c['is_active'] == true)
                            const Chip(label: Text('Active', style: TextStyle(fontSize: 10, color: Colors.white)),
                              backgroundColor: AppTheme.successColor, padding: EdgeInsets.zero, labelPadding: EdgeInsets.symmetric(horizontal: 8)),
                        ],
                      ),
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showCreateDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final aliasCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final stateCtrl = TextEditingController();
    final gstCtrl = TextEditingController();
    final panCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Company'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Company Name *')),
              TextField(controller: aliasCtrl, decoration: const InputDecoration(labelText: 'Alias')),
              TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'City')),
              TextField(controller: stateCtrl, decoration: const InputDecoration(labelText: 'State')),
              TextField(controller: gstCtrl, decoration: const InputDecoration(labelText: 'GSTIN')),
              TextField(controller: panCtrl, decoration: const InputDecoration(labelText: 'PAN')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            if (nameCtrl.text.isEmpty) return;
            await context.read<EnterpriseProvider>().createCompany({
              'name': nameCtrl.text.trim(), 'alias': aliasCtrl.text.trim(),
              'city': cityCtrl.text.trim(), 'state': stateCtrl.text.trim(),
              'gstin': gstCtrl.text.trim(), 'pan': panCtrl.text.trim(),
              'phone': phoneCtrl.text.trim(),
            });
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: const Text('Create')),
        ],
      ),
    );
  }
}
