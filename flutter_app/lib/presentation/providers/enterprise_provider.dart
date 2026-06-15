import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';

class EnterpriseProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  List<dynamic> _companies = [];
  List<dynamic> _godowns = [];
  List<dynamic> _stockGroups = [];
  List<dynamic> _batches = [];
  List<dynamic> _costCenters = [];
  List<dynamic> _costCategories = [];
  List<dynamic> _budgets = [];
  List<dynamic> _auditLogs = [];
  List<dynamic> _cheques = [];
  List<dynamic> _tdsDeductions = [];
  List<dynamic> _gstReturns = [];
  List<dynamic> _priceLevels = [];
  List<dynamic> _bankTransactions = [];
  List<dynamic> _bom = [];
  dynamic _activePosSession;
  bool _isLoading = false;
  String? _error;

  List<dynamic> get companies => _companies;
  List<dynamic> get godowns => _godowns;
  List<dynamic> get stockGroups => _stockGroups;
  List<dynamic> get batches => _batches;
  List<dynamic> get costCenters => _costCenters;
  List<dynamic> get costCategories => _costCategories;
  List<dynamic> get budgets => _budgets;
  List<dynamic> get auditLogs => _auditLogs;
  List<dynamic> get cheques => _cheques;
  List<dynamic> get tdsDeductions => _tdsDeductions;
  List<dynamic> get gstReturns => _gstReturns;
  List<dynamic> get priceLevels => _priceLevels;
  List<dynamic> get bankTransactions => _bankTransactions;
  List<dynamic> get bom => _bom;
  dynamic get activePosSession => _activePosSession;
  bool get isLoading => _isLoading;
  String get baseUrl => ApiConstants.baseUrl;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadCompanies() async {
    final r = await _api.get('$baseUrl/api/enterprise/companies');
    if (r.statusCode == 200) { _companies = jsonDecode(r.body); notifyListeners(); }
  }

  Future<bool> createCompany(Map<String, dynamic> data) async {
    final r = await _api.post('$baseUrl/api/enterprise/companies', body: data);
    if (r.statusCode == 200) { await loadCompanies(); return true; }
    return false;
  }

  Future<void> loadGodowns() async {
    final r = await _api.get('$baseUrl/api/enterprise/godowns');
    if (r.statusCode == 200) { _godowns = jsonDecode(r.body); notifyListeners(); }
  }

  Future<bool> createGodown(Map<String, dynamic> data) async {
    final r = await _api.post('$baseUrl/api/enterprise/godowns', body: data);
    if (r.statusCode == 200) { await loadGodowns(); return true; }
    return false;
  }

  Future<void> loadStockGroups() async {
    final r = await _api.get('$baseUrl/api/enterprise/stock-groups');
    if (r.statusCode == 200) { _stockGroups = jsonDecode(r.body); notifyListeners(); }
  }

  Future<void> loadBatches({int? productId}) async {
    final params = <String, String>{};
    if (productId != null) params['product_id'] = productId.toString();
    final r = await _api.get('$baseUrl/api/enterprise/batches', queryParams: params);
    if (r.statusCode == 200) { _batches = jsonDecode(r.body); notifyListeners(); }
  }

  Future<bool> createBatch(Map<String, dynamic> data) async {
    final r = await _api.post('$baseUrl/api/enterprise/batches', body: data);
    if (r.statusCode == 200) { await loadBatches(); return true; }
    return false;
  }

  Future<List<dynamic>> getExpiringBatches(int days) async {
    final r = await _api.get('$baseUrl/api/enterprise/batches/expiring', queryParams: {'days': days.toString()});
    if (r.statusCode == 200) return jsonDecode(r.body);
    return [];
  }

  Future<void> loadCostCenters() async {
    final r = await _api.get('$baseUrl/api/enterprise/cost-centers');
    if (r.statusCode == 200) { _costCenters = jsonDecode(r.body); notifyListeners(); }
  }

  Future<void> loadCostCategories() async {
    final r = await _api.get('$baseUrl/api/enterprise/cost-categories');
    if (r.statusCode == 200) { _costCategories = jsonDecode(r.body); notifyListeners(); }
  }

  Future<void> loadBudgets() async {
    final r = await _api.get('$baseUrl/api/enterprise/budgets');
    if (r.statusCode == 200) { _budgets = jsonDecode(r.body); notifyListeners(); }
  }

  Future<bool> createBudget(Map<String, dynamic> data) async {
    final r = await _api.post('$baseUrl/api/enterprise/budgets', body: data);
    if (r.statusCode == 200) { await loadBudgets(); return true; }
    return false;
  }

  Future<void> loadAuditLogs() async {
    final r = await _api.get('$baseUrl/api/enterprise/audit-logs');
    if (r.statusCode == 200) { _auditLogs = jsonDecode(r.body); notifyListeners(); }
  }

  Future<void> loadCheques({String? status}) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    final r = await _api.get('$baseUrl/api/enterprise/cheques', queryParams: params);
    if (r.statusCode == 200) { _cheques = jsonDecode(r.body); notifyListeners(); }
  }

  Future<bool> createCheque(Map<String, dynamic> data) async {
    final r = await _api.post('$baseUrl/api/enterprise/cheques', body: data);
    if (r.statusCode == 200) { await loadCheques(); return true; }
    return false;
  }

  Future<bool> updateChequeStatus(int id, Map<String, dynamic> data) async {
    final r = await _api.put('$baseUrl/api/enterprise/cheques/$id/status', body: data);
    if (r.statusCode == 200) { await loadCheques(); return true; }
    return false;
  }

  Future<void> loadTDS() async {
    final r = await _api.get('$baseUrl/api/enterprise/tds-deductions');
    if (r.statusCode == 200) { _tdsDeductions = jsonDecode(r.body); notifyListeners(); }
  }

  Future<Map<String, dynamic>?> getTDSReport() async {
    final r = await _api.get('$baseUrl/api/enterprise/tds-report');
    if (r.statusCode == 200) return jsonDecode(r.body);
    return null;
  }

  Future<void> loadGSTReturns() async {
    final r = await _api.get('$baseUrl/api/enterprise/gst/returns');
    if (r.statusCode == 200) { _gstReturns = jsonDecode(r.body); notifyListeners(); }
  }

  Future<Map<String, dynamic>?> generateGSTReturn(Map<String, dynamic> data) async {
    final r = await _api.post('$baseUrl/api/enterprise/gst/generate', body: data);
    if (r.statusCode == 200) { await loadGSTReturns(); return jsonDecode(r.body); }
    return null;
  }

  Future<void> loadPriceLevels() async {
    final r = await _api.get('$baseUrl/api/enterprise/price-levels');
    if (r.statusCode == 200) { _priceLevels = jsonDecode(r.body); notifyListeners(); }
  }

  Future<void> loadBankTransactions({int? accountId}) async {
    final params = <String, String>{};
    if (accountId != null) params['account_id'] = accountId.toString();
    final r = await _api.get('$baseUrl/api/enterprise/bank-transactions', queryParams: params);
    if (r.statusCode == 200) { _bankTransactions = jsonDecode(r.body); notifyListeners(); }
  }

  Future<void> loadBOM() async {
    final r = await _api.get('$baseUrl/api/enterprise/bom');
    if (r.statusCode == 200) { _bom = jsonDecode(r.body); notifyListeners(); }
  }

  Future<Map<String, dynamic>?> openPosSession(double openingBalance) async {
    final r = await _api.post('$baseUrl/api/enterprise/pos/session/open', body: {'opening_balance': openingBalance});
    if (r.statusCode == 200) { _activePosSession = jsonDecode(r.body); notifyListeners(); return _activePosSession; }
    return null;
  }

  Future<Map<String, dynamic>?> closePosSession(int id, Map<String, dynamic> data) async {
    final r = await _api.post('$baseUrl/api/enterprise/pos/session/close/$id', body: data);
    if (r.statusCode == 200) { _activePosSession = null; notifyListeners(); return jsonDecode(r.body); }
    return null;
  }

  Future<void> loadActivePosSession() async {
    final r = await _api.get('$baseUrl/api/enterprise/pos/active-session');
    if (r.statusCode == 200) { _activePosSession = jsonDecode(r.body); notifyListeners(); }
  }
}
