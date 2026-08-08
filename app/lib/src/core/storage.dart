import 'package:shared_preferences/shared_preferences.dart';

/// Persistencia local simples: token JWT e tema escolhido.
///
/// O tema fica salvo localmente para ser aplicado imediatamente na abertura do
/// app, sem esperar a resposta da API. O perfil do usuario guarda a mesma
/// preferencia no servidor, para acompanhar a conta em outro dispositivo.
class Storage {
  Storage(this._prefs);

  static const _tokenKey = 'auth_token';
  static const _themeKey = 'theme_id';
  static const _serverKey = 'server_url';

  final SharedPreferences _prefs;

  static Future<Storage> create() async => Storage(await SharedPreferences.getInstance());

  String? get token => _prefs.getString(_tokenKey);

  Future<void> saveToken(String token) => _prefs.setString(_tokenKey, token);

  Future<void> clearToken() => _prefs.remove(_tokenKey);

  /// Identificador do tema (ver AppThemes). Null na primeira execucao.
  String? get themeId => _prefs.getString(_themeKey);

  Future<void> saveThemeId(String id) => _prefs.setString(_themeKey, id);

  /// Endereco da API. Null usa o valor de compilacao (Env.apiBaseUrl).
  /// Necessario no APK: o servidor roda na maquina do usuario, e o IP muda.
  String? get serverUrl => _prefs.getString(_serverKey);

  Future<void> saveServerUrl(String url) => _prefs.setString(_serverKey, url);

  Future<void> clearServerUrl() => _prefs.remove(_serverKey);
}
