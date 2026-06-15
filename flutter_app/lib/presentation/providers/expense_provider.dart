import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';

class ExpenseProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  List<dynamic> _expenses = [];
  List<dynamic> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get expenses => _expenses;
  List<dynamic> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadExpenses({int? categoryId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final params = <String, String>{};
      if (categoryId != null) params['category_id'] = categoryId.toString();

      final response = await _api.get(ApiConstants.expenses, queryParams: params);
      if (response.statusCode == 200) {
        _expenses = jsonDecode(response.body);
      }
    } catch (e) {
      _error = 'Failed to load expenses';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    try {
      final response = await _api.get(ApiConstants.expenseCategories);
      if (response.statusCode == 200) {
        _categories = jsonDecode(response.body);
      }
    } catch (e) {
      _error = 'Failed to load expense categories';
    }
    notifyListeners();
  }

  Future<bool> createExpense(Map<String, dynamic> data) async {
    try {
      final response = await _api.post(ApiConstants.expenses, body: data);
      if (response.statusCode == 201) {
        await loadExpenses();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createCategory(Map<String, dynamic> data) async {
    try {
      final response = await _api.post(ApiConstants.expenseCategories, body: data);
      if (response.statusCode == 201) {
        await loadCategories();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
