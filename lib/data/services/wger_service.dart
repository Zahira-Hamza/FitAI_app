import 'package:dio/dio.dart';

import '../../core/errors/app_exception.dart';
import '../../core/network/dio_client.dart';
import '../models/exercise.dart';
import '../models/workout.dart';

class WgerService {
  final Dio _dio = DioClient.instance;

  static const String _base = 'https://wger.de/api/v2';

  static const Map<String, int> categoryIds = {
    'Chest': 11,
    'Back': 12,
    'Legs': 10,
    'Arms': 8,
    'Cardio': 15,
    'Shoulders': 13,
    'Core': 14,
  };

  Future<List<Exercise>> getExercises({
    String? category,
    int page = 0,
    int limit = 20,
  }) async {
    return safeRequest(() async {
      final params = <String, dynamic>{
        'format': 'json',
        'language': 2,
        'limit': limit,
        'offset': page * limit,
      };
      if (category != null && category != 'Full Body') {
        final id = categoryIds[category];
        if (id != null) params['category'] = id;
      }

      // Use /exerciseinfo/ — it returns names + muscles as full objects in one call
      final response = await _dio.get(
        '$_base/exerciseinfo/',
        queryParameters: params,
      );

      final results = (response.data['results'] as List<dynamic>?) ?? [];
      return results
          .whereType<Map<String, dynamic>>()
          .map(
            _exerciseFromInfo,
          ) // <-- use _exerciseFromInfo, not _exerciseFromWger
          .where((e) => e.name.isNotEmpty)
          .toList();
    });
  }

  Future<List<Exercise>> searchExercises(String query) async {
    return safeRequest(() async {
      final response = await _dio.get(
        '$_base/exercise/search/',
        queryParameters: {'term': query, 'language': 'en', 'format': 'json'},
      );
      try {
        final suggestions =
            response.data['suggestions'] as List<dynamic>? ?? [];
        return suggestions
            .map((s) {
              final data = s['data'] as Map<String, dynamic>? ?? {};
              return Exercise(
                id: data['id']?.toString() ?? '',
                name: s['value']?.toString() ?? '',
                muscleGroup: data['category']?.toString() ?? '',
              );
            })
            .where((e) => e.id.isNotEmpty)
            .toList();
      } catch (e) {
        throw ParseException(detail: e.toString());
      }
    });
  }

  Future<Exercise> getExerciseDetail(String id) async {
    return safeRequest(() async {
      final response = await _dio.get(
        '$_base/exerciseinfo/$id/',
        queryParameters: {'format': 'json'},
      );
      try {
        return _exerciseFromInfo(response.data as Map<String, dynamic>);
      } catch (e) {
        throw ParseException(detail: e.toString());
      }
    });
  }

  Workout buildWorkoutFromExercises(
    List<Exercise> exercises,
    String name,
    String category,
  ) {
    return Workout(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      category: category,
      muscleGroup: category,
      durationMinutes: (exercises.length * 6).clamp(15, 90),
      exerciseCount: exercises.length,
      exercises: exercises.map((e) => e.copyWith(sets: 3, reps: 12)).toList(),
      difficulty: 'Intermediate',
    );
  }

  // ── Parsers ────────────────────────────────────────────────────────────────

  Exercise _exerciseFromWger(Map<String, dynamic> e) {
    // /exercise/ endpoint returns flat fields: id, name, category, muscles (as int IDs)
    // It does NOT have a translations field — that's only on /exerciseinfo/
    final name = e['name']?.toString() ?? '';

    // muscles is List<int> here — just store as strings, don't try to read ['name_en']
    final muscleIds =
        (e['muscles'] as List<dynamic>?)?.map((m) => m.toString()).toList() ??
        [];

    return Exercise(
      id: e['id']?.toString() ?? '',
      name: name,
      muscleGroup: e['category']?['name']?.toString() ?? '',
      muscles: muscleIds,
    );
  }

  Exercise _exerciseFromInfo(Map<String, dynamic> e) {
    String name = _extractEnglishName(e['translations']);
    if (name.isEmpty) name = e['name']?.toString() ?? '';

    String description = '';
    final translations = e['translations'] as List<dynamic>?;
    if (translations != null) {
      final en = _firstEnglish(translations);
      if (en != null) {
        final raw = (en as Map)['description']?.toString() ?? '';
        description = raw.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      }
    }

    // /exerciseinfo/ returns full muscle objects — safe to read ['name_en']
    final muscles = _parseMuscleObjects(e['muscles']);
    final musclesSecondary = _parseMuscleObjects(e['muscles_secondary']);

    final images = e['images'] as List<dynamic>?;
    final imageUrl = images != null && images.isNotEmpty
        ? images.first['image']?.toString() ?? ''
        : '';

    return Exercise(
      id: e['id']?.toString() ?? '',
      name: name,
      description: description,
      muscleGroup: e['category']?['name']?.toString() ?? '',
      muscles: muscles,
      musclesSecondary: musclesSecondary,
      imageUrl: imageUrl,
    );
  }

  String _extractEnglishName(dynamic translations) {
    if (translations == null) return '';
    final list = translations as List<dynamic>;
    final en = _firstEnglish(list);
    return en != null ? (en as Map)['name']?.toString() ?? '' : '';
  }

  dynamic _firstEnglish(List<dynamic> list) {
    try {
      return list.firstWhere(
        (t) => (t as Map)['language'] == 2,
        orElse: () => list.isNotEmpty ? list.first : null,
      );
    } catch (_) {
      return list.isNotEmpty ? list.first : null;
    }
  }

  List<String> _parseMuscleObjects(dynamic muscles) {
    if (muscles == null) return [];
    return (muscles as List<dynamic>)
        .map((m) {
          if (m is Map) {
            return m['name_en']?.toString() ?? m['name']?.toString() ?? '';
          }
          return ''; // guard: ID-only, skip
        })
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
