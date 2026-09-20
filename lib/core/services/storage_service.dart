import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  StorageService._();
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static const _kToken = 'auth_token';
  static const _kUser = 'auth_user';

  static Future<void> setToken(String token) async {
    await init();
    await _prefs!.setString(_kToken, token);
  }

  static String? getToken() => _prefs?.getString(_kToken);

  static Future<void> setUser(String userJson) async {
    await init();
    await _prefs!.setString(_kUser, userJson);
  }

  static String? getUser() => _prefs?.getString(_kUser);

  static Future<void> clear() async {
    await init();
    await _prefs!.remove(_kToken);
    await _prefs!.remove(_kUser);
  }
}
