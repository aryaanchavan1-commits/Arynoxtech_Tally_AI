import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/backup_provider.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<BackupProvider>().loadBackups());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BackupProvider>(
      builder: (context, provider, _) => Scaffold(
        appBar: AppBar(title: const Text('Backup & Restore')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.backup, size: 48, color: AppTheme.accentColor),
                    const SizedBox(height: 12),
                    Text('Your data is stored locally on your device.', style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.backup),
                        label: const Text('Create Backup'),
                        onPressed: () async {
                          await provider.createBackup();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup created')));
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Backup History', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (provider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (provider.backups.isEmpty)
              const Center(child: Text('No backups yet'))
            else
              ...provider.backups.map((b) => Card(
                child: ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: Text(b['filename'] ?? ''),
                  subtitle: Text('${b['backup_type']} | ${_formatSize(b['size_bytes'])}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.restore), onPressed: () async {
                        final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                          title: const Text('Restore Backup?'),
                          content: const Text('This will replace all current data. Continue?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restore')),
                          ],
                        ));
                        if (confirm == true) {
                          await provider.restoreBackup(b['id']);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup restored. Please restart.')));
                          }
                        }
                      }),
                      IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor), onPressed: () async {
                        await provider.deleteBackup(b['id']);
                      }),
                    ],
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }

  String _formatSize(dynamic bytes) {
    final size = (bytes ?? 0).toDouble();
    if (size < 1024) return '${size.toStringAsFixed(0)} B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
