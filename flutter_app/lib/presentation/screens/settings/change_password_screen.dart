import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  Future<void> _change() async {
    if (_newCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    final success = await context.read<AuthProvider>().changePassword(_currentCtrl.text, _newCtrl.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'Password changed successfully' : 'Failed to change password'),
        backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
      ));
      if (success) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _currentCtrl, decoration: const InputDecoration(labelText: 'Current Password'), obscureText: true),
          const SizedBox(height: 16),
          TextField(controller: _newCtrl, decoration: const InputDecoration(labelText: 'New Password'), obscureText: true),
          const SizedBox(height: 16),
          TextField(controller: _confirmCtrl, decoration: const InputDecoration(labelText: 'Confirm New Password'), obscureText: true),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _change, child: const Text('Change Password')),
        ],
      ),
    );
  }
}
