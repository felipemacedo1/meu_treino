import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../models/user.dart';
import 'providers.dart';

enum AuthStatus { checking, signedOut, signedIn }

@immutable
class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.error,
    this.offline = false,
  });

  final AuthStatus status;
  final AppUser? user;
  final String? error;

  /// Sessão restaurada do cache local porque o servidor não respondeu.
  /// O app continua utilizável com o que estiver em cache.
  final bool offline;

  bool get isSignedIn => status == AuthStatus.signedIn;
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    final storage = ref.watch(storageProvider);

    void handleUnauthorized() {
      if (state.status != AuthStatus.signedOut) {
        storage.clearToken();
        state = const AuthState(status: AuthStatus.signedOut, error: 'Sua sessão expirou.');
      }
    }

    AuthEvents.instance.unauthorized.addListener(handleUnauthorized);
    ref.onDispose(() => AuthEvents.instance.unauthorized.removeListener(handleUnauthorized));

    if (storage.token == null) {
      return const AuthState(status: AuthStatus.signedOut);
    }
    Future.microtask(_restore);
    return const AuthState(status: AuthStatus.checking);
  }

  /// Restaura a sessão na abertura do app.
  ///
  /// Só desloga quando o servidor **diz** que o token não vale mais (401).
  /// Falha de rede não pode expulsar o usuário: o token dura 60 dias e o
  /// cenário normal é justamente abrir o app na academia, sem sinal.
  Future<void> _restore() async {
    final storage = ref.read(storageProvider);
    final cached = _cachedUser(storage.userJson);

    try {
      final user = await ref.read(authRepositoryProvider).me();
      await storage.saveUserJson(jsonEncode(user.toJson()));
      state = AuthState(status: AuthStatus.signedIn, user: user);
    } on ApiException catch (error) {
      if (error.isUnauthorized) {
        await storage.clearToken();
        state = const AuthState(
          status: AuthStatus.signedOut,
          error: 'Sua sessão expirou. Entre novamente.',
        );
        return;
      }
      _keepOfflineSession(cached);
    } catch (_) {
      _keepOfflineSession(cached);
    }
  }

  /// Sem resposta do servidor: mantém a sessão com o que está salvo localmente.
  void _keepOfflineSession(AppUser? cached) {
    if (cached == null) {
      // Nunca guardamos o usuário (login antigo): sem como seguir offline.
      state = const AuthState(
        status: AuthStatus.signedOut,
        error: 'Não foi possível falar com o servidor.',
      );
      return;
    }
    state = AuthState(status: AuthStatus.signedIn, user: cached, offline: true);
  }

  AppUser? _cachedUser(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      return AppUser.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    final result = await ref.read(authRepositoryProvider).login(email, password);
    final storage = ref.read(storageProvider);
    await storage.saveToken(result.token);
    await storage.saveUserJson(jsonEncode(result.user.toJson()));
    state = AuthState(status: AuthStatus.signedIn, user: result.user);
  }

  Future<void> register(String name, String email, String password) async {
    final result = await ref.read(authRepositoryProvider).register(name, email, password);
    final storage = ref.read(storageProvider);
    await storage.saveToken(result.token);
    await storage.saveUserJson(jsonEncode(result.user.toJson()));
    state = AuthState(status: AuthStatus.signedIn, user: result.user);
  }

  Future<void> logout() async {
    await ref.read(storageProvider).clearToken();
    state = const AuthState(status: AuthStatus.signedOut);
  }

  /// Nova tentativa de contato com o servidor, para sair do modo offline.
  Future<void> retryOnline() async {
    if (state.status == AuthStatus.signedOut) return;
    await _restore();
  }

  void updateUserName(String name) {
    final user = state.user;
    if (user == null) return;
    final updated = AppUser(
      id: user.id,
      name: name,
      email: user.email,
      createdAt: user.createdAt,
    );
    ref.read(storageProvider).saveUserJson(jsonEncode(updated.toJson()));
    state = AuthState(status: state.status, user: updated, offline: state.offline);
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
