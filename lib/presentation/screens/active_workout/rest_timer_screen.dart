// Rest timer is implemented as an overlay inside active_workout_screen.dart
// This file is kept for router compatibility.
import 'package:flutter/material.dart';

class RestTimerScreen extends StatelessWidget {
  const RestTimerScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: Color(0xFF12121D),
        body: Center(
          child: Text('Use active workout screen for rest timer.',
              style: TextStyle(color: Colors.white)),
        ),
      );
}
