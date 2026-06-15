import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class TrialBalanceScreen extends StatefulWidget {
  const TrialBalanceScreen({super.key});

  @override
  State<TrialBalanceScreen> createState() => _TrialBalanceScreenState();
}

class _TrialBalanceScreenState extends State<TrialBalanceScreen> {
  final _api = ApiClient();
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await _api.get(ApiConstants.reportsTrialBalance);
    if (res.statusCode == 200) setState(() { _data = jsonDecode(res.body); _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trial Balance')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DataTable(
                  columnSpacing: 20,
                  columns: const [DataColumn(label: Text('Account')), DataColumn(label: Text('Debit'), numeric: true), DataColumn(label: Text('Credit'), numeric: true)],
                  rows: (_data?['items'] as List? ?? []).map((item) => DataRow(cells: [
                    DataCell(Text(item['account_name'] ?? '')),
                    DataCell(Text((item['debit'] ?? 0).toStringAsFixed(2))),
                    DataCell(Text((item['credit'] ?? 0).toStringAsFixed(2))),
                  ])).toList(),
                ),
                const Divider(),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Total', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('₹${(_data?['total_debit'] ?? 0).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('₹${(_data?['total_credit'] ?? 0).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ]),
              ],
            ),
    );
  }
}
