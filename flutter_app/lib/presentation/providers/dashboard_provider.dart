import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _chartData;
  List<dynamic> _topCustomers = [];
  List<dynamic> _topProducts = [];
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get summary => _summary;
  Map<String, dynamic>? get chartData => _chartData;
  List<dynamic> get topCustomers => _topCustomers;
  List<dynamic> get topProducts => _topProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadDashboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      final summaryRes = await _api.get(ApiConstants.dashboardSummary);
      if (summaryRes.statusCode == 200) {
        _summary = jsonDecode(summaryRes.body);
      }

      final chartRes = await _api.get(ApiConstants.dashboardChart);
      if (chartRes.statusCode == 200) {
        _chartData = jsonDecode(chartRes.body);
      }

      final topCustRes = await _api.get(ApiConstants.topCustomers);
      if (topCustRes.statusCode == 200) {
        _topCustomers = jsonDecode(topCustRes.body);
      }

      final topProdRes = await _api.get(ApiConstants.topProducts);
      if (topProdRes.statusCode == 200) {
        _topProducts = jsonDecode(topProdRes.body);
      }
    } catch (e) {
      _error = 'Failed to load dashboard data';
    }

    _isLoading = false;
    notifyListeners();
  }
}
