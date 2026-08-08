import '../core/api_client.dart';
import '../models/common.dart';
import '../models/exercise.dart';
import '../models/session.dart';
import '../models/stats.dart';
import '../models/user.dart';
import '../models/workout.dart';

Map<String, dynamic> _map(dynamic data) => (data as Map).cast<String, dynamic>();

List<Map<String, dynamic>> _list(dynamic data) =>
    (data as List).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();

// ------------------------------- auth --------------------------------------

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  Future<AuthResult> register(String name, String email, String password) async {
    final data = await _api.post('/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
    });
    return AuthResult.fromJson(_map(data));
  }

  Future<AuthResult> login(String email, String password) async {
    final data = await _api.post('/auth/login', body: {'email': email, 'password': password});
    return AuthResult.fromJson(_map(data));
  }

  Future<AppUser> me() async => AppUser.fromJson(_map(await _api.get('/auth/me')));
}

// ------------------------------ profile ------------------------------------

class ProfileRepository {
  ProfileRepository(this._api);

  final ApiClient _api;

  Future<UserProfile> get() async => UserProfile.fromJson(_map(await _api.get('/profile')));

  Future<UserProfile> update(Map<String, dynamic> body) async =>
      UserProfile.fromJson(_map(await _api.put('/profile', body: body)));

  Future<List<BodyWeightPoint>> bodyWeights() async =>
      BodyWeightPoint.listFromJson(_map(await _api.get('/profile/body-weights')));

  Future<List<BodyWeightPoint>> addBodyWeight(double weightKg, {DateTime? measuredAt}) async {
    final data = await _api.post('/profile/body-weights', body: {
      'weightKg': weightKg,
      if (measuredAt != null) 'measuredAt': measuredAt.toIso8601String().substring(0, 10),
    });
    return BodyWeightPoint.listFromJson(_map(data));
  }
}

// ----------------------------- exercises -----------------------------------

class ExerciseRepository {
  ExerciseRepository(this._api);

  final ApiClient _api;

  Future<Catalog> catalog() async => Catalog.fromJson(_map(await _api.get('/exercises/catalog')));

  Future<PagedResult<ExerciseSummary>> search({
    String? search,
    int? muscleId,
    int? equipmentId,
    int? categoryId,
    bool onlyWithImage = false,
    bool onlyWithVideo = false,
    int page = 0,
    int size = 20,
  }) async {
    final data = await _api.get('/exercises', query: {
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      'muscleId': muscleId,
      'equipmentId': equipmentId,
      'categoryId': categoryId,
      'onlyWithImage': onlyWithImage,
      'onlyWithVideo': onlyWithVideo,
      'page': page,
      'size': size,
    });
    return PagedResult.fromJson(_map(data), ExerciseSummary.fromJson);
  }

  Future<ExerciseDetail> detail(int id) async =>
      ExerciseDetail.fromJson(_map(await _api.get('/exercises/$id')));

  Future<List<ExerciseSummary>> equivalents(int id, {int limit = 15}) async {
    final data = await _api.get('/exercises/$id/equivalents', query: {'limit': limit});
    return _list(data).map(ExerciseSummary.fromJson).toList();
  }
}

// ------------------------------ workouts -----------------------------------

class WorkoutRepository {
  WorkoutRepository(this._api);

  final ApiClient _api;

  Future<List<WorkoutSummary>> list({bool includeArchived = false}) async {
    final data = await _api.get('/workouts', query: {'includeArchived': includeArchived});
    return _list(data).map(WorkoutSummary.fromJson).toList();
  }

  Future<List<SplitOption>> splits() async =>
      _list(await _api.get('/workouts/splits')).map(SplitOption.fromJson).toList();

  Future<Workout> get(int id) async => Workout.fromJson(_map(await _api.get('/workouts/$id')));

  Future<Workout> create(Map<String, dynamic> body) async =>
      Workout.fromJson(_map(await _api.post('/workouts', body: body)));

  Future<Workout> fromTemplate(String splitType, {String? name, String? color}) async {
    final data = await _api.post('/workouts/from-template', body: {
      'splitType': splitType,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
    });
    return Workout.fromJson(_map(data));
  }

  Future<Workout> update(int id, Map<String, dynamic> body) async =>
      Workout.fromJson(_map(await _api.put('/workouts/$id', body: body)));

  Future<Workout> duplicate(int id, {String? name}) async {
    final data = await _api.post('/workouts/$id/duplicate', body: {if (name != null) 'name': name});
    return Workout.fromJson(_map(data));
  }

  Future<void> delete(int id) => _api.delete('/workouts/$id');
}

// ------------------------------ sessions -----------------------------------

class SessionRepository {
  SessionRepository(this._api);

  final ApiClient _api;

  Future<TrainingSession> start({int? workoutId, int? workoutDayId, bool discardActive = false}) async {
    final data = await _api.post('/sessions/start', body: {
      'workoutId': workoutId,
      'workoutDayId': workoutDayId,
      'discardActive': discardActive,
    });
    return TrainingSession.fromJson(_map(data));
  }

  Future<TrainingSession?> active() async {
    final data = await _api.getOrNull('/sessions/active');
    if (data == null) return null;
    return TrainingSession.fromJson(_map(data));
  }

  Future<TrainingSession> get(int id) async =>
      TrainingSession.fromJson(_map(await _api.get('/sessions/$id')));

  Future<PagedResult<SessionSummary>> history({int page = 0, int size = 20}) async {
    final data = await _api.get('/sessions', query: {'page': page, 'size': size});
    return PagedResult.fromJson(_map(data), SessionSummary.fromJson);
  }

  Future<TrainingSession> updateSet(
    int sessionId,
    int setId, {
    int? reps,
    double? weight,
    bool? completed,
    int? rpe,
  }) async {
    final data = await _api.patch('/sessions/$sessionId/sets/$setId', body: {
      if (reps != null) 'reps': reps,
      if (weight != null) 'weight': weight,
      if (completed != null) 'completed': completed,
      if (rpe != null) 'rpe': rpe,
    });
    return TrainingSession.fromJson(_map(data));
  }

  Future<TrainingSession> addSet(int sessionId, int sessionExerciseId, {int? reps, double? weight}) async {
    final data = await _api.post(
      '/sessions/$sessionId/exercises/$sessionExerciseId/sets',
      body: {'reps': reps, 'weight': weight},
    );
    return TrainingSession.fromJson(_map(data));
  }

  Future<TrainingSession> removeSet(int sessionId, int setId) async =>
      TrainingSession.fromJson(_map(await _api.delete('/sessions/$sessionId/sets/$setId')));

  Future<TrainingSession> updateExercise(
    int sessionId,
    int sessionExerciseId, {
    int? restSeconds,
    String? notes,
  }) async {
    final data = await _api.patch('/sessions/$sessionId/exercises/$sessionExerciseId', body: {
      if (restSeconds != null) 'restSeconds': restSeconds,
      if (notes != null) 'notes': notes,
    });
    return TrainingSession.fromJson(_map(data));
  }

  Future<TrainingSession> substitute(int sessionId, int sessionExerciseId, int exerciseId) async {
    final data = await _api.post(
      '/sessions/$sessionId/exercises/$sessionExerciseId/substitute',
      body: {'exerciseId': exerciseId},
    );
    return TrainingSession.fromJson(_map(data));
  }

  Future<TrainingSession> addExercise(
    int sessionId,
    int exerciseId, {
    int sets = 3,
    String targetReps = '10',
    int restSeconds = 90,
  }) async {
    final data = await _api.post('/sessions/$sessionId/exercises', body: {
      'exerciseId': exerciseId,
      'sets': sets,
      'targetReps': targetReps,
      'restSeconds': restSeconds,
    });
    return TrainingSession.fromJson(_map(data));
  }

  Future<TrainingSession> removeExercise(int sessionId, int sessionExerciseId) async {
    final data = await _api.delete('/sessions/$sessionId/exercises/$sessionExerciseId');
    return TrainingSession.fromJson(_map(data));
  }

  Future<TrainingSession> finish(int sessionId, {String? notes, int? durationSeconds}) async {
    final data = await _api.post('/sessions/$sessionId/finish', body: {
      if (notes != null) 'notes': notes,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
    });
    return TrainingSession.fromJson(_map(data));
  }

  Future<TrainingSession> cancel(int sessionId) async =>
      TrainingSession.fromJson(_map(await _api.post('/sessions/$sessionId/cancel')));

  Future<void> delete(int sessionId) => _api.delete('/sessions/$sessionId');
}

// -------------------------------- stats ------------------------------------

class StatsRepository {
  StatsRepository(this._api);

  final ApiClient _api;

  Future<StatsOverview> overview() async =>
      StatsOverview.fromJson(_map(await _api.get('/stats/overview')));

  Future<List<WeeklyVolume>> weeklyVolume({int weeks = 12}) async {
    final data = await _api.get('/stats/weekly-volume', query: {'weeks': weeks});
    return _list(data).map(WeeklyVolume.fromJson).toList();
  }

  Future<List<MuscleGroupVolume>> muscleGroups({int days = 30}) async {
    final data = await _api.get('/stats/muscle-groups', query: {'days': days});
    return _list(data).map(MuscleGroupVolume.fromJson).toList();
  }

  Future<ExerciseProgression> exerciseProgression(int exerciseId) async =>
      ExerciseProgression.fromJson(_map(await _api.get('/stats/exercise/$exerciseId')));

  Future<List<CalendarDay>> calendar({int days = 120}) async {
    final data = await _api.get('/stats/calendar', query: {'days': days});
    return _list(data).map(CalendarDay.fromJson).toList();
  }
}

// -------------------------------- sync -------------------------------------

class SyncRepository {
  SyncRepository(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> status() async => _map(await _api.get('/sync/status'));

  Future<Map<String, dynamic>> sync() async => _map(await _api.post('/sync/wger'));
}
