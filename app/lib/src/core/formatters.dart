import 'package:intl/intl.dart';

final _dateFormat = DateFormat('dd/MM/yyyy', 'pt_BR');
final _dayMonthFormat = DateFormat('dd/MM', 'pt_BR');
final _dateTimeFormat = DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR');
final _weekdayFormat = DateFormat('EEEE', 'pt_BR');

String formatDate(DateTime? date) => date == null ? '--' : _dateFormat.format(date.toLocal());

String formatDayMonth(DateTime? date) => date == null ? '--' : _dayMonthFormat.format(date.toLocal());

String formatDateTime(DateTime? date) => date == null ? '--' : _dateTimeFormat.format(date.toLocal());

String formatWeekday(DateTime date) => _weekdayFormat.format(date.toLocal());

/// 5500.0 -> "5.500 kg" / 12500 -> "12,5 t"
String formatVolume(num? volume) {
  final value = volume ?? 0;
  if (value >= 1000) {
    final tons = value / 1000;
    return '${tons.toStringAsFixed(tons >= 100 ? 0 : 1).replaceAll('.', ',')} t';
  }
  return '${_decimal(value)} kg';
}

String formatWeight(num? weight) {
  if (weight == null) return '--';
  return '${_decimal(weight)} kg';
}

String _decimal(num value) {
  final isInteger = value == value.roundToDouble();
  final text = isInteger ? value.round().toString() : value.toStringAsFixed(1);
  return text.replaceAll('.', ',');
}

String formatNumber(num? value) => value == null ? '--' : _decimal(value);

/// 3600 -> "1h 00min" | 90 -> "1min 30s"
String formatDuration(int? seconds) {
  if (seconds == null || seconds <= 0) return '--';
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final rest = seconds % 60;
  if (hours > 0) return '${hours}h ${minutes.toString().padLeft(2, '0')}min';
  if (minutes > 0) return '${minutes}min ${rest.toString().padLeft(2, '0')}s';
  return '${rest}s';
}

/// Cronometro: 125 -> "02:05"
String formatClock(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  final minutes = safe ~/ 60;
  final rest = safe % 60;
  return '${minutes.toString().padLeft(2, '0')}:${rest.toString().padLeft(2, '0')}';
}

String formatRest(int seconds) {
  if (seconds <= 0) return 'sem descanso';
  if (seconds % 60 == 0) return '${seconds ~/ 60} min';
  if (seconds < 60) return '${seconds}s';
  return '${seconds ~/ 60}min ${seconds % 60}s';
}

String relativeDate(DateTime? date) {
  if (date == null) return 'nunca';
  final now = DateTime.now();
  final local = date.toLocal();
  final days = DateTime(now.year, now.month, now.day)
      .difference(DateTime(local.year, local.month, local.day))
      .inDays;
  if (days == 0) return 'hoje';
  if (days == 1) return 'ontem';
  if (days < 7) return 'há $days dias';
  if (days < 30) return 'há ${(days / 7).floor()} semana(s)';
  return formatDate(local);
}

String goalLabel(String? goal) => switch (goal) {
      'HIPERTROFIA' => 'Hipertrofia',
      'FORCA' => 'Força',
      'EMAGRECIMENTO' => 'Emagrecimento',
      'RESISTENCIA' => 'Resistência',
      'SAUDE' => 'Saúde e bem-estar',
      _ => 'Não definido',
    };

String experienceLabel(String? experience) => switch (experience) {
      'INICIANTE' => 'Iniciante',
      'INTERMEDIARIO' => 'Intermediário',
      'AVANCADO' => 'Avançado',
      _ => 'Não definido',
    };

String splitLabel(String? split) => switch (split) {
      'ABC' => 'ABC',
      'ABCD' => 'ABCD',
      'ABCDE' => 'ABCDE',
      'PPL' => 'Push Pull Legs',
      'UPPER_LOWER' => 'Upper / Lower',
      'FULL_BODY' => 'Full Body',
      _ => 'Personalizado',
    };
