import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final storage = const FlutterSecureStorage();
  String? _token;

  Future<String?> get token async {
    _token ??= await storage.read(key: 'auth_token');
    return _token;
  }

  Future<void> setToken(String token) async {
    _token = token;
    await storage.write(key: 'auth_token', value: token);
  }

  Future<void> clearToken() async {
    _token = null;
    await storage.delete(key: 'auth_token');
  }

  Future<Map<String, String>> _headers() async {
    final t = await token;
    return {
      'Content-Type': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    };
  }

  Future<http.Response> get(String url, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse(url).replace(queryParameters: queryParams);
    return http.get(uri, headers: await _headers());
  }

  Future<http.Response> post(String url, {Map<String, dynamic>? body}) async {
    return http.post(Uri.parse(url), headers: await _headers(), body: body != null ? jsonEncode(body) : null);
  }

  Future<http.Response> put(String url, {Map<String, dynamic>? body}) async {
    return http.put(Uri.parse(url), headers: await _headers(), body: body != null ? jsonEncode(body) : null);
  }

  Future<http.Response> delete(String url) async {
    return http.delete(Uri.parse(url), headers: await _headers());
  }

  Future<http.Response> uploadFile(String url, String filePath, String fieldName) async {
    final t = await token;
    final request = http.MultipartRequest('POST', Uri.parse(url));
    if (t != null) request.headers['Authorization'] = 'Bearer $t';
    request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));
    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }

  Future<http.Response> uploadBytes(String url, List<int> bytes, String fieldName, String filename) async {
    final t = await token;
    final request = http.MultipartRequest('POST', Uri.parse(url));
    if (t != null) request.headers['Authorization'] = 'Bearer $t';
    request.files.add(http.MultipartFile.fromBytes(fieldName, bytes, filename: filename));
    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }

  Future<http.Response> getAudio(String url) async {
    final t = await token;
    final headers = <String, String>{};
    if (t != null) headers['Authorization'] = 'Bearer $t';
    return http.get(Uri.parse(url), headers: headers);
  }
}
