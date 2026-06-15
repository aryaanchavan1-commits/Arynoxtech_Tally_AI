import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../data/models/product_model.dart';

class InventoryProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  List<ProductModel> _products = [];
  List<dynamic> _categories = [];
  List<dynamic> _lowStockItems = [];
  bool _isLoading = false;
  String? _error;

  List<ProductModel> get products => _products;
  List<dynamic> get categories => _categories;
  List<dynamic> get lowStockItems => _lowStockItems;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadProducts({String? search, int? categoryId, bool? lowStock}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final params = <String, String>{};
      if (search != null) params['search'] = search;
      if (categoryId != null) params['category_id'] = categoryId.toString();
      if (lowStock == true) params['low_stock'] = 'true';

      final response = await _api.get(ApiConstants.inventoryProducts, queryParams: params);
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        _products = list.map((e) => ProductModel.fromJson(e)).toList();
      }
    } catch (e) {
      _error = 'Failed to load products';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    try {
      final response = await _api.get(ApiConstants.inventoryCategories);
      if (response.statusCode == 200) {
        _categories = jsonDecode(response.body);
      }
    } catch (e) {
      _error = 'Failed to load categories';
    }
    notifyListeners();
  }

  Future<void> loadLowStock() async {
    try {
      final response = await _api.get(ApiConstants.lowStock);
      if (response.statusCode == 200) {
        _lowStockItems = jsonDecode(response.body);
      }
    } catch (e) {
      _error = 'Failed to load low stock items';
    }
    notifyListeners();
  }

  Future<bool> createProduct(Map<String, dynamic> data) async {
    try {
      final response = await _api.post(ApiConstants.inventoryProducts, body: data);
      if (response.statusCode == 201) {
        await loadProducts();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createCategory(Map<String, dynamic> data) async {
    try {
      final response = await _api.post(ApiConstants.inventoryCategories, body: data);
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
