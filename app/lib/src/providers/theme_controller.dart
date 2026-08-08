import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/theme.dart';
import 'auth_controller.dart';
import 'providers.dart';

/// Controla o tema visual ativo.
///
/// Estratégia de persistência:
/// - **local** (`shared_preferences`): fonte da verdade para aplicar o tema
///   imediatamente na abertura, sem depender da rede;
/// - **perfil do usuário** (`PUT /api/profile`): guarda a mesma preferência no
///   servidor para acompanhar a conta em outro dispositivo.
///
/// A escrita no servidor é "melhor esforço": se falhar, o tema local continua
/// valendo e nada quebra na interface.
class ThemeController extends Notifier<ThemeDefinition> {
  @override
  ThemeDefinition build() {
    final storage = ref.watch(storageProvider);

    // Quando o usuário entra, busca a preferência salva na conta.
    ref.listen(authControllerProvider, (previous, next) {
      final wasSignedIn = previous?.isSignedIn ?? false;
      if (next.isSignedIn && !wasSignedIn) {
        Future.microtask(_pullFromProfile);
      }
    });

    return AppThemes.byId(storage.themeId);
  }

  /// Aplica o tema na hora, persiste local e tenta sincronizar com a conta.
  Future<void> select(String themeId) async {
    final definition = AppThemes.byId(themeId);
    if (definition.id == state.id) return;

    state = definition;
    await ref.read(storageProvider).saveThemeId(definition.id);
    _pushToProfile(definition.id);
  }

  /// Lê o tema salvo na conta e adota se o usuário nunca escolheu localmente
  /// ou se a preferência do servidor for diferente.
  Future<void> _pullFromProfile() async {
    try {
      final profile = await ref.read(profileRepositoryProvider).get();
      final remoteId = profile.theme;
      if (remoteId == null || remoteId.isEmpty) {
        // Conta ainda sem preferência: publica a local para não perder a escolha.
        _pushToProfile(state.id);
        return;
      }
      final definition = AppThemes.byId(remoteId);
      if (definition.id != state.id) {
        state = definition;
        await ref.read(storageProvider).saveThemeId(definition.id);
      }
    } catch (_) {
      // Sem rede ou sem perfil: o tema local continua valendo.
    }
  }

  void _pushToProfile(String themeId) {
    ref.read(profileRepositoryProvider).update({'theme': themeId}).ignore();
  }
}

final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeDefinition>(ThemeController.new);
