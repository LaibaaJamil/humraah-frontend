import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  Map<String, String> _headers({bool auth = true, bool json = true}) {
    final h = <String, String>{};
    if (json) h['Content-Type'] = 'application/json';
    if (auth) {
      final t = StorageService.getToken();
      if (t != null && t.isNotEmpty) h['Authorization'] = 'Bearer $t';
    }
    return h;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final url = '${ApiConstants.apiBase}$path';

    print('API URL = $url');

    return Uri.parse(url).replace(
      queryParameters: query?.map(
        (k, v) => MapEntry(k, v.toString()),
      ),
    );
  }

  Future<Map<String, dynamic>> get(String path,
      {Map<String, dynamic>? query}) async {
    try {
      final res = await http
          .get(_uri(path, query), headers: _headers())
          .timeout(const Duration(seconds: 30));
      return _handle(res);
    } on SocketException {
      throw ApiException('Cannot reach server. Is the backend running?');
    }
  }

  Future<Map<String, dynamic>> post(String path, {Object? body}) async {
    try {
      final res = await http
          .post(_uri(path), headers: _headers(), body: jsonEncode(body ?? {}))
          .timeout(const Duration(seconds: 30));
      return _handle(res);
    } on SocketException {
      throw ApiException('Cannot reach server. Is the backend running?');
    }
  }

  Future<Map<String, dynamic>> put(String path, {Object? body}) async {
    try {
      final res = await http
          .put(_uri(path), headers: _headers(), body: jsonEncode(body ?? {}))
          .timeout(const Duration(seconds: 30));
      return _handle(res);
    } on SocketException {
      throw ApiException('Cannot reach server. Is the backend running?');
    }
  }

  Future<Map<String, dynamic>> patch(String path, {Object? body}) async {
    try {
      final res = await http
          .patch(_uri(path), headers: _headers(), body: jsonEncode(body ?? {}))
          .timeout(const Duration(seconds: 30));
      return _handle(res);
    } on SocketException {
      throw ApiException('Cannot reach server. Is the backend running?');
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final res = await http
          .delete(_uri(path), headers: _headers())
          .timeout(const Duration(seconds: 30));
      return _handle(res);
    } on SocketException {
      throw ApiException('Cannot reach server. Is the backend running?');
    }
  }

  Future<Map<String, dynamic>> uploadFile(
    String path, {
    required String fieldName,
    required List<int> bytes,
    required String filename,
    Map<String, String>? fields,
  }) async {
    try {
      final req = http.MultipartRequest('POST', _uri(path));
      final t = StorageService.getToken();
      if (t != null && t.isNotEmpty) req.headers['Authorization'] = 'Bearer $t';
      if (fields != null) req.fields.addAll(fields);
      req.files.add(
        http.MultipartFile.fromBytes(fieldName, bytes, filename: filename),
      );
      final streamed = await req.send().timeout(const Duration(minutes: 5));
      final res = await http.Response.fromStream(streamed);
      return _handle(res);
    } on SocketException {
      throw ApiException('Cannot reach server. Is the backend running?');
    }
  }

  Map<String, dynamic> _handle(http.Response res) {
    Map<String, dynamic> body = {};
    try {
      body =
          res.body.isEmpty ? {} : jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      body = {'message': res.body};
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return body;

    final msg = body['message']?.toString() ??
        'Request failed with status ${res.statusCode}';
    throw ApiException(msg, res.statusCode);
  }
}
