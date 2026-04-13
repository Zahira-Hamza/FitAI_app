import 'package:flutter/material.dart';

class ActiveWorkoutScreen extends StatelessWidget {
  final Map<String, dynamic>? workoutData;
  const ActiveWorkoutScreen({super.key, this.workoutData});

  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: Color(0xFF12121D),
        body: Center(child: Text('Active Workout — Module 3', style: TextStyle(color: Colors.white))),
      );
}
