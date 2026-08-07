import '../core/env.dart';
import 'common.dart';

class WorkoutExerciseItem {
  const WorkoutExerciseItem({
    this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.targetSets,
    required this.targetReps,
    required this.restSeconds,
    required this.primaryMuscles,
    required this.equipment,
    this.imageUrl,
    this.targetWeight,
    this.notes,
    this.lastWeight,
    this.bestWeight,
    this.orderIndex = 0,
  });

  final int? id;
  final int exerciseId;
  final String exerciseName;
  final String? imageUrl;
  final List<String> primaryMuscles;
  final List<String> equipment;
  final int orderIndex;
  final int targetSets;
  final String targetReps;
  final double? targetWeight;
  final int restSeconds;
  final String? notes;
  final double? lastWeight;
  final double? bestWeight;

  String? get resolvedImageUrl => Env.resolveMedia(imageUrl);

  factory WorkoutExerciseItem.fromJson(Map<String, dynamic> json) => WorkoutExerciseItem(
        id: asIntOrNull(json['id']),
        exerciseId: asInt(json['exerciseId']),
        exerciseName: asString(json['exerciseName']),
        imageUrl: asStringOrNull(json['imageUrl']),
        primaryMuscles: asStringList(json['primaryMuscles']),
        equipment: asStringList(json['equipment']),
        orderIndex: asInt(json['orderIndex']),
        targetSets: asInt(json['targetSets'], 3),
        targetReps: asString(json['targetReps'], '10'),
        targetWeight: asDoubleOrNull(json['targetWeight']),
        restSeconds: asInt(json['restSeconds'], 90),
        notes: asStringOrNull(json['notes']),
        lastWeight: asDoubleOrNull(json['lastWeight']),
        bestWeight: asDoubleOrNull(json['bestWeight']),
      );

  Map<String, dynamic> toRequest() => {
        if (id != null) 'id': id,
        'exerciseId': exerciseId,
        'targetSets': targetSets,
        'targetReps': targetReps,
        'targetWeight': targetWeight,
        'restSeconds': restSeconds,
        'notes': notes,
      };

  WorkoutExerciseItem copyWith({
    int? targetSets,
    String? targetReps,
    double? targetWeight,
    int? restSeconds,
    String? notes,
    bool clearTargetWeight = false,
  }) {
    return WorkoutExerciseItem(
      id: id,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      imageUrl: imageUrl,
      primaryMuscles: primaryMuscles,
      equipment: equipment,
      orderIndex: orderIndex,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      targetWeight: clearTargetWeight ? null : (targetWeight ?? this.targetWeight),
      restSeconds: restSeconds ?? this.restSeconds,
      notes: notes ?? this.notes,
      lastWeight: lastWeight,
      bestWeight: bestWeight,
    );
  }
}

class WorkoutDayItem {
  const WorkoutDayItem({
    this.id,
    required this.label,
    required this.name,
    required this.exercises,
    this.orderIndex = 0,
  });

  final int? id;
  final String label;
  final String name;
  final int orderIndex;
  final List<WorkoutExerciseItem> exercises;

  int get totalSets => exercises.fold(0, (sum, item) => sum + item.targetSets);

  factory WorkoutDayItem.fromJson(Map<String, dynamic> json) => WorkoutDayItem(
        id: asIntOrNull(json['id']),
        label: asString(json['label']),
        name: asString(json['name']),
        orderIndex: asInt(json['orderIndex']),
        exercises: asMapList(json['exercises']).map(WorkoutExerciseItem.fromJson).toList(),
      );

  Map<String, dynamic> toRequest() => {
        if (id != null) 'id': id,
        'label': label,
        'name': name,
        'exercises': exercises.map((e) => e.toRequest()).toList(),
      };

  WorkoutDayItem copyWith({
    String? label,
    String? name,
    List<WorkoutExerciseItem>? exercises,
  }) {
    return WorkoutDayItem(
      id: id,
      label: label ?? this.label,
      name: name ?? this.name,
      orderIndex: orderIndex,
      exercises: exercises ?? this.exercises,
    );
  }
}

class Workout {
  const Workout({
    required this.id,
    required this.name,
    required this.splitType,
    required this.archived,
    required this.days,
    this.notes,
    this.color,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String? notes;
  final String splitType;
  final String? color;
  final bool archived;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<WorkoutDayItem> days;

  int get exerciseCount => days.fold(0, (sum, day) => sum + day.exercises.length);

  factory Workout.fromJson(Map<String, dynamic> json) => Workout(
        id: asInt(json['id']),
        name: asString(json['name']),
        notes: asStringOrNull(json['notes']),
        splitType: asString(json['splitType'], 'CUSTOM'),
        color: asStringOrNull(json['color']),
        archived: asBool(json['archived']),
        createdAt: asDate(json['createdAt']),
        updatedAt: asDate(json['updatedAt']),
        days: asMapList(json['days']).map(WorkoutDayItem.fromJson).toList(),
      );

  Map<String, dynamic> toRequest() => {
        'name': name,
        'notes': notes,
        'splitType': splitType,
        'color': color,
        'archived': archived,
        'days': days.map((d) => d.toRequest()).toList(),
      };

  Workout copyWith({
    String? name,
    String? notes,
    String? splitType,
    String? color,
    bool? archived,
    List<WorkoutDayItem>? days,
  }) {
    return Workout(
      id: id,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      splitType: splitType ?? this.splitType,
      color: color ?? this.color,
      archived: archived ?? this.archived,
      createdAt: createdAt,
      updatedAt: updatedAt,
      days: days ?? this.days,
    );
  }
}

class WorkoutDayLabel {
  const WorkoutDayLabel({
    required this.id,
    required this.label,
    required this.name,
    required this.exerciseCount,
  });

  final int id;
  final String label;
  final String name;
  final int exerciseCount;

  factory WorkoutDayLabel.fromJson(Map<String, dynamic> json) => WorkoutDayLabel(
        id: asInt(json['id']),
        label: asString(json['label']),
        name: asString(json['name']),
        exerciseCount: asInt(json['exerciseCount']),
      );
}

class WorkoutSummary {
  const WorkoutSummary({
    required this.id,
    required this.name,
    required this.splitType,
    required this.archived,
    required this.dayCount,
    required this.exerciseCount,
    required this.days,
    this.color,
    this.createdAt,
    this.lastSessionAt,
  });

  final int id;
  final String name;
  final String splitType;
  final String? color;
  final bool archived;
  final DateTime? createdAt;
  final int dayCount;
  final int exerciseCount;
  final List<WorkoutDayLabel> days;
  final DateTime? lastSessionAt;

  factory WorkoutSummary.fromJson(Map<String, dynamic> json) => WorkoutSummary(
        id: asInt(json['id']),
        name: asString(json['name']),
        splitType: asString(json['splitType'], 'CUSTOM'),
        color: asStringOrNull(json['color']),
        archived: asBool(json['archived']),
        createdAt: asDate(json['createdAt']),
        dayCount: asInt(json['dayCount']),
        exerciseCount: asInt(json['exerciseCount']),
        days: asMapList(json['days']).map(WorkoutDayLabel.fromJson).toList(),
        lastSessionAt: asDate(json['lastSessionAt']),
      );
}

class SplitOption {
  const SplitOption({
    required this.code,
    required this.name,
    required this.description,
    required this.dayNames,
  });

  final String code;
  final String name;
  final String description;
  final List<String> dayNames;

  factory SplitOption.fromJson(Map<String, dynamic> json) => SplitOption(
        code: asString(json['code']),
        name: asString(json['name']),
        description: asString(json['description']),
        dayNames: asStringList(json['dayNames']),
      );
}
