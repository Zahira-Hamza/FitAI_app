import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/workout.dart';
import '../../../data/services/wger_service.dart';
import '../../providers/active_workout_provider.dart';
import '../../providers/workout_provider.dart';
import '../../widgets/common/fitai_button.dart';
import '../../widgets/common/shimmer_loader.dart';
import '../../widgets/workout/exercise_list_tile.dart';

final _exerciseDetailProvider =
    FutureProvider.autoDispose.family<Exercise, String>((ref, id) async {
  return ref.watch(wgerServiceProvider).getExerciseDetail(id);
});

class WorkoutDetailScreen extends ConsumerWidget {
  final String workoutId;
  final Map<String, dynamic>? extra;

  const WorkoutDetailScreen({super.key, required this.workoutId, this.extra});

  Color _categoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'chest': return const Color(0xFFFF6584);
      case 'back': return const Color(0xFF6C63FF);
      case 'legs': return const Color(0xFF43E97B);
      case 'arms': return const Color(0xFFFFB347);
      case 'cardio': return const Color(0xFF4FC3F7);
      case 'shoulders': return const Color(0xFFCE93D8);
      case 'core': return const Color(0xFFFFD54F);
      default: return const Color(0xFF9E9EBE);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseAsync = ref.watch(_exerciseDetailProvider(workoutId));
    final categoryName = extra?['category']?.toString() ?? '';
    final color = _categoryColor(categoryName);

    return Scaffold(
      backgroundColor: const Color(0xFF12121D),
      body: exerciseAsync.when(
        loading: () => const _DetailShimmer(),
        error: (e, _) => _DetailError(
          onRetry: () => ref.invalidate(_exerciseDetailProvider(workoutId)),
        ),
        data: (exercise) => _DetailContent(
          exercise: exercise,
          color: color,
          onStartWorkout: () => _startWorkout(context, ref, exercise),
        ),
      ),
    );
  }

  void _startWorkout(BuildContext context, WidgetRef ref, Exercise exercise) {
    final workout = ref
        .read(wgerServiceProvider)
        .buildWorkoutFromExercises(
          [exercise],
          exercise.name,
          exercise.muscleGroup,
        );
    ref.read(activeWorkoutProvider.notifier).startWorkout(workout);
    context.go('/active-workout');
  }
}

class _DetailContent extends StatelessWidget {
  final Exercise exercise;
  final Color color;
  final VoidCallback onStartWorkout;

  const _DetailContent({
    required this.exercise,
    required this.color,
    required this.onStartWorkout,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: const Color(0xFF12121D),
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C2E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        color.withOpacity(0.3),
                        const Color(0xFF12121D),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(Icons.fitness_center, color: color, size: 72),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Info chips row
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (exercise.muscleGroup.isNotEmpty)
                          _InfoChip(
                              label: exercise.muscleGroup, color: color),
                        _InfoChip(
                            icon: Icons.timer_outlined,
                            label: '~30 min',
                            color: const Color(0xFF9E9EBE)),
                        _InfoChip(
                            icon: Icons.repeat,
                            label: '3 × 12',
                            color: const Color(0xFF9E9EBE)),
                      ],
                    ),
                    // Muscles
                    if (exercise.muscles.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text('Primary Muscles',
                          style: TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: exercise.muscles
                            .map((m) => _InfoChip(label: m, color: color))
                            .toList(),
                      ),
                    ],
                    if (exercise.musclesSecondary.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Secondary Muscles',
                          style: TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: exercise.musclesSecondary
                            .map((m) => _InfoChip(
                                label: m,
                                color: const Color(0xFF9E9EBE)))
                            .toList(),
                      ),
                    ],
                    // Description
                    if (exercise.description.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text('Description',
                          style: TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 10),
                      Text(
                        exercise.description,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          color: Color(0xFF9E9EBE),
                          height: 1.6,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Text('Exercises',
                        style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 10),
                    ExerciseListTile(index: 1, exercise: exercise),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Sticky bottom button
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF12121D).withOpacity(0),
                  const Color(0xFF12121D),
                ],
              ),
            ),
            child: FitAIButton(
              label: 'Start Workout',
              onPressed: onStartWorkout,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _InfoChip({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: color, size: 13),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
      );
}

class _DetailShimmer extends StatelessWidget {
  const _DetailShimmer();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(20),
        child: ShimmerLoader(type: ShimmerType.card, count: 3),
      );
}

class _DetailError extends StatelessWidget {
  final VoidCallback onRetry;
  const _DetailError({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: Color(0xFFFF6584), size: 56),
            const SizedBox(height: 16),
            const Text('Failed to load workout details',
                style: TextStyle(
                    fontFamily: 'Manrope',
                    color: Color(0xFF9E9EBE),
                    fontSize: 14)),
            const SizedBox(height: 20),
            SizedBox(
                width: 140,
                child: FitAIButton(label: 'Retry', onPressed: onRetry)),
          ],
        ),
      );
}
