import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/env.dart';
import '../core/storage.dart';
import '../data/repositories.dart';

/// Disparado pelo ApiClient quando a API responde 401.
/// Evita dependencia circular entre o client e o controller de autenticacao.
class AuthEvents {
  AuthEvents._();

  static final instance = AuthEvents._();
  final ValueNotifier<int> unauthorized = ValueNotifier<int>(0);

  void notifyUnauthorized() => unauthorized.value++;
}

/// Sobrescrito no main() com a instancia já inicializada.
final storageProvider = Provider<Storage>((ref) {
  throw UnimplementedError('storageProvider precisa ser sobrescrito no main()');
});

/// Endereco da API em uso. No app web e sempre o valor de compilacao
/// (o nginx faz o proxy de /api). No APK o usuario pode apontar para o
/// proprio servidor, porque o IP da maquina muda.
class ServerUrlController extends Notifier<String> {
  @override
  String build() {
    final saved = ref.watch(storageProvider).serverUrl;
    final url = (saved == null || saved.isEmpty) ? Env.apiBaseUrl : saved;
    Env.activeBaseUrl = url;
    return url;
  }

  Future<void> set(String input) async {
    final url = Env.normalizeServerUrl(input);
    if (url == state) return;
    await ref.read(storageProvider).saveServerUrl(url);
    Env.activeBaseUrl = url;
    state = url;
  }

  Future<void> reset() async {
    await ref.read(storageProvider).clearServerUrl();
    Env.activeBaseUrl = Env.apiBaseUrl;
    state = Env.apiBaseUrl;
  }

  bool get isCustom => state != Env.apiBaseUrl;
}

final serverUrlProvider =
    NotifierProvider<ServerUrlController, String>(ServerUrlController.new);

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(storageProvider);
  final baseUrl = ref.watch(serverUrlProvider);
  return ApiClient(
    baseUrl: baseUrl,
    tokenReader: () => storage.token,
    onUnauthorized: () {
      if (storage.token != null) {
        AuthEvents.instance.notifyUnauthorized();
      }
    },
  );
});

final authRepositoryProvider = Provider((ref) => AuthRepository(ref.watch(apiClientProvider)));
final profileRepositoryProvider = Provider((ref) => ProfileRepository(ref.watch(apiClientProvider)));
final exerciseRepositoryProvider =
    Provider((ref) => ExerciseRepository(ref.watch(apiClientProvider)));
final workoutRepositoryProvider = Provider((ref) => WorkoutRepository(ref.watch(apiClientProvider)));
final sessionRepositoryProvider = Provider((ref) => SessionRepository(ref.watch(apiClientProvider)));
final statsRepositoryProvider = Provider((ref) => StatsRepository(ref.watch(apiClientProvider)));
final syncRepositoryProvider = Provider((ref) => SyncRepository(ref.watch(apiClientProvider)));
