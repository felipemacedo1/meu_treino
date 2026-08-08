import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import 'providers.dart';

enum AuthStatus { checking, signedOut, signedIn }

@immutable
class AuthState {
  const AuthState({required this.status, this.user, this.error});

  final AuthStatus status;
  final AppUser? user;
  final String? error;

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

  Future<void> _restore() async {
    try {
      final user = await ref.read(authRepositoryProvider).me();
      state = AuthState(status: AuthStatus.signedIn, user: user);
    } catch (_) {
      await ref.read(storageProvider).clearToken();
      state = const AuthState(status: AuthStatus.signedOut);
    }
  }

  Future<void> login(String email, String password) async {
    final result = await ref.read(authRepositoryProvider).login(email, password);
    await ref.read(storageProvider).saveToken(result.token);
    state = AuthState(status: AuthStatus.signedIn, user: result.user);
  }

  Future<void> register(String name, String email, String password) async {
    final result = await ref.read(authRepositoryProvider).register(name, email, password);
    await ref.read(storageProvider).saveToken(result.token);
    state = AuthState(status: AuthStatus.signedIn, user: result.user);
  }

  Future<void> logout() async {
    await ref.read(storageProvider).clearToken();
    state = const AuthState(status: AuthStatus.signedOut);
  }

  void updateUserName(String name) {
    final user = state.user;
    if (user == null) return;
    state = AuthState(
      status: state.status,
      user: AppUser(id: user.id, name: name, email: user.email, createdAt: user.createdAt),
    );
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
