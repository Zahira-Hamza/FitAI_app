class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String avatarUrl;
  final int age;
  final double weight;
  final double height;
  final String goal;
  final String level;
  final DateTime createdAt;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.avatarUrl = '',
    required this.age,
    required this.weight,
    required this.height,
    required this.goal,
    required this.level,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'avatarUrl': avatarUrl,
        'age': age,
        'weight': weight,
        'height': height,
        'goal': goal,
        'level': level,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        uid: map['uid'] as String? ?? '',
        name: map['name'] as String? ?? '',
        email: map['email'] as String? ?? '',
        avatarUrl: map['avatarUrl'] as String? ?? '',
        age: (map['age'] as num?)?.toInt() ?? 25,
        weight: (map['weight'] as num?)?.toDouble() ?? 70,
        height: (map['height'] as num?)?.toDouble() ?? 170,
        goal: map['goal'] as String? ?? 'stayActive',
        level: map['level'] as String? ?? 'beginner',
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );

  UserProfile copyWith({
    String? uid,
    String? name,
    String? email,
    String? avatarUrl,
    int? age,
    double? weight,
    double? height,
    String? goal,
    String? level,
    DateTime? createdAt,
  }) =>
      UserProfile(
        uid: uid ?? this.uid,
        name: name ?? this.name,
        email: email ?? this.email,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        age: age ?? this.age,
        weight: weight ?? this.weight,
        height: height ?? this.height,
        goal: goal ?? this.goal,
        level: level ?? this.level,
        createdAt: createdAt ?? this.createdAt,
      );

  String get firstName => name.split(' ').first;
}
