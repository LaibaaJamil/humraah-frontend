import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../core/services/api_service.dart';
import '../core/services/storage_service.dart';
import '../models/user.dart';
import '../core/services/socket_service.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  bool _loading = false;
  String? _error;

  AppUser? get user => _user;
  bool get canUploadResource =>
      _user != null &&
      (_user!.role == 'ngo_admin' || _user!.role == 'ngo_staff');
  bool get loading => _loading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<void> bootstrap() async {
    await StorageService.init();
    final cached = StorageService.getUser();
    if (cached != null) {
      try {
        _user = AppUser.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      } catch (_) {}
    }
    if (StorageService.getToken() != null) {
      try {
        final res = await ApiService.instance.get(ApiConstants.me);
        final u = res['data']['user'] as Map<String, dynamic>;
        _user = AppUser.fromJson(u);
        await StorageService.setUser(jsonEncode(u));
      } catch (_) {
        await logout();
      }
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      final res = await ApiService.instance.post(
        ApiConstants.login,
        body: {'email': email, 'password': password},
      );

      final token = res['token'] ?? res['data']?['token'];
      final user = res['user'] ?? res['data']?['user'];

      if (token == null || user == null) {
        throw Exception("Invalid response format from server");
      }

      await StorageService.setToken(token.toString());
      await StorageService.setUser(jsonEncode(user));

      _user = AppUser.fromJson(user as Map<String, dynamic>);
      SocketService.connect(_user!.id);

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String role = 'ngo_staff',
    Map<String, dynamic>? ngoData,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final body = <String, dynamic>{
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role,
      };
      if (ngoData != null) body['ngoData'] = ngoData;

      final res =
          await ApiService.instance.post(ApiConstants.register, body: body);
      final data = res['data'] as Map<String, dynamic>;
      await StorageService.setToken(data['token'].toString());
      await StorageService.setUser(jsonEncode(data['user']));
      _user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
      SocketService.connect(_user!.id);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      await StorageService.clear();
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    SocketService.disconnect();
    await StorageService.clear();
    _user = null;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    try {
      final res = await ApiService.instance.get(ApiConstants.me);
      final u = res['data']['user'] as Map<String, dynamic>;
      _user = AppUser.fromJson(u);
      await StorageService.setUser(jsonEncode(u));
      notifyListeners();
    } catch (_) {}
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }
}
