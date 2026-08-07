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

  /// O backend devolve caminhos relativos como `/api/media/<hash>`.
  /// Aqui convertemos para a URL absoluta correta em qualquer ambiente.
  static String? resolveMedia(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    if (path.startsWith('/api/')) {
      return '$apiBaseUrl${path.substring(4)}';
    }
    if (path.startsWith('/')) {
      return '$apiBaseUrl$path';
    }
    return '$apiBaseUrl/$path';
  }
}
