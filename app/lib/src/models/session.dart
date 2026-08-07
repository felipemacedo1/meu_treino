import '../core/env.dart';
import 'common.dart';

class WorkoutSet {
  const WorkoutSet({
    required this.id,
    required this.setNumber,
    required this.completed,
    this.targetReps,
    this.reps,
    this.weight,
    this.completedAt,
    this.rpe,
  });

  final int id;
  final int setNumber;
  final String? targetReps;
  final int? reps;
  final double? weight;
  final bool completed;
  final DateTime? completedAt;
  final int? rpe;

  double get volume => (weight ?? 0) * (reps ?? 0);

  factory WorkoutSet.fromJson(Map<String, dynamic> json) => WorkoutSet(
        id: asInt(json['id']),
        setNumber: asInt(json['setNumber']),
        targetReps: asStringOrNull(json['targetReps']),
        reps: asIntOrNull(json['reps']),
        weight: asDoubleOrNull(json['weight']),
        completed: asBool(json['completed']),
        completedAt: asDate(json['completedAt']),
        rpe: asIntOrNull(json['rpe']),
      );
}

class SessionExerciseItem {
  const SessionExerciseItem({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.orderIndex,
    required this.restSeconds,
    required this.substituted,
    required this.primaryMuscles,
    required this.equipment,
    required this.sets,
    this.imageUrl,
    this.notes,
    this.originalExerciseName,
    this.lastWeight,
    this.lastReps,
    this.lastDate,
    this.bestWeight,
  });

  final int id;
  final int exerciseId;
  final String exerciseName;
  final String? imageUrl;
  final List<String> primaryMuscles;
  final List<String> equipment;
  final int orderIndex;
  final int restSeconds;
  final String? notes;
  final bool substituted;
  final String? originalExerciseName;
  final double? lastWeight;
  final int? lastReps;
  final DateTime? lastDate;
  final double? bestWeight;
  final List<WorkoutSet> sets;

  String? get resolvedImageUrl => Env.resolveMedia(imageUrl);

  int get completedSets => sets.where((s) => s.completed).length;

  bool get isDone => sets.isNotEmpty && completedSets == sets.length;

  double get volume => sets.fold(0.0, (sum, s) => sum + (s.completed ? s.volume : 0));

  factory SessionExerciseItem.fromJson(Map<String, dynamic> json) => SessionExerciseItem(
        id: asInt(json['id']),
        exerciseId: asInt(json['exerciseId']),
        exerciseName: asString(json['exerciseName']),
        imageUrl: asStringOrNull(json['imageUrl']),
        primaryMuscles: asStringList(json['primaryMuscles']),
        equipment: asStringList(json['equipment']),
        orderIndex: asInt(json['orderIndex']),
        restSeconds: asInt(json['restSeconds'], 90),
        notes: asStringOrNull(json['notes']),
        substituted: asBool(json['substituted']),
        originalExerciseName: asStringOrNull(json['originalExerciseName']),
        lastWeight: asDoubleOrNull(json['lastWeight']),
        lastReps: asIntOrNull(json['lastReps']),
        lastDate: asDate(json['lastDate']),
        bestWeight: asDoubleOrNull(json['bestWeight']),
        sets: asMapList(json['sets']).map(WorkoutSet.fromJson).toList(),
      );
}

class TrainingSession {
  const TrainingSession({
    required this.id,
    required this.status,
    required this.startedAt,
    required this.totalVolume,
    required this.totalSets,
    required this.exercises,
    this.workoutId,
    this.workoutDayId,
    this.workoutName,
    this.dayLabel,
    this.dayName,
    this.finishedAt,
    this.durationSeconds,
    this.notes,
  });

  final int id;
  final int? workoutId;
  final int? workoutDayId;
  final String? workoutName;
  final String? dayLabel;
  final String? dayName;
  final String status;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int? durationSeconds;
  final double totalVolume;
  final int totalSets;
  final String? notes;
  final List<SessionExerciseItem> exercises;

  bool get inProgress => status == 'IN_PROGRESS';

  int get plannedSets => exercises.fold(0, (sum, e) => sum + e.sets.length);

  int get completedSets => exercises.fold(0, (sum, e) => sum + e.completedSets);

  double get progress => plannedSets == 0 ? 0 : completedSets / plannedSets;

  int get elapsedSeconds =>
      durationSeconds ?? DateTime.now().difference(startedAt.toLocal()).inSeconds;

  String get title {
    final label = dayLabel == null || dayLabel!.isEmpty ? '' : '$dayLabel · ';
    return '$label${dayName ?? workoutName ?? 'Treino'}';
  }

  factory TrainingSession.fromJson(Map<String, dynamic> json) => TrainingSession(
        id: asInt(json['id']),
        workoutId: asIntOrNull(json['workoutId']),
        workoutDayId: asIntOrNull(json['workoutDayId']),
        workoutName: asStringOrNull(json['workoutName']),
        dayLabel: asStringOrNull(json['dayLabel']),
        dayName: asStringOrNull(json['dayName']),
        status: asString(json['status'], 'IN_PROGRESS'),
        startedAt: asDate(json['startedAt']) ?? DateTime.now(),
        finishedAt: asDate(json['finishedAt']),
        durationSeconds: asIntOrNull(json['durationSeconds']),
        totalVolume: asDouble(json['totalVolume']),
        totalSets: asInt(json['totalSets']),
        notes: asStringOrNull(json['notes']),
        exercises: asMapList(json['exercises']).map(SessionExerciseItem.fromJson).toList(),
      );
}

class SessionSummary {
  const SessionSummary({
    required this.id,
    required this.status,
    required this.startedAt,
    required this.totalVolume,
    required this.totalSets,
    required this.exerciseCount,
    this.workoutId,
    this.workoutName,
    this.dayLabel,
    this.dayName,
    this.finishedAt,
    this.durationSeconds,
  });

  final int id;
  final int? workoutId;
  final String? workoutName;
  final String? dayLabel;
  final String? dayName;
  final String status;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int? durationSeconds;
  final double totalVolume;
  final int totalSets;
  final int exerciseCount;

  String get title {
    final label = dayLabel == null || dayLabel!.isEmpty ? '' : '$dayLabel · ';
    return '$label${dayName ?? workoutName ?? 'Treino'}';
  }

  factory SessionSummary.fromJson(Map<String, dynamic> json) => SessionSummary(
        id: asInt(json['id']),
        workoutId: asIntOrNull(json['workoutId']),
        workoutName: asStringOrNull(json['workoutName']),
        dayLabel: asStringOrNull(json['dayLabel']),
        dayName: asStringOrNull(json['dayName']),
        status: asString(json['status']),
        startedAt: asDate(json['startedAt']) ?? DateTime.now(),
        finishedAt: asDate(json['finishedAt']),
        durationSeconds: asIntOrNull(json['durationSeconds']),
        totalVolume: asDouble(json['totalVolume']),
        totalSets: asInt(json['totalSets']),
        exerciseCount: asInt(json['exerciseCount']),
      );
}
