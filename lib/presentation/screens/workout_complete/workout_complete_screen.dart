import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/date_formatter.dart';
import '../../providers/active_workout_provider.dart';

// Holds the last completed session data so WorkoutCompleteScreen can read it
// even after the provider is reset.
class _CompletedSession {
  final int elapsedSeconds;
  final int totalSets;
  final int exerciseCount;
  final double calories;
  final String workoutName;
  final List<LoggedSet> loggedSets;
  _CompletedSession({
    required this.elapsedSeconds,
    required this.totalSets,
    required this.exerciseCount,
    required this.calories,
    required this.workoutName,
    required this.loggedSets,
  });
}

final _completedSessionProvider =
    StateProvider<_CompletedSession?>((ref) => null);

class WorkoutCompleteScreen extends ConsumerStatefulWidget {
  const WorkoutCompleteScreen({super.key});

  @override
  ConsumerState<WorkoutCompleteScreen> createState() =>
      _WorkoutCompleteScreenState();
}

class _WorkoutCompleteScreenState
    extends ConsumerState<WorkoutCompleteScreen>
    with SingleTickerProviderStateMixin {
  int _rating = 0;
  bool _saving = false;
  late _CompletedSession _session;
  late AnimationController _checkController;
  late Animation<double> _checkAnim;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _checkAnim = CurvedAnimation(
        parent: _checkController, curve: Curves.elasticOut);
    _checkController.forward();

    // Capture current state before it gets reset
    final workoutState = ref.read(activeWorkoutProvider);
    _session = _CompletedSession(
      elapsedSeconds: workoutState.elapsedSeconds,
      totalSets: workoutState.loggedSets.length,
      exerciseCount: workoutState.currentExerciseIndex + 1,
      calories: (workoutState.elapsedSeconds / 60) * 7,
      workoutName: workoutState.workout?.name ?? 'Workout',
      loggedSets: List.from(workoutState.loggedSets),
    );
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    setState(() => _saving = true);
    await ref.read(activeWorkoutProvider.notifier).endWorkout(rating: _rating);
    if (!mounted) return;
    context.go('/home');
  }

  void _viewSummary() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFF5A5A7A),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text('Workout Summary',
                style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _session.loggedSets.length,
                itemBuilder: (_, i) {
                  final s = _session.loggedSets[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF252538),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                              color: Color(0xFF6C63FF),
                              shape: BoxShape.circle),
                          child: Center(
                            child: Text('${s.setNumber}',
                                style: const TextStyle(
                                    fontFamily: 'SpaceGrotesk',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(s.exerciseName,
                              style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 13,
                                  color: Colors.white)),
                        ),
                        Text('${s.reps} reps  •  ${s.weight.toStringAsFixed(1)} kg',
                            style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 12,
                                color: Color(0xFF9E9EBE))),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121D),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Animated checkmark
              ScaleTransition(
                scale: _checkAnim,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF43E97B).withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFF43E97B), width: 2),
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Color(0xFF43E97B), size: 56),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Workout Complete!',
                  style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 8),
              const Text('You absolutely crushed today\'s goals.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      color: Color(0xFF9E9EBE))),
              const SizedBox(height: 28),
              // Stats grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _StatCell(
                      icon: Icons.timer_outlined,
                      iconColor: const Color(0xFFC4C0FF),
                      label: 'DURATION',
                      value: DateFormatter.formatDuration(
                          _session.elapsedSeconds)),
                  _StatCell(
                      icon: Icons.local_fire_department,
                      iconColor: const Color(0xFF43E97B),
                      label: 'BURNED',
                      value:
                          '${_session.calories.toStringAsFixed(0)} kcal'),
                  _StatCell(
                      icon: Icons.fitness_center,
                      iconColor: const Color(0xFFFF6584),
                      label: 'TOTAL SETS',
                      value: '${_session.totalSets}'),
                  _StatCell(
                      icon: Icons.list_alt_outlined,
                      iconColor: const Color(0xFFFFB347),
                      label: 'EXERCISES',
                      value: '${_session.exerciseCount}'),
                ],
              ),
              const SizedBox(height: 28),
              // Rating
              const Text('RATE YOUR PERFORMANCE',
                  style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF9E9EBE),
                      letterSpacing: 1)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final filled = i < _rating;
                  return GestureDetector(
                    onTap: () => setState(() => _rating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        filled ? Icons.star_rounded : Icons.star_border_rounded,
                        color: filled
                            ? const Color(0xFFFFD700)
                            : const Color(0xFF5A5A7A),
                        size: 36,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 28),
              // Buttons
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _saveAndContinue,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Save & Continue',
                          style: TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _viewSummary,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF6C63FF)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('View Summary',
                      style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFC4C0FF))),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _StatCell(
      {required this.icon,
      required this.iconColor,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C2E),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: const Color(0xFF6C63FF).withOpacity(0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 10,
                    color: Color(0xFF9E9EBE),
                    letterSpacing: 0.8)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ],
        ),
      );
}
