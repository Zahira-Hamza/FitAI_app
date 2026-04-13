class PersonalRecord {
  final String exerciseName;
  final String category;
  final String unit;
  final double value;
  final DateTime date;

  const PersonalRecord({
    required this.exerciseName,
    this.category = '',
    this.unit = 'kg',
    required this.value,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'exerciseName': exerciseName,
        'category': category,
        'unit': unit,
        'value': value,
        'date': date.toIso8601String(),
      };

  factory PersonalRecord.fromMap(Map<String, dynamic> map) => PersonalRecord(
        exerciseName: map['exerciseName'] as String? ?? '',
        category: map['category'] as String? ?? '',
        unit: map['unit'] as String? ?? 'kg',
        value: (map['value'] as num?)?.toDouble() ?? 0,
        date: map['date'] != null
            ? DateTime.tryParse(map['date'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
}
