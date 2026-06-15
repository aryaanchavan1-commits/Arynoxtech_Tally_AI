import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/ai_provider.dart';

class AISettingsScreen extends StatefulWidget {
  const AISettingsScreen({super.key});

  @override
  State<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends State<AISettingsScreen> {
  final _keyCtrl = TextEditingController();
  String _provider = 'groq';
  String? _model;
  List<dynamic> _models = [];
  bool _testing = false;
  bool _keyChanged = false;

  @override
  void initState() {
    super.initState();
    _keyCtrl.addListener(() {
      if (!_keyChanged && _keyCtrl.text.isNotEmpty) {
        setState(() => _keyChanged = true);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ai = context.read<AIProvider>();
      ai.loadProviders();
      ai.loadSettings();
    });
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ai = context.read<AIProvider>();
    final body = <String, dynamic>{
      'provider': _provider,
      'model': _model,
    };
    if (_keyChanged && _keyCtrl.text.isNotEmpty) {
      body['api_key'] = _keyCtrl.text;
    }
    final success = await ai.saveSettings(body);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Settings saved' : 'Failed to save')));
      if (success) setState(() => _keyChanged = false);
    }
  }

  Future<void> _test() async {
    if (_keyCtrl.text.isEmpty) return;
    setState(() => _testing = true);
    final ai = context.read<AIProvider>();
    final result = await ai.testConnection({
      'provider': _provider,
      'api_key': _keyCtrl.text,
      'model': _model,
    });
    setState(() => _testing = false);
    if (mounted && result != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Test completed'),
        backgroundColor: result['success'] == true ? AppTheme.successColor : AppTheme.errorColor,
      ));
    }
  }

  Future<void> _delete() async {
    final ai = context.read<AIProvider>();
    await ai.deleteSettings();
    _keyCtrl.clear();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI settings removed')));
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AIProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('AI Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Provider', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...ai.providers.map((p) => RadioListTile(
                    value: p['id'],
                    groupValue: _provider,
                    title: Text(p['name']),
                    onChanged: (v) {
                      setState(() {
                        _provider = v as String;
                        _models = p['models'] as List<dynamic>;
                        _model = _models.isNotEmpty ? _models.first as String : null;
                        _keyCtrl.clear();
                      });
                    },
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_models.isNotEmpty)
            DropdownButtonFormField(
              value: _model,
              items: _models.map((m) => DropdownMenuItem(value: m as String, child: Text(m))).toList(),
              onChanged: (v) => setState(() => _model = v as String?),
              decoration: const InputDecoration(labelText: 'Model'),
            ),
          const SizedBox(height: 16),
          if (ai.settings?['has_api_key'] == true && !_keyChanged)
            Row(children: [
              Icon(Icons.check_circle, size: 16, color: AppTheme.successColor),
              const SizedBox(width: 6),
              Text('API key is saved', style: TextStyle(color: AppTheme.successColor, fontSize: 13)),
            ]),
          const SizedBox(height: 4),
          TextFormField(
            controller: _keyCtrl,
            decoration: InputDecoration(
              labelText: 'API Key',
              hintText: ai.settings?['has_api_key'] == true ? 'Leave empty to keep existing key' : 'Enter your API key',
            ),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: _testing ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.wifi_tethering),
                  label: const Text('Test Connection'),
                  onPressed: _testing ? null : _test,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                  onPressed: _save,
                ),
              ),
            ],
          ),
          if (ai.settings != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              icon: const Icon(Icons.delete, color: AppTheme.errorColor),
              label: const Text('Remove API Key', style: TextStyle(color: AppTheme.errorColor)),
              onPressed: _delete,
            ),
          ],
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Supported Providers', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('• Groq - Fast free inference (Llama 3.3, DeepSeek, Mixtral, Gemma)'),
                  Text('• OpenAI - GPT-4o, GPT-4o-mini'),
                  Text('• Gemini - Google Gemini 2.0 Flash'),
                  Text('• OpenRouter - Free models (DeepSeek V4 Flash Free, Gemini Flash Free, Llama 3.2 Free)'),
                  Text('• API keys are encrypted and stored locally'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
