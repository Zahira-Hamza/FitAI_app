class Exercise {
  final String id;
  final String name;
  final String description;
  final String muscleGroup;
  final int sets;
  final int reps;
  final double weight;
  final String imageUrl;
  final List<String> muscles;
  final List<String> musclesSecondary;

  const Exercise({
    required this.id,
    required this.name,
    this.description = '',
    this.muscleGroup = '',
    this.sets = 3,
    this.reps = 12,
    this.weight = 0,
    this.imageUrl = '',
    this.muscles = const [],
    this.musclesSecondary = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'muscleGroup': muscleGroup,
        'sets': sets,
        'reps': reps,
        'weight': weight,
        'imageUrl': imageUrl,
        'muscles': muscles,
        'musclesSecondary': musclesSecondary,
      };

  factory Exercise.fromMap(Map<String, dynamic> map) => Exercise(
        id: map['id']?.toString() ?? '',
        name: map['name'] as String? ?? 'Unknown Exercise',
        description: map['description'] as String? ?? '',
        muscleGroup: map['muscleGroup'] as String? ?? '',
        sets: (map['sets'] as num?)?.toInt() ?? 3,
        reps: (map['reps'] as num?)?.toInt() ?? 12,
        weight: (map['weight'] as num?)?.toDouble() ?? 0,
        imageUrl: map['imageUrl'] as String? ?? '',
        muscles: List<String>.from(map['muscles'] ?? []),
        musclesSecondary: List<String>.from(map['musclesSecondary'] ?? []),
      );

  Exercise copyWith({int? sets, int? reps, double? weight}) => Exercise(
        id: id,
        name: name,
        description: description,
        muscleGroup: muscleGroup,
        sets: sets ?? this.sets,
        reps: reps ?? this.reps,
        weight: weight ?? this.weight,
        imageUrl: imageUrl,
        muscles: muscles,
        musclesSecondary: musclesSecondary,
      );
}
