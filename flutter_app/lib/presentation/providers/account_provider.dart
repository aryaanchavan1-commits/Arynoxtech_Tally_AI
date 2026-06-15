import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../data/models/account_model.dart';

class AccountProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  List<AccountModel> _accounts = [];
  bool _isLoading = false;
  String? _error;

  List<AccountModel> get accounts => _accounts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadAccounts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.get(ApiConstants.accounts);
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        _accounts = list.map((e) => AccountModel.fromJson(e)).toList();
      }
    } catch (e) {
      _error = 'Failed to load accounts';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createAccount(Map<String, dynamic> data) async {
    try {
      final response = await _api.post(ApiConstants.accounts, body: data);
      if (response.statusCode == 201) {
        await loadAccounts();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAccount(int id) async {
    try {
      final response = await _api.delete('${ApiConstants.accounts}/$id');
      if (response.statusCode == 200) {
        await loadAccounts();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
