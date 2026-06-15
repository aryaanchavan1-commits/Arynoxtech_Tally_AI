import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class CreateVoucherScreen extends StatefulWidget {
  final String? voucherType;
  const CreateVoucherScreen({super.key, this.voucherType});

  @override
  State<CreateVoucherScreen> createState() => _CreateVoucherScreenState();
}

class _CreateVoucherScreenState extends State<CreateVoucherScreen> {
  final _api = ApiClient();
  final _dateController = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
  final _narrationController = TextEditingController();
  final _refController = TextEditingController();
  String _voucherType = 'Journal';
  List<dynamic> _accounts = [];
  List<Map<String, dynamic>> _entries = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.voucherType != null) _voucherType = widget.voucherType!;
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final res = await _api.get(ApiConstants.accounts);
    if (res.statusCode == 200) setState(() => _accounts = jsonDecode(res.body));
  }

  void _addEntry() {
    setState(() => _entries.add({'account_id': null, 'debit': 0.0, 'credit': 0.0, 'particular': ''}));
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final totalDebit = _entries.fold(0.0, (sum, e) => sum + (e['debit'] as num).toDouble());
    final totalCredit = _entries.fold(0.0, (sum, e) => sum + (e['credit'] as num).toDouble());
    if ((totalDebit - totalCredit).abs() > 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debit and Credit must match')));
      setState(() => _loading = false);
      return;
    }
    final res = await _api.post(ApiConstants.vouchers, body: {
      'voucher_type': _voucherType,
      'date': _dateController.text,
      'narration': _narrationController.text,
      'reference_no': _refController.text,
      'entries': _entries,
    });
    setState(() => _loading = false);
    if (mounted) {
      if (res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voucher created')));
        Navigator.pop(context);
      } else {
        final err = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err['detail'] ?? 'Error')));
      }
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _narrationController.dispose();
    _refController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$_voucherType Voucher')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField(
            value: _voucherType,
            items: ['Payment', 'Receipt', 'Sales', 'Purchase', 'Contra', 'Journal', 'Debit Note', 'Credit Note']
                .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _voucherType = v!),
            decoration: const InputDecoration(labelText: 'Voucher Type'),
          ),
          const SizedBox(height: 12),
          TextFormField(controller: _dateController, decoration: const InputDecoration(labelText: 'Date', prefixIcon: Icon(Icons.calendar_today)),
            onTap: () async {
              final date = await showDatePicker(context: context, firstDate: DateTime(2000), lastDate: DateTime(2100), initialDate: DateTime.now());
              if (date != null) _dateController.text = date.toIso8601String().substring(0, 10);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(controller: _narrationController, decoration: const InputDecoration(labelText: 'Narration'), maxLines: 2),
          const SizedBox(height: 12),
          TextFormField(controller: _refController, decoration: const InputDecoration(labelText: 'Reference No.')),
          const SizedBox(height: 20),
          Row(children: [
            Text('Entries', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(icon: const Icon(Icons.add), label: const Text('Add Entry'), onPressed: _addEntry),
          ]),
          ..._entries.asMap().entries.map((entry) => Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  DropdownButtonFormField(
                    value: entry.value['account_id'],
                    items: _accounts.map((a) => DropdownMenuItem(value: a['id'], child: Text(a['name']))).toList(),
                    onChanged: (v) => setState(() => entry.value['account_id'] = v),
                    decoration: const InputDecoration(labelText: 'Account', isDense: true),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextField(
                      decoration: const InputDecoration(labelText: 'Debit', isDense: true),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => entry.value['debit'] = double.tryParse(v) ?? 0,
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(
                      decoration: const InputDecoration(labelText: 'Credit', isDense: true),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => entry.value['credit'] = double.tryParse(v) ?? 0,
                    )),
                  ]),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Particulars', isDense: true),
                    onChanged: (v) => entry.value['particular'] = v,
                  ),
                ],
              ),
            ),
          )),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _save,
            child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save Voucher'),
          ),
        ],
      ),
    );
  }
}
