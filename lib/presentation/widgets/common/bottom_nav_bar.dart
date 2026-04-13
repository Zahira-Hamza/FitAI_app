import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FitAIBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const FitAIBottomNavBar({super.key, required this.currentIndex});

  static const _routes = ['/home', '/workouts', '/ai-coach', '/progress', '/profile'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C2E),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF6C63FF).withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        backgroundColor: Colors.transparent,
        selectedItemColor: const Color(0xFFC4C0FF),
        unselectedItemColor: const Color(0xFF5A5A7A),
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 11,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        onTap: (index) {
          if (index != currentIndex) {
            context.go(_routes[index]);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'HOME',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center_outlined),
            activeIcon: Icon(Icons.fitness_center),
            label: 'WORKOUTS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_outlined),
            activeIcon: Icon(Icons.smart_toy),
            label: 'AI COACH',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart_outlined),
            activeIcon: Icon(Icons.show_chart),
            label: 'PROGRESS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'PROFILE',
          ),
        ],
      ),
    );
  }
}
