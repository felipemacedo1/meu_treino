import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
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

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(storageProvider);
  return ApiClient(
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
