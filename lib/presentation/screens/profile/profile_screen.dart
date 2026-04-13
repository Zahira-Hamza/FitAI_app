import 'package:flutter/material.dart';
import '../../widgets/common/bottom_nav_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF12121D),
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Profile — Module 4', style: TextStyle(color: Colors.white))),
        bottomNavigationBar: const FitAIBottomNavBar(currentIndex: 4),
      );
}
