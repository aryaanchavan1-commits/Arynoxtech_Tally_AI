import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../data/models/customer_model.dart';

class CustomerProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  List<CustomerModel> _customers = [];
  bool _isLoading = false;
  String? _error;

  List<CustomerModel> get customers => _customers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadCustomers({String? search}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final params = <String, String>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      final response = await _api.get(ApiConstants.customers, queryParams: params);
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        _customers = list.map((e) => CustomerModel.fromJson(e)).toList();
      }
    } catch (e) {
      _error = 'Failed to load customers';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createCustomer(Map<String, dynamic> data) async {
    try {
      final response = await _api.post(ApiConstants.customers, body: data);
      if (response.statusCode == 201) {
        await loadCustomers();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getCustomerStatement(int id) async {
    try {
      final response = await _api.get('${ApiConstants.customers}/$id/statement');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
