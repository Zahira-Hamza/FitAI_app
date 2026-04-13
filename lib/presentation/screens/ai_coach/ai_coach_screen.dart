import 'package:flutter/material.dart';
import '../../widgets/common/bottom_nav_bar.dart';

class AiCoachScreen extends StatelessWidget {
  const AiCoachScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF12121D),
        appBar: AppBar(title: const Text('AI Coach')),
        body: const Center(child: Text('AI Coach — Module 5', style: TextStyle(color: Colors.white))),
        bottomNavigationBar: const FitAIBottomNavBar(currentIndex: 2),
      );
}
