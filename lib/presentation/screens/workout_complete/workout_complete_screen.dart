import 'package:flutter/material.dart';

class WorkoutCompleteScreen extends StatelessWidget {
  const WorkoutCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: Color(0xFF12121D),
        body: Center(child: Text('Workout Complete — Module 3', style: TextStyle(color: Colors.white))),
      );
}
