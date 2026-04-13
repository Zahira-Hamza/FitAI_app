import 'package:flutter/material.dart';
import '../../widgets/common/bottom_nav_bar.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF12121D),
        appBar: AppBar(title: const Text('Progress')),
        body: const Center(child: Text('Progress — Module 4', style: TextStyle(color: Colors.white))),
        bottomNavigationBar: const FitAIBottomNavBar(currentIndex: 3),
      );
}
