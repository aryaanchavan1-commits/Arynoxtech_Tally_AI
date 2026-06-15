import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';

class AIProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  Map<String, dynamic>? _settings;
  List<dynamic> _providers = [];
  bool _isLoading = false;
  bool _voiceProcessing = false;
  bool _uploading = false;
  String? _error;
  final List<ChatMessage> _messages = [];
  String _currentProcessingActionId = '';

  Map<String, dynamic>? get settings => _settings;
  List<dynamic> get providers => _providers;
  bool get isLoading => _isLoading;
  bool get voiceProcessing => _voiceProcessing;
  bool get uploading => _uploading;
  String get currentProcessingActionId => _currentProcessingActionId;
  List<ChatMessage> get messages => _messages;
  String? get error => _error;

  bool get sttSupported {
    if (_settings == null) return false;
    final p = _providers.cast<Map<String, dynamic>>().where((p) => p['id'] == _settings!['provider']).firstOrNull;
    return p?['stt_supported'] == true;
  }

  bool get ttsSupported {
    if (_settings == null) return false;
    final p = _providers.cast<Map<String, dynamic>>().where((p) => p['id'] == _settings!['provider']).firstOrNull;
    return p?['tts_supported'] == true;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadSettings() async {
    try {
      final response = await _api.get(ApiConstants.aiSettings);
      if (response.statusCode == 200) {
        _settings = jsonDecode(response.body);
      }
    } catch (e) {
      _error = 'Failed to load AI settings';
    }
    notifyListeners();
  }

  Future<void> loadProviders() async {
    try {
      final response = await _api.get(ApiConstants.aiProviders);
      if (response.statusCode == 200) {
        _providers = jsonDecode(response.body)['providers'];
      }
    } catch (e) {
      _error = 'Failed to load AI providers';
    }
    notifyListeners();
  }

  Future<bool> saveSettings(Map<String, dynamic> data) async {
    try {
      final response = await _api.post(ApiConstants.aiSettings, body: data);
      if (response.statusCode == 200) {
        await loadSettings();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteSettings() async {
    try {
      final response = await _api.delete(ApiConstants.aiSettings);
      if (response.statusCode == 200) {
        _settings = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> testConnection(Map<String, dynamic> data) async {
    try {
      final response = await _api.post(ApiConstants.aiTest, body: data);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> sendMessage(String message, {bool includeData = false}) async {
    _messages.add(ChatMessage(role: 'user', content: message));
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.post(ApiConstants.aiChat, body: {
        'message': message,
        'include_business_data': includeData,
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _messages.add(ChatMessage(role: 'assistant', content: data['response']));
      } else {
        _messages.add(ChatMessage(role: 'assistant', content: 'Error: Unable to get response'));
      }
    } catch (e) {
      _messages.add(ChatMessage(role: 'assistant', content: 'Connection error. Please check your AI settings.'));
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> pickAndUploadFiles() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );
    if (result == null || result.files.isEmpty) return null;

    _uploading = true;
    notifyListeners();

    try {
      final request = http.MultipartRequest('POST', Uri.parse(ApiConstants.aiUpload));
      final t = await _api.token;
      if (t != null) request.headers['Authorization'] = 'Bearer $t';

      for (final file in result.files) {
        if (file.path != null) {
          request.files.add(await http.MultipartFile.fromPath('files', file.path!));
        } else if (file.bytes != null) {
          request.files.add(http.MultipartFile.fromBytes('files', file.bytes!, filename: file.name));
        }
      }
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        final fileInfo = data.map((e) => {
          'file_id': e['file_id'],
          'filename': e['filename'],
          'size': e['size'],
          'preview': e['preview'],
        }).toList();

        final fileNames = fileInfo.map((f) => f['filename'] as String).join(', ');
        _messages.add(ChatMessage(
          role: 'user',
          content: '📎 Uploaded: $fileNames',
          files: fileInfo,
        ));
        notifyListeners();
        return {
          'files': fileInfo,
          'fileIds': fileInfo.map((f) => f['file_id'] as String).toList(),
        };
      }
      return null;
    } catch (e) {
      _error = 'Upload failed: $e';
      return null;
    } finally {
      _uploading = false;
      notifyListeners();
    }
  }

  Future<void> sendAgentMessage(String message, {List<String>? fileIds}) async {
    final history = _messages.map((m) => {
      'role': m.role == 'user' ? 'user' : 'assistant',
      'content': m.content,
    }).toList();

    _messages.add(ChatMessage(role: 'user', content: message));
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.post(ApiConstants.aiAgent, body: {
        'message': message,
        'history': history.take(20).toList(),
        'file_ids': fileIds ?? [],
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['type'] == 'agent_action') {
          final actions = (data['actions'] as List).map((a) => AgentAction(
            action: a['action'],
            params: Map<String, dynamic>.from(a['params']),
            description: a['description'],
          )).toList();
          _messages.add(ChatMessage(
            role: 'assistant',
            content: data['response'] ?? '',
            actions: actions,
          ));
        } else {
          _messages.add(ChatMessage(role: 'assistant', content: data['response'] ?? ''));
        }
      } else {
        _messages.add(ChatMessage(role: 'assistant', content: 'Error: Unable to get response'));
      }
    } catch (e) {
      _messages.add(ChatMessage(role: 'assistant', content: 'Connection error. Please check your AI settings.'));
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> confirmAction(String action, Map<String, dynamic> params) async {
    _currentProcessingActionId = '${action}_${DateTime.now().millisecondsSinceEpoch}';
    notifyListeners();

    try {
      final response = await _api.post(ApiConstants.aiAgentExecute, body: {
        'action': action,
        'params': params,
      });
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final success = result['success'] == true;
        _messages.add(ChatMessage(
          role: 'assistant',
          content: success
              ? '✅ ${result['message']}'
              : '❌ ${result['message']}',
        ));
        return success;
      }
      _messages.add(ChatMessage(role: 'assistant', content: '❌ Action execution failed'));
      return false;
    } catch (e) {
      _messages.add(ChatMessage(role: 'assistant', content: '❌ Error: $e'));
      return false;
    } finally {
      _currentProcessingActionId = '';
      notifyListeners();
    }
  }

  Future<String?> transcribeAudio(List<int> audioBytes) async {
    _voiceProcessing = true;
    notifyListeners();

    try {
      final response = await _api.uploadBytes(
        ApiConstants.aiVoiceInput,
        audioBytes,
        'file',
        'voice_input.wav',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['transcript'] as String?;
      } else {
        _error = 'Transcription failed';
        return null;
      }
    } catch (e) {
      _error = 'Transcription error: $e';
      return null;
    } finally {
      _voiceProcessing = false;
      notifyListeners();
    }
  }

  Future<String?> getAudioUrl(String text) async {
    try {
      final response = await _api.post(ApiConstants.aiVoiceOutput, body: {
        'text': text,
        'voice': 'alloy',
      });
      if (response.statusCode == 200) {
        return response.body;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> clearMessages() {
    _messages.clear();
    notifyListeners();
    return Future.value();
  }
}

class AgentAction {
  final String action;
  final Map<String, dynamic> params;
  final String description;

  AgentAction({
    required this.action,
    required this.params,
    required this.description,
  });
}

class ChatMessage {
  final String role;
  final String content;
  final List<Map<String, dynamic>>? files;
  final List<AgentAction>? actions;
  final bool actionCompleted;

  ChatMessage({
    required this.role,
    required this.content,
    this.files,
    this.actions,
    this.actionCompleted = false,
  });
}
