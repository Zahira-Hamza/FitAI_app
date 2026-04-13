class WorkoutSession {
  final String id;
  final String workoutName;
  final String userId;
  final DateTime date;
  final int durationSeconds;
  final int totalSets;
  final int exerciseCount;
  final double caloriesBurned;
  final int rating;
  final List<Map<String, dynamic>> exerciseLog;
  final String muscleGroup;

  const WorkoutSession({
    required this.id,
    required this.workoutName,
    required this.userId,
    required this.date,
    this.durationSeconds = 0,
    this.totalSets = 0,
    this.exerciseCount = 0,
    this.caloriesBurned = 0,
    this.rating = 0,
    this.exerciseLog = const [],
    this.muscleGroup = '',
  });

  int get durationMinutes => (durationSeconds / 60).round();

  Map<String, dynamic> toMap() => {
        'id': id,
        'workoutName': workoutName,
        'userId': userId,
        'date': date.toIso8601String(),
        'durationSeconds': durationSeconds,
        'totalSets': totalSets,
        'exerciseCount': exerciseCount,
        'caloriesBurned': caloriesBurned,
        'rating': rating,
        'exerciseLog': exerciseLog,
        'muscleGroup': muscleGroup,
      };

  factory WorkoutSession.fromMap(Map<String, dynamic> map) => WorkoutSession(
        id: map['id']?.toString() ?? '',
        workoutName: map['workoutName'] as String? ?? 'Workout',
        userId: map['userId'] as String? ?? '',
        date: map['date'] != null
            ? DateTime.tryParse(map['date'].toString()) ?? DateTime.now()
            : DateTime.now(),
        durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
        totalSets: (map['totalSets'] as num?)?.toInt() ?? 0,
        exerciseCount: (map['exerciseCount'] as num?)?.toInt() ?? 0,
        caloriesBurned: (map['caloriesBurned'] as num?)?.toDouble() ?? 0,
        rating: (map['rating'] as num?)?.toInt() ?? 0,
        exerciseLog: List<Map<String, dynamic>>.from(
          (map['exerciseLog'] as List<dynamic>?)?.map(
                (e) => Map<String, dynamic>.from(e as Map),
              ) ??
              [],
        ),
        muscleGroup: map['muscleGroup'] as String? ?? '',
      );
}
