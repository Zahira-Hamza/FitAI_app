import 'package:flutter/material.dart';
import '../../widgets/common/bottom_nav_bar.dart';

class WorkoutBrowserScreen extends StatelessWidget {
  final String? initialCategory;
  const WorkoutBrowserScreen({super.key, this.initialCategory});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF12121D),
        appBar: AppBar(title: const Text('Workouts')),
        body: const Center(child: Text('Workout Browser — Module 3', style: TextStyle(color: Colors.white))),
        bottomNavigationBar: const FitAIBottomNavBar(currentIndex: 1),
      );
}
