import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';

class BackupProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  List<dynamic> _backups = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get backups => _backups;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadBackups() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.get(ApiConstants.backupList);
      if (response.statusCode == 200) {
        _backups = jsonDecode(response.body);
      }
    } catch (e) {
      _error = 'Failed to load backups';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createBackup({String description = ''}) async {
    try {
      final response = await _api.post(ApiConstants.backupCreate, body: {
        'description': description,
      });
      if (response.statusCode == 200) {
        await loadBackups();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> restoreBackup(int id) async {
    try {
      final response = await _api.post('${ApiConstants.backupRestore}/$id');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteBackup(int id) async {
    try {
      final response = await _api.delete('${ApiConstants.baseUrl}/api/backup/$id');
      if (response.statusCode == 200) {
        await loadBackups();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
