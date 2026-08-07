import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_page.dart';
import '../features/auth/register_page.dart';
import '../features/exercises/exercise_detail_page.dart';
import '../features/history/session_detail_page.dart';
import '../features/onboarding/onboarding_page.dart';
import '../features/session/active_session_page.dart';
import '../features/shell/home_shell.dart';
import '../features/workouts/workout_detail_page.dart';
import '../features/workouts/workout_editor_page.dart';
import '../providers/auth_controller.dart';

class AppRoutes {
  const AppRoutes._();

  static const login = '/login';
  static const register = '/register';
  static const onboarding = '/onboarding';
  static const home = '/';
  static const session = '/session';
  static String workout(int id) => '/workouts/$id';
  static String workoutEdit(int id) => '/workouts/$id/edit';
  static const workoutNew = '/workouts/new';
  static String exercise(int id) => '/exercises/$id';
  static String sessionDetail(int id) => '/sessions/$id';
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final path = state.matchedLocation;
      final isAuthRoute = path == AppRoutes.login || path == AppRoutes.register;

      if (auth.status == AuthStatus.checking) return null;
      if (!auth.isSignedIn) return isAuthRoute ? null : AppRoutes.login;
      if (isAuthRoute) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginPage()),
      GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterPage()),
      GoRoute(path: AppRoutes.onboarding, builder: (_, __) => const OnboardingPage()),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, state) {
          final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
          return HomeShell(initialTab: tab);
        },
      ),
      GoRoute(path: AppRoutes.session, builder: (_, __) => const ActiveSessionPage()),
      GoRoute(path: AppRoutes.workoutNew, builder: (_, __) => const WorkoutEditorPage()),
      GoRoute(
        path: '/workouts/:id',
        builder: (_, state) =>
            WorkoutDetailPage(workoutId: int.parse(state.pathParameters['id']!)),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, state) =>
                WorkoutEditorPage(workoutId: int.parse(state.pathParameters['id']!)),
          ),
        ],
      ),
      GoRoute(
        path: '/exercises/:id',
        builder: (_, state) =>
            ExerciseDetailPage(exerciseId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/sessions/:id',
        builder: (_, state) =>
            SessionDetailPage(sessionId: int.parse(state.pathParameters['id']!)),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Ops')),
      body: Center(child: Text('Rota não encontrada: ${state.uri}')),
    ),
  );
});
