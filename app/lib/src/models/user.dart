import 'common.dart';

class AppUser {
  const AppUser({required this.id, required this.name, required this.email, this.createdAt});

  final int id;
  final String name;
  final String email;
  final DateTime? createdAt;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: asInt(json['id']),
        name: asString(json['name']),
        email: asString(json['email']),
        createdAt: asDate(json['createdAt']),
      );

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

class AuthResult {
  const AuthResult({required this.token, required this.user});

  final String token;
  final AppUser user;

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        token: asString(json['token']),
        user: AppUser.fromJson((json['user'] as Map).cast<String, dynamic>()),
      );
}

class UserProfile {
  const UserProfile({
    required this.userId,
    required this.name,
    required this.email,
    this.weightKg,
    this.heightCm,
    this.birthDate,
    this.gender,
    this.goal,
    this.experience,
    this.availableDays,
    this.sessionMinutes,
    this.weeklyGoal,
    this.theme,
    this.bmi,
  });

  final int userId;
  final String name;
  final String email;
  final double? weightKg;
  final int? heightCm;
  final DateTime? birthDate;
  final String? gender;
  final String? goal;
  final String? experience;
  final int? availableDays;
  final int? sessionMinutes;
  final int? weeklyGoal;

  /// Identificador do tema visual escolhido (ver AppThemes).
  final String? theme;
  final double? bmi;

  bool get isComplete => weightKg != null && heightCm != null && goal != null && experience != null;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        userId: asInt(json['userId']),
        name: asString(json['name']),
        email: asString(json['email']),
        weightKg: asDoubleOrNull(json['weightKg']),
        heightCm: asIntOrNull(json['heightCm']),
        birthDate: asDate(json['birthDate']),
        gender: asStringOrNull(json['gender']),
        goal: asStringOrNull(json['goal']),
        experience: asStringOrNull(json['experience']),
        availableDays: asIntOrNull(json['availableDays']),
        sessionMinutes: asIntOrNull(json['sessionMinutes']),
        weeklyGoal: asIntOrNull(json['weeklyGoal']),
        theme: asStringOrNull(json['theme']),
        bmi: asDoubleOrNull(json['bmi']),
      );
}

class BodyWeightPoint {
  const BodyWeightPoint({required this.date, required this.weightKg});

  final DateTime date;
  final double weightKg;

  static List<BodyWeightPoint> listFromJson(Map<String, dynamic> json) {
    return asMapList(json['points'])
        .map(
          (item) => BodyWeightPoint(
            date: asDate(item['date']) ?? DateTime.now(),
            weightKg: asDouble(item['weightKg']),
          ),
        )
        .toList();
  }
}
