/// Configuracao de ambiente do app.
///
/// Em dev o app fala direto com o backend em localhost:8080.
/// No build do Docker passamos `--dart-define=API_BASE_URL=/api`, porque o
/// nginx faz o proxy de /api para o container da API (sem CORS).
class Env {
  const Env._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api',
  );

  /// Base efetiva da API. No APK o usuario pode apontar para o proprio
  /// servidor, entao o valor de compilacao e apenas o padrao.
  static String activeBaseUrl = apiBaseUrl;

  /// O backend devolve caminhos relativos como `/api/media/<hash>`.
  /// Aqui convertemos para a URL absoluta correta em qualquer ambiente.
  static String? resolveMedia(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final base = activeBaseUrl;
    if (path.startsWith('/api/')) {
      return '$base${path.substring(4)}';
    }
    if (path.startsWith('/')) {
      return '$base$path';
    }
    return '$base/$path';
  }

  /// Normaliza o que o usuario digitar: aceita "192.168.0.8:8080",
  /// "http://host" ou a URL completa terminando em /api.
  static String normalizeServerUrl(String input) {
    var value = input.trim();
    if (value.isEmpty) return apiBaseUrl;
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      value = 'http://$value';
    }
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    if (!value.endsWith('/api')) {
      value = '$value/api';
    }
    return value;
  }
}
