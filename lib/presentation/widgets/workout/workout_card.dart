import 'package:flutter/material.dart';
import '../../../data/models/workout_session.dart';

class WorkoutCard extends StatelessWidget {
  final WorkoutSession session;
  final VoidCallback? onTap;

  const WorkoutCard({super.key, required this.session, this.onTap});

  static Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'chest':
        return const Color(0xFFFF6584);
      case 'back':
        return const Color(0xFF6C63FF);
      case 'legs':
        return const Color(0xFF43E97B);
      case 'arms':
        return const Color(0xFFFFB347);
      case 'cardio':
        return const Color(0xFF4FC3F7);
      case 'shoulders':
        return const Color(0xFFCE93D8);
      case 'core':
        return const Color(0xFFFFD54F);
      default:
        return const Color(0xFF9E9EBE);
    }
  }

  static IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'cardio':
        return Icons.directions_run;
      case 'legs':
        return Icons.accessibility_new;
      default:
        return Icons.fitness_center;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(session.muscleGroup);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF6C63FF).withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _categoryIcon(session.muscleGroup),
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.workoutName,
                    style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${session.durationMinutes} mins • ${session.exerciseCount} Exercises',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      color: Color(0xFF9E9EBE),
                    ),
                  ),
                  if (session.muscleGroup.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _CategoryPill(
                      label: session.muscleGroup,
                      color: color,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF5A5A7A),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  final Color color;

  const _CategoryPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
