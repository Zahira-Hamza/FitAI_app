import 'exercise.dart';

class Workout {
  final String id;
  final String name;
  final String description;
  final String category;
  final String difficulty;
  final int durationMinutes;
  final int exerciseCount;
  final List<Exercise> exercises;
  final String muscleGroup;

  const Workout({
    required this.id,
    required this.name,
    this.description = '',
    this.category = '',
    this.difficulty = 'Beginner',
    this.durationMinutes = 30,
    this.exerciseCount = 0,
    this.exercises = const [],
    this.muscleGroup = '',
  });

  int get actualExerciseCount => exercises.isEmpty ? exerciseCount : exercises.length;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'difficulty': difficulty,
        'durationMinutes': durationMinutes,
        'exerciseCount': exerciseCount,
        'exercises': exercises.map((e) => e.toMap()).toList(),
        'muscleGroup': muscleGroup,
      };

  factory Workout.fromMap(Map<String, dynamic> map) => Workout(
        id: map['id']?.toString() ?? '',
        name: map['name'] as String? ?? 'Workout',
        description: map['description'] as String? ?? '',
        category: map['category'] as String? ?? '',
        difficulty: map['difficulty'] as String? ?? 'Beginner',
        durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 30,
        exerciseCount: (map['exerciseCount'] as num?)?.toInt() ?? 0,
        exercises: (map['exercises'] as List<dynamic>?)
                ?.map((e) => Exercise.fromMap(e as Map<String, dynamic>))
                .toList() ??
            [],
        muscleGroup: map['muscleGroup'] as String? ?? '',
      );
}
