import 'common.dart';

class StatsOverview {
  const StatsOverview({
    required this.totalSessions,
    required this.totalVolume,
    required this.totalSets,
    required this.totalMinutes,
    required this.currentStreak,
    required this.longestStreak,
    required this.sessionsThisWeek,
    required this.weeklyGoal,
    required this.volumeThisWeek,
    required this.avgSessionMinutes,
    required this.workoutCount,
    this.lastSessionAt,
  });

  final int totalSessions;
  final double totalVolume;
  final int totalSets;
  final int totalMinutes;
  final int currentStreak;
  final int longestStreak;
  final int sessionsThisWeek;
  final int weeklyGoal;
  final double volumeThisWeek;
  final int avgSessionMinutes;
  final int workoutCount;
  final DateTime? lastSessionAt;

  double get weekProgress => weeklyGoal == 0 ? 0 : (sessionsThisWeek / weeklyGoal).clamp(0.0, 1.0);

  factory StatsOverview.fromJson(Map<String, dynamic> json) => StatsOverview(
        totalSessions: asInt(json['totalSessions']),
        totalVolume: asDouble(json['totalVolume']),
        totalSets: asInt(json['totalSets']),
        totalMinutes: asInt(json['totalMinutes']),
        currentStreak: asInt(json['currentStreak']),
        longestStreak: asInt(json['longestStreak']),
        sessionsThisWeek: asInt(json['sessionsThisWeek']),
        weeklyGoal: asInt(json['weeklyGoal'], 4),
        volumeThisWeek: asDouble(json['volumeThisWeek']),
        avgSessionMinutes: asInt(json['avgSessionMinutes']),
        workoutCount: asInt(json['workoutCount']),
        lastSessionAt: asDate(json['lastSessionAt']),
      );

  static const empty = StatsOverview(
    totalSessions: 0,
    totalVolume: 0,
    totalSets: 0,
    totalMinutes: 0,
    currentStreak: 0,
    longestStreak: 0,
    sessionsThisWeek: 0,
    weeklyGoal: 4,
    volumeThisWeek: 0,
    avgSessionMinutes: 0,
    workoutCount: 0,
  );
}

class WeeklyVolume {
  const WeeklyVolume({required this.weekStart, required this.volume, required this.sessions});

  final DateTime weekStart;
  final double volume;
  final int sessions;

  factory WeeklyVolume.fromJson(Map<String, dynamic> json) => WeeklyVolume(
        weekStart: asDate(json['weekStart']) ?? DateTime.now(),
        volume: asDouble(json['volume']),
        sessions: asInt(json['sessions']),
      );
}

class MuscleGroupVolume {
  const MuscleGroupVolume({required this.group, required this.volume, required this.sets});

  final String group;
  final double volume;
  final int sets;

  factory MuscleGroupVolume.fromJson(Map<String, dynamic> json) => MuscleGroupVolume(
        group: asString(json['group'], 'Outros'),
        volume: asDouble(json['volume']),
        sets: asInt(json['sets']),
      );
}

class ProgressionPoint {
  const ProgressionPoint({
    required this.date,
    required this.sets,
    required this.reps,
    this.topWeight,
    this.volume,
    this.estimatedOneRepMax,
  });

  final DateTime date;
  final double? topWeight;
  final double? volume;
  final int sets;
  final int reps;
  final double? estimatedOneRepMax;

  factory ProgressionPoint.fromJson(Map<String, dynamic> json) => ProgressionPoint(
        date: asDate(json['date']) ?? DateTime.now(),
        topWeight: asDoubleOrNull(json['topWeight']),
        volume: asDoubleOrNull(json['volume']),
        sets: asInt(json['sets']),
        reps: asInt(json['reps']),
        estimatedOneRepMax: asDoubleOrNull(json['estimatedOneRepMax']),
      );
}

class ExerciseProgression {
  const ExerciseProgression({
    required this.exerciseId,
    required this.exerciseName,
    required this.points,
    this.bestWeight,
    this.lastWeight,
    this.lastDate,
  });

  final int exerciseId;
  final String exerciseName;
  final double? bestWeight;
  final double? lastWeight;
  final DateTime? lastDate;
  final List<ProgressionPoint> points;

  factory ExerciseProgression.fromJson(Map<String, dynamic> json) => ExerciseProgression(
        exerciseId: asInt(json['exerciseId']),
        exerciseName: asString(json['exerciseName']),
        bestWeight: asDoubleOrNull(json['bestWeight']),
        lastWeight: asDoubleOrNull(json['lastWeight']),
        lastDate: asDate(json['lastDate']),
        points: asMapList(json['points']).map(ProgressionPoint.fromJson).toList(),
      );
}

class CalendarDay {
  const CalendarDay({required this.date, required this.sessions, required this.volume});

  final DateTime date;
  final int sessions;
  final double volume;

  factory CalendarDay.fromJson(Map<String, dynamic> json) => CalendarDay(
        date: asDate(json['date']) ?? DateTime.now(),
        sessions: asInt(json['sessions']),
        volume: asDouble(json['volume']),
      );
}
