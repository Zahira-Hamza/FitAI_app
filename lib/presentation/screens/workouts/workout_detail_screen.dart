import 'package:flutter/material.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final String workoutId;
  final Map<String, dynamic>? extra;
  const WorkoutDetailScreen({super.key, required this.workoutId, this.extra});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF12121D),
        appBar: AppBar(title: const Text('Workout Detail')),
        body: Center(child: Text('Workout Detail $workoutId — Module 3', style: const TextStyle(color: Colors.white))),
      );
}
