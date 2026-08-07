/// Helpers de parsing tolerantes (a API sempre manda os campos, mas nulos).
int asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

int? asIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double asDouble(dynamic value, [double fallback = 0]) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

double? asDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

String asString(dynamic value, [String fallback = '']) => value is String ? value : fallback;

String? asStringOrNull(dynamic value) => value is String && value.isNotEmpty ? value : null;

bool asBool(dynamic value, [bool fallback = false]) => value is bool ? value : fallback;

DateTime? asDate(dynamic value) {
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

List<String> asStringList(dynamic value) {
  if (value is List) return value.whereType<String>().toList();
  return const [];
}

List<Map<String, dynamic>> asMapList(dynamic value) {
  if (value is List) {
    return value.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }
  return const [];
}

/// Paginacao devolvida pelo backend.
class PagedResult<T> {
  const PagedResult({
    required this.items,
    required this.page,
    required this.totalElements,
    required this.totalPages,
    required this.last,
  });

  final List<T> items;
  final int page;
  final int totalElements;
  final int totalPages;
  final bool last;

  static PagedResult<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parse,
  ) {
    return PagedResult<T>(
      items: asMapList(json['content']).map(parse).toList(),
      page: asInt(json['page']),
      totalElements: asInt(json['totalElements']),
      totalPages: asInt(json['totalPages']),
      last: asBool(json['last'], true),
    );
  }

  static PagedResult<T> empty<T>() => PagedResult<T>(
        items: const [],
        page: 0,
        totalElements: 0,
        totalPages: 0,
        last: true,
      );
}
