import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../data/models/invoice_model.dart';

class InvoiceProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  List<InvoiceModel> _invoices = [];
  bool _isLoading = false;
  String? _error;

  List<InvoiceModel> get invoices => _invoices;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadInvoices({String? status, String? dateFrom, String? dateTo}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final params = <String, String>{};
      if (status != null) params['status'] = status;
      if (dateFrom != null) params['date_from'] = dateFrom;
      if (dateTo != null) params['date_to'] = dateTo;

      final response = await _api.get(ApiConstants.invoices, queryParams: params);
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        _invoices = list.map((e) => InvoiceModel.fromJson(e)).toList();
      }
    } catch (e) {
      _error = 'Failed to load invoices';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createInvoice(Map<String, dynamic> data) async {
    try {
      final response = await _api.post(ApiConstants.invoices, body: data);
      if (response.statusCode == 201) {
        await loadInvoices();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
