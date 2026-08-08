import '../core/env.dart';
import 'common.dart';

class Muscle {
  const Muscle({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.front,
    this.imageUrl,
  });

  final int id;
  final String name;
  final String scientificName;
  final bool front;
  final String? imageUrl;

  factory Muscle.fromJson(Map<String, dynamic> json) => Muscle(
        id: asInt(json['id']),
        name: asString(json['name']),
        scientificName: asString(json['scientificName']),
        front: asBool(json['front'], true),
        imageUrl: asStringOrNull(json['imageUrl']),
      );
}

class NamedRef {
  const NamedRef({required this.id, required this.name});

  final int id;
  final String name;

  factory NamedRef.fromJson(Map<String, dynamic> json) =>
      NamedRef(id: asInt(json['id']), name: asString(json['name']));
}

class Catalog {
  const Catalog({
    required this.muscles,
    required this.equipment,
    required this.categories,
    required this.totalExercises,
  });

  final List<Muscle> muscles;
  final List<NamedRef> equipment;
  final List<NamedRef> categories;
  final int totalExercises;

  factory Catalog.fromJson(Map<String, dynamic> json) => Catalog(
        muscles: asMapList(json['muscles']).map(Muscle.fromJson).toList(),
        equipment: asMapList(json['equipment']).map(NamedRef.fromJson).toList(),
        categories: asMapList(json['categories']).map(NamedRef.fromJson).toList(),
        totalExercises: asInt(json['totalExercises']),
      );

  static const empty = Catalog(muscles: [], equipment: [], categories: [], totalExercises: 0);
}

class ExerciseSummary {
  const ExerciseSummary({
    required this.id,
    required this.name,
    required this.originalName,
    required this.primaryMuscles,
    required this.equipment,
    required this.hasVideo,
    this.categoryName,
    this.categoryId,
    this.imageUrl,
  });

  final int id;
  final String name;
  final String originalName;
  final String? categoryName;
  final int? categoryId;
  final String? imageUrl;
  final List<String> primaryMuscles;
  final List<String> equipment;
  final bool hasVideo;

  String? get resolvedImageUrl => Env.resolveMedia(imageUrl);

  String get subtitle {
    final parts = <String>[];
    if (primaryMuscles.isNotEmpty) parts.add(primaryMuscles.join(', '));
    if (equipment.isNotEmpty) parts.add(equipment.join(', '));
    if (parts.isEmpty && categoryName != null) parts.add(categoryName!);
    return parts.join(' · ');
  }

  factory ExerciseSummary.fromJson(Map<String, dynamic> json) => ExerciseSummary(
        id: asInt(json['id']),
        name: asString(json['name']),
        originalName: asString(json['originalName']),
        categoryName: asStringOrNull(json['categoryName']),
        categoryId: asIntOrNull(json['categoryId']),
        imageUrl: asStringOrNull(json['imageUrl']),
        primaryMuscles: asStringList(json['primaryMuscles']),
        equipment: asStringList(json['equipment']),
        hasVideo: asBool(json['hasVideo']),
      );
}

class ExerciseDetail {
  const ExerciseDetail({
    required this.id,
    required this.name,
    required this.originalName,
    required this.images,
    required this.videos,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.equipment,
    this.wgerId,
    this.description,
    this.categoryId,
    this.categoryName,
  });

  final int id;
  final int? wgerId;
  final String name;
  final String originalName;
  final String? description;
  final int? categoryId;
  final String? categoryName;
  final List<String> images;
  final List<String> videos;
  final List<Muscle> primaryMuscles;
  final List<Muscle> secondaryMuscles;
  final List<NamedRef> equipment;

  List<String> get resolvedImages =>
      images.map(Env.resolveMedia).whereType<String>().toList();

  List<String> get resolvedVideos =>
      videos.map(Env.resolveMedia).whereType<String>().toList();

  factory ExerciseDetail.fromJson(Map<String, dynamic> json) => ExerciseDetail(
        id: asInt(json['id']),
        wgerId: asIntOrNull(json['wgerId']),
        name: asString(json['name']),
        originalName: asString(json['originalName']),
        description: asStringOrNull(json['description']),
        categoryId: asIntOrNull(json['categoryId']),
        categoryName: asStringOrNull(json['categoryName']),
        images: asStringList(json['images']),
        videos: asStringList(json['videos']),
        primaryMuscles: asMapList(json['primaryMuscles']).map(Muscle.fromJson).toList(),
        secondaryMuscles: asMapList(json['secondaryMuscles']).map(Muscle.fromJson).toList(),
        equipment: asMapList(json['equipment']).map(NamedRef.fromJson).toList(),
      );
}

/// Filtros da tela de exercicios.
class ExerciseFilter {
  const ExerciseFilter({
    this.search = '',
    this.muscleId,
    this.equipmentId,
    this.categoryId,
    this.onlyWithImage = false,
    this.onlyWithVideo = false,
  });

  final String search;
  final int? muscleId;
  final int? equipmentId;
  final int? categoryId;
  final bool onlyWithImage;
  final bool onlyWithVideo;

  bool get hasFilters =>
      muscleId != null ||
      equipmentId != null ||
      categoryId != null ||
      onlyWithImage ||
      onlyWithVideo;

  int get activeCount =>
      (muscleId != null ? 1 : 0) +
      (equipmentId != null ? 1 : 0) +
      (categoryId != null ? 1 : 0) +
      (onlyWithImage ? 1 : 0) +
      (onlyWithVideo ? 1 : 0);

  ExerciseFilter copyWith({
    String? search,
    int? muscleId,
    int? equipmentId,
    int? categoryId,
    bool? onlyWithImage,
    bool? onlyWithVideo,
    bool clearMuscle = false,
    bool clearEquipment = false,
    bool clearCategory = false,
  }) {
    return ExerciseFilter(
      search: search ?? this.search,
      muscleId: clearMuscle ? null : (muscleId ?? this.muscleId),
      equipmentId: clearEquipment ? null : (equipmentId ?? this.equipmentId),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      onlyWithImage: onlyWithImage ?? this.onlyWithImage,
      onlyWithVideo: onlyWithVideo ?? this.onlyWithVideo,
    );
  }
}
