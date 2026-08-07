import 'package:shared_preferences/shared_preferences.dart';

/// Persistencia local simples (token JWT e preferencia de tema).
class Storage {
  Storage(this._prefs);

  static const _tokenKey = 'auth_token';
  static const _themeKey = 'theme_mode';

  final SharedPreferences _prefs;

  static Future<Storage> create() async => Storage(await SharedPreferences.getInstance());

  String? get token => _prefs.getString(_tokenKey);

  Future<void> saveToken(String token) => _prefs.setString(_tokenKey, token);

  Future<void> clearToken() => _prefs.remove(_tokenKey);

  /// 'light' | 'dark' | 'system'
  String get themeMode => _prefs.getString(_themeKey) ?? 'system';

  Future<void> saveThemeMode(String mode) => _prefs.setString(_themeKey, mode);
}
