import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/network/dio_client.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/exception_mappers.dart';
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

  Box<String> get _cache => Hive.box<String>('workouts_cache');

  Future<List<Exercise>> getExercises({
    String? category,
    int page = 0,
    int limit = 20,
  }) async {
    final cacheKey = 'exercises_${category ?? "all"}_${page}_$limit';

    // Return cache if available (offline or fresh hit)
    final cached = _cache.get(cacheKey);
    if (cached != null) {
      try {
        final list = jsonDecode(cached) as List;
        return list
            .whereType<Map<String, dynamic>>()
            .map(Exercise.fromMap)
            .toList();
      } catch (_) {} // corrupt cache — fall through to network
    }

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

      final response =
          await _dio.get('$_base/exerciseinfo/', queryParameters: params);

      try {
        final results =
            (response.data['results'] as List<dynamic>?) ?? [];
        final exercises = results
            .whereType<Map<String, dynamic>>()
            .map(_exerciseFromInfo)
            .where((e) => e.name.isNotEmpty)
            .toList();

        // Save to cache
        try {
          await _cache.put(
            cacheKey,
            jsonEncode(exercises.map((e) => e.toMap()).toList()),
          );
        } catch (_) {}

        return exercises;
      } catch (e) {
        throw ParseException(detail: e.toString());
      }
    });
  }

  Future<List<Exercise>> searchExercises(String query) async {
    return safeRequest(() async {
      final response = await _dio.get(
        '$_base/exercise/search/',
        queryParameters: {
          'term': query,
          'language': 'en',
          'format': 'json',
        },
      );
      try {
        final suggestions =
            response.data['suggestions'] as List<dynamic>? ?? [];
        return suggestions.map((s) {
          final data = s['data'] as Map<String, dynamic>? ?? {};
          return Exercise(
            id: data['id']?.toString() ?? '',
            name: s['value']?.toString() ?? '',
            muscleGroup: data['category']?.toString() ?? '',
          );
        }).where((e) => e.id.isNotEmpty).toList();
      } catch (e) {
        throw ParseException(detail: e.toString());
      }
    });
  }

  Future<Exercise> getExerciseDetail(String id) async {
    final cacheKey = 'exercise_detail_$id';
    final cached = _cache.get(cacheKey);
    if (cached != null) {
      try {
        return Exercise.fromMap(
            jsonDecode(cached) as Map<String, dynamic>);
      } catch (_) {}
    }

    return safeRequest(() async {
      final response = await _dio.get(
        '$_base/exerciseinfo/$id/',
        queryParameters: {'format': 'json'},
      );
      try {
        final exercise =
            _exerciseFromInfo(response.data as Map<String, dynamic>);
        try {
          await _cache.put(cacheKey, jsonEncode(exercise.toMap()));
        } catch (_) {}
        return exercise;
      } catch (e) {
        throw ParseException(detail: e.toString());
      }
    });
  }

  Workout buildWorkoutFromExercises(
      List<Exercise> exercises, String name, String category) {
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
    return (muscles as List<dynamic>).map((m) {
      if (m is Map) {
        return m['name_en']?.toString() ?? m['name']?.toString() ?? '';
      }
      return '';
    }).where((s) => s.isNotEmpty).toList();
  }
}
