import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';

class SearchProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  List<dynamic> _results = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get results => _results;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      _results = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.get(ApiConstants.search, queryParams: {'query': query});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _results = data['results'];
      }
    } catch (e) {
      _results = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  void clear() {
    _results = [];
    notifyListeners();
  }
}
