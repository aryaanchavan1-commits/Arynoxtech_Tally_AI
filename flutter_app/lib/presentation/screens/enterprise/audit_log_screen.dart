import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/enterprise_provider.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<EnterpriseProvider>().loadAuditLogs());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnterpriseProvider>(
      builder: (context, ep, _) => Scaffold(
        appBar: AppBar(title: const Text('Audit Logs')),
        body: ep.auditLogs.isEmpty
            ? const Center(child: Text('No audit logs'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: ep.auditLogs.length,
                itemBuilder: (_, i) {
                  final log = ep.auditLogs[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _actionColor(log['action']).withOpacity(0.1),
                        child: Icon(_actionIcon(log['action']), color: _actionColor(log['action']), size: 18),
                      ),
                      title: Text('${log['action']} - ${log['entity_type']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text('ID: ${log['entity_id'] ?? 'N/A'} | ${log['created_at'] ?? ''}', style: const TextStyle(fontSize: 11)),
                      dense: true,
                    ),
                  );
                },
              ),
      ),
    );
  }

  Color _actionColor(String? action) {
    switch (action?.toUpperCase()) {
      case 'CREATE': return AppTheme.successColor;
      case 'UPDATE': return AppTheme.infoColor;
      case 'DELETE': return AppTheme.errorColor;
      case 'RECONCILE': return AppTheme.accentColor;
      case 'LOGIN': return AppTheme.primaryColor;
      default: return Colors.grey;
    }
  }

  IconData _actionIcon(String? action) {
    switch (action?.toUpperCase()) {
      case 'CREATE': return Icons.add_circle;
      case 'UPDATE': return Icons.edit;
      case 'DELETE': return Icons.delete;
      case 'RECONCILE': return Icons.compare_arrows;
      case 'LOGIN': return Icons.login;
      default: return Icons.info;
    }
  }
}
