import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories.dart';
import '../models/common.dart';
import '../models/exercise.dart';
import '../models/session.dart';
import '../models/stats.dart';
import '../models/user.dart';
import '../models/workout.dart';
import 'providers.dart';

// ------------------------------- catalogo ----------------------------------

final catalogProvider = FutureProvider<Catalog>((ref) async {
  return ref.watch(exerciseRepositoryProvider).catalog();
});

final splitOptionsProvider = FutureProvider<List<SplitOption>>((ref) async {
  return ref.watch(workoutRepositoryProvider).splits();
});

// ------------------------------- perfil ------------------------------------

class ProfileController extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() => ref.watch(profileRepositoryProvider).get();

  Future<void> save(Map<String, dynamic> body) async {
    final updated = await ref.read(profileRepositoryProvider).update(body);
    state = AsyncData(updated);
    ref.invalidate(statsOverviewProvider);
  }
}

final profileProvider = AsyncNotifierProvider<ProfileController, UserProfile>(ProfileController.new);

final bodyWeightsProvider = FutureProvider<List<BodyWeightPoint>>((ref) async {
  return ref.watch(profileRepositoryProvider).bodyWeights();
});

// ------------------------------- treinos -----------------------------------

class WorkoutsController extends AsyncNotifier<List<WorkoutSummary>> {
  @override
  Future<List<WorkoutSummary>> build() => ref.watch(workoutRepositoryProvider).list();

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(workoutRepositoryProvider).list());
  }

  Future<Workout> createFromTemplate(String splitType, {String? name, String? color}) async {
    final workout = await ref
        .read(workoutRepositoryProvider)
        .fromTemplate(splitType, name: name, color: color);
    await reload();
    return workout;
  }

  Future<Workout> create(Map<String, dynamic> body) async {
    final workout = await ref.read(workoutRepositoryProvider).create(body);
    await reload();
    return workout;
  }

  Future<Workout> updateWorkout(int id, Map<String, dynamic> body) async {
    final workout = await ref.read(workoutRepositoryProvider).update(id, body);
    ref.invalidate(workoutDetailProvider(id));
    await reload();
    return workout;
  }

  Future<Workout> duplicate(int id, {String? name}) async {
    final workout = await ref.read(workoutRepositoryProvider).duplicate(id, name: name);
    await reload();
    return workout;
  }

  Future<void> delete(int id) async {
    await ref.read(workoutRepositoryProvider).delete(id);
    await reload();
  }
}

final workoutsProvider =
    AsyncNotifierProvider<WorkoutsController, List<WorkoutSummary>>(WorkoutsController.new);

final workoutDetailProvider = FutureProvider.family<Workout, int>((ref, id) async {
  return ref.watch(workoutRepositoryProvider).get(id);
});

// ------------------------------- sessao ------------------------------------

class SessionController extends AsyncNotifier<TrainingSession?> {
  @override
  Future<TrainingSession?> build() => ref.watch(sessionRepositoryProvider).active();

  SessionRepository get _repo => ref.read(sessionRepositoryProvider);

  Future<TrainingSession> start({
    int? workoutId,
    int? workoutDayId,
    bool discardActive = false,
  }) async {
    final session = await _repo.start(
      workoutId: workoutId,
      workoutDayId: workoutDayId,
      discardActive: discardActive,
    );
    state = AsyncData(session);
    return session;
  }

  Future<void> refreshActive() async {
    state = await AsyncValue.guard(() => _repo.active());
  }

  Future<void> _apply(Future<TrainingSession> Function() action) async {
    try {
      final session = await action();
      state = AsyncData(session);
    } catch (error, stack) {
      // mantem a sessao atual na tela e propaga o erro para a UI mostrar
      state = AsyncData(state.value);
      Error.throwWithStackTrace(error, stack);
    }
  }

  int? get _sessionId => state.value?.id;

  Future<void> updateSet(int setId, {int? reps, double? weight, bool? completed, int? rpe}) async {
    final id = _sessionId;
    if (id == null) return;
    await _apply(() => _repo.updateSet(id, setId,
        reps: reps, weight: weight, completed: completed, rpe: rpe));
  }

  Future<void> addSet(int sessionExerciseId, {int? reps, double? weight}) async {
    final id = _sessionId;
    if (id == null) return;
    await _apply(() => _repo.addSet(id, sessionExerciseId, reps: reps, weight: weight));
  }

  Future<void> removeSet(int setId) async {
    final id = _sessionId;
    if (id == null) return;
    await _apply(() => _repo.removeSet(id, setId));
  }

  Future<void> updateExercise(int sessionExerciseId, {int? restSeconds, String? notes}) async {
    final id = _sessionId;
    if (id == null) return;
    await _apply(
      () => _repo.updateExercise(id, sessionExerciseId,
          restSeconds: restSeconds, notes: notes),
    );
  }

  Future<void> substitute(int sessionExerciseId, int exerciseId) async {
    final id = _sessionId;
    if (id == null) return;
    await _apply(() => _repo.substitute(id, sessionExerciseId, exerciseId));
  }

  Future<void> addExercise(int exerciseId) async {
    final id = _sessionId;
    if (id == null) return;
    await _apply(() => _repo.addExercise(id, exerciseId));
  }

  Future<void> removeExercise(int sessionExerciseId) async {
    final id = _sessionId;
    if (id == null) return;
    await _apply(() => _repo.removeExercise(id, sessionExerciseId));
  }

  Future<TrainingSession> finish({String? notes, int? durationSeconds}) async {
    final id = _sessionId;
    if (id == null) throw StateError('Nenhuma sessão ativa');
    final finished =
        await _repo.finish(id, notes: notes, durationSeconds: durationSeconds);
    state = const AsyncData(null);
    _invalidateAfterSession();
    return finished;
  }

  Future<void> cancel() async {
    final id = _sessionId;
    if (id == null) return;
    await _repo.cancel(id);
    state = const AsyncData(null);
    _invalidateAfterSession();
  }

  void _invalidateAfterSession() {
    ref.invalidate(statsOverviewProvider);
    ref.invalidate(weeklyVolumeProvider);
    ref.invalidate(muscleGroupsProvider);
    ref.invalidate(calendarProvider);
    ref.invalidate(historyProvider);
    ref.invalidate(workoutsProvider);
  }
}

final activeSessionProvider =
    AsyncNotifierProvider<SessionController, TrainingSession?>(SessionController.new);

final sessionDetailProvider = FutureProvider.family<TrainingSession, int>((ref, id) async {
  return ref.watch(sessionRepositoryProvider).get(id);
});

// ------------------------------ historico ----------------------------------

class HistoryController extends AsyncNotifier<PagedResult<SessionSummary>> {
  @override
  Future<PagedResult<SessionSummary>> build() =>
      ref.watch(sessionRepositoryProvider).history(page: 0, size: 30);

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.last) return;
    final next = await ref
        .read(sessionRepositoryProvider)
        .history(page: current.page + 1, size: 30);
    state = AsyncData(
      PagedResult<SessionSummary>(
        items: [...current.items, ...next.items],
        page: next.page,
        totalElements: next.totalElements,
        totalPages: next.totalPages,
        last: next.last,
      ),
    );
  }
}

final historyProvider =
    AsyncNotifierProvider<HistoryController, PagedResult<SessionSummary>>(HistoryController.new);

// ----------------------------- estatisticas --------------------------------

final statsOverviewProvider = FutureProvider<StatsOverview>((ref) async {
  return ref.watch(statsRepositoryProvider).overview();
});

final weeklyVolumeProvider = FutureProvider<List<WeeklyVolume>>((ref) async {
  return ref.watch(statsRepositoryProvider).weeklyVolume(weeks: 10);
});

final muscleGroupsProvider = FutureProvider<List<MuscleGroupVolume>>((ref) async {
  return ref.watch(statsRepositoryProvider).muscleGroups(days: 30);
});

final calendarProvider = FutureProvider<List<CalendarDay>>((ref) async {
  return ref.watch(statsRepositoryProvider).calendar(days: 119);
});

final exerciseProgressionProvider =
    FutureProvider.family<ExerciseProgression, int>((ref, exerciseId) async {
  return ref.watch(statsRepositoryProvider).exerciseProgression(exerciseId);
});

// ------------------------------ exercicios ---------------------------------

@immutable
class ExerciseSearchState {
  const ExerciseSearchState({
    required this.filter,
    required this.items,
    required this.total,
    required this.page,
    required this.last,
    this.loading = false,
    this.loadingMore = false,
    this.error,
  });

  final ExerciseFilter filter;
  final List<ExerciseSummary> items;
  final int total;
  final int page;
  final bool last;
  final bool loading;
  final bool loadingMore;
  final String? error;

  ExerciseSearchState copyWith({
    ExerciseFilter? filter,
    List<ExerciseSummary>? items,
    int? total,
    int? page,
    bool? last,
    bool? loading,
    bool? loadingMore,
    String? error,
    bool clearError = false,
  }) {
    return ExerciseSearchState(
      filter: filter ?? this.filter,
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      last: last ?? this.last,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }

  static const initial = ExerciseSearchState(
    filter: ExerciseFilter(),
    items: [],
    total: 0,
    page: 0,
    last: true,
    loading: true,
  );
}

class ExerciseSearchController extends Notifier<ExerciseSearchState> {
  Timer? _debounce;

  @override
  ExerciseSearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(_load);
    return ExerciseSearchState.initial;
  }

  Future<void> _load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final filter = state.filter;
      final result = await ref.read(exerciseRepositoryProvider).search(
            search: filter.search,
            muscleId: filter.muscleId,
            equipmentId: filter.equipmentId,
            categoryId: filter.categoryId,
            onlyWithImage: filter.onlyWithImage,
            onlyWithVideo: filter.onlyWithVideo,
            page: 0,
            size: 24,
          );
      state = state.copyWith(
        items: result.items,
        total: result.totalElements,
        page: 0,
        last: result.last,
        loading: false,
      );
    } catch (error) {
      state = state.copyWith(loading: false, error: error.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.last || state.loadingMore || state.loading) return;
    state = state.copyWith(loadingMore: true);
    try {
      final filter = state.filter;
      final result = await ref.read(exerciseRepositoryProvider).search(
            search: filter.search,
            muscleId: filter.muscleId,
            equipmentId: filter.equipmentId,
            categoryId: filter.categoryId,
            onlyWithImage: filter.onlyWithImage,
            onlyWithVideo: filter.onlyWithVideo,
            page: state.page + 1,
            size: 24,
          );
      state = state.copyWith(
        items: [...state.items, ...result.items],
        page: result.page,
        last: result.last,
        total: result.totalElements,
        loadingMore: false,
      );
    } catch (error) {
      state = state.copyWith(loadingMore: false, error: error.toString());
    }
  }

  void search(String term) {
    state = state.copyWith(filter: state.filter.copyWith(search: term));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  void applyFilter(ExerciseFilter filter) {
    state = state.copyWith(filter: filter);
    _load();
  }

  void clearFilters() {
    state = state.copyWith(filter: ExerciseFilter(search: state.filter.search));
    _load();
  }

  Future<void> reload() => _load();
}

final exerciseSearchProvider =
    NotifierProvider<ExerciseSearchController, ExerciseSearchState>(ExerciseSearchController.new);

final exerciseDetailProvider = FutureProvider.family<ExerciseDetail, int>((ref, id) async {
  return ref.watch(exerciseRepositoryProvider).detail(id);
});

final equivalentsProvider =
    FutureProvider.family<List<ExerciseSummary>, int>((ref, exerciseId) async {
  return ref.watch(exerciseRepositoryProvider).equivalents(exerciseId, limit: 20);
});
