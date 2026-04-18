import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/date_formatter.dart';
import '../../providers/active_workout_provider.dart';
import '../../widgets/common/fitai_button.dart';

class ActiveWorkoutScreen extends ConsumerWidget {
  final Map<String, dynamic>? workoutData;
  const ActiveWorkoutScreen({super.key, this.workoutData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeWorkoutProvider);

    // Navigate to complete when finished
    ref.listen(activeWorkoutProvider, (prev, next) {
      if (next.isFinished && !(prev?.isFinished ?? false)) {
        context.go('/workout-complete');
      }
    });

    if (!state.hasWorkout) {
      return const Scaffold(
        backgroundColor: Color(0xFF12121D),
        body: Center(
          child: Text('No active workout',
              style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (_) => _showEndDialog(context, ref),
      child: Scaffold(
        backgroundColor: const Color(0xFF12121D),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _TopBar(state: state, ref: ref),
                  _ProgressRow(state: state),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        children: [
                          _ExerciseCard(state: state),
                          const SizedBox(height: 20),
                          _LogButton(ref: ref),
                          const SizedBox(height: 12),
                          _NavRow(state: state, ref: ref),
                          const SizedBox(height: 16),
                          _AICoachBar(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Rest timer overlay
              if (state.isResting) _RestOverlay(state: state, ref: ref),
            ],
          ),
        ),
      ),
    );
  }

  void _showEndDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('End workout?',
            style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        content: const Text('Your progress will be saved.',
            style: TextStyle(
                fontFamily: 'Manrope', color: Color(0xFF9E9EBE))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF9E9EBE))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(activeWorkoutProvider.notifier).endWorkout();
              if (context.mounted) context.go('/workout-complete');
            },
            child: const Text('End Workout',
                style: TextStyle(color: Color(0xFFFF6584))),
          ),
        ],
      ),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final ActiveWorkoutState state;
  final WidgetRef ref;
  const _TopBar({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.pause_circle_outline,
                  color: Color(0xFF9E9EBE)),
              onPressed: () {},
            ),
            Expanded(
              child: Text(
                state.workout?.name ?? '',
                style: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            GestureDetector(
              onTap: () => _showEndDialog(context, ref),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6584).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFF6584).withOpacity(0.4)),
                ),
                child: const Text('END SESSION',
                    style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF6584))),
              ),
            ),
          ],
        ),
      );

  void _showEndDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('End workout early?',
            style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        content: const Text('Your progress will be saved.',
            style: TextStyle(
                fontFamily: 'Manrope', color: Color(0xFF9E9EBE))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF9E9EBE))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(activeWorkoutProvider.notifier).endWorkout();
              if (context.mounted) context.go('/workout-complete');
            },
            child: const Text('End Workout',
                style: TextStyle(color: Color(0xFFFF6584))),
          ),
        ],
      ),
    );
  }
}

// ── Progress Row ──────────────────────────────────────────────────────────────

class _ProgressRow extends StatelessWidget {
  final ActiveWorkoutState state;
  const _ProgressRow({required this.state});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Exercise ${state.currentExerciseIndex + 1} of ${state.totalExercises}',
                  style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                Text(
                  '${(state.completionPercent() * 100).toInt()}% COMPLETED',
                  style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF43E97B)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: state.completionPercent(),
                minHeight: 4,
                backgroundColor: const Color(0xFF252538),
                color: const Color(0xFF6C63FF),
              ),
            ),
          ],
        ),
      );
}

// ── Exercise Card ─────────────────────────────────────────────────────────────

class _ExerciseCard extends StatefulWidget {
  final ActiveWorkoutState state;
  const _ExerciseCard({required this.state});

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _timerController;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            state.currentExerciseName,
            style: const TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          if (state.currentExerciseMuscles.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              state.currentExerciseMuscles,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12,
                color: Color(0xFF9E9EBE),
                letterSpacing: 0.8,
              ),
            ),
          ],
          const SizedBox(height: 20),
          // Timer circle
          SizedBox(
            width: 160,
            height: 160,
            child: AnimatedBuilder(
              animation: _timerController,
              builder: (_, __) => CustomPaint(
                painter: _TimerPainter(
                  progress: (state.elapsedSeconds % 60) / 60,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormatter.formatDuration(state.elapsedSeconds),
                        style: const TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text('ACTIVE SET',
                          style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 11,
                              color: Color(0xFF9E9EBE),
                              letterSpacing: 0.8)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Set / reps info
          Row(
            children: [
              Expanded(
                child: _StatMini(
                  label: 'CURRENT SET',
                  value:
                      '${state.currentSetIndex + 1}/${state.totalSetsForCurrentExercise}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatMini(
                  label: 'TARGET REPS',
                  value: '${state.totalRepsForCurrentExercise}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Weight adjuster
          Consumer(builder: (context, ref, _) {
            final exerciseId =
                state.workout?.exercises[state.currentExerciseIndex].id ?? '';
            final weight = state.weightForCurrentExercise();
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF252538),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Current Weight',
                      style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          color: Color(0xFF9E9EBE))),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove,
                            color: Colors.white, size: 18),
                        onPressed: () => ref
                            .read(activeWorkoutProvider.notifier)
                            .adjustWeight(exerciseId, -2.5),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '${weight.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add,
                            color: Colors.white, size: 18),
                        onPressed: () => ref
                            .read(activeWorkoutProvider.notifier)
                            .adjustWeight(exerciseId, 2.5),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  final String label;
  final String value;
  const _StatMini({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF252538),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 10,
                    color: Color(0xFF9E9EBE),
                    letterSpacing: 0.8)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ],
        ),
      );
}

class _TimerPainter extends CustomPainter {
  final double progress;
  const _TimerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final trackPaint = Paint()
      ..color = const Color(0xFF252538)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    final progressPaint = Paint()
      ..color = const Color(0xFFC4C0FF)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // start at top
      progress * 2 * 3.14159,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_TimerPainter old) => old.progress != progress;
}

// ── Log Button ────────────────────────────────────────────────────────────────

class _LogButton extends StatelessWidget {
  final WidgetRef ref;
  const _LogButton({required this.ref});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.check_circle_outline, color: Colors.white),
          label: const Text('LOG SET COMPLETE',
              style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          onPressed: () =>
              ref.read(activeWorkoutProvider.notifier).logSetComplete(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6584),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
}

// ── Nav Row ───────────────────────────────────────────────────────────────────

class _NavRow extends StatelessWidget {
  final ActiveWorkoutState state;
  final WidgetRef ref;
  const _NavRow({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left,
                color: Color(0xFF9E9EBE), size: 28),
            onPressed: state.currentExerciseIndex > 0
                ? () => ref
                    .read(activeWorkoutProvider.notifier)
                    .previousExercise()
                : null,
          ),
          TextButton(
            onPressed: () => _showSkipDialog(context, ref),
            child: const Text('SKIP EXERCISE',
                style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9E9EBE))),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right,
                color: Color(0xFF9E9EBE), size: 28),
            onPressed:
                state.currentExerciseIndex < state.totalExercises - 1
                    ? () => ref
                        .read(activeWorkoutProvider.notifier)
                        .nextExercise()
                    : null,
          ),
        ],
      );

  void _showSkipDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C2E),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Skip exercise?',
            style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF9E9EBE))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(activeWorkoutProvider.notifier).skipExercise();
            },
            child: const Text('Skip',
                style: TextStyle(color: Color(0xFFFF6584))),
          ),
        ],
      ),
    );
  }
}

// ── AI Coach Bar ──────────────────────────────────────────────────────────────

class _AICoachBar extends StatelessWidget {
  static const _tips = [
    'Keep your core engaged throughout.',
    'Breathe out on the effort phase.',
    'Great pace — focus on the squeeze.',
    'Control the movement, don\'t rush.',
    'Keep your back straight and neutral.',
  ];

  @override
  Widget build(BuildContext context) {
    final tip = _tips[DateTime.now().second % _tips.length];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.smart_toy_outlined,
              color: Color(0xFFC4C0FF), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI COACH',
                    style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFC4C0FF),
                        letterSpacing: 0.8)),
                Text('"$tip"',
                    style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF9E9EBE))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Rest Timer Overlay ────────────────────────────────────────────────────────

class _RestOverlay extends StatelessWidget {
  final ActiveWorkoutState state;
  final WidgetRef ref;
  const _RestOverlay({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFF12121D),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        state.workout?.name ?? '',
                        style: const TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6584).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('RESTING',
                          style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFF6584))),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Countdown ring
              SizedBox(
                width: 200,
                height: 200,
                child: CustomPaint(
                  painter: _RestTimerPainter(
                    progress: state.restSecondsRemaining / 60,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('REST',
                            style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 13,
                                color: Color(0xFF9E9EBE),
                                letterSpacing: 1)),
                        Text(
                          '${state.restSecondsRemaining}',
                          style: const TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const Text('SECONDS',
                            style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 11,
                                color: Color(0xFF9E9EBE),
                                letterSpacing: 0.8)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatMini(
                        label: 'NEXT SET',
                        value:
                            '${state.currentSetIndex + 1}/${state.totalSetsForCurrentExercise}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatMini(
                        label: 'EXERCISE',
                        value:
                            '${state.currentExerciseIndex + 1}/${state.totalExercises}',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Coming up card
              if (state.nextExerciseName != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C2E),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.fitness_center,
                              color: Color(0xFFC4C0FF), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('COMING UP',
                                  style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFFF6584),
                                      letterSpacing: 0.8)),
                              Text(
                                state.nextExerciseName!,
                                style: const TextStyle(
                                    fontFamily: 'SpaceGrotesk',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: OutlinedButton(
                  onPressed: () =>
                      ref.read(activeWorkoutProvider.notifier).skipRest(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFF6584)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 0),
                  ),
                  child: const Text('SKIP REST ▶▶',
                      style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF6584))),
                ),
              ),
              const SizedBox(height: 12),
              // Nav row (same style as active workout)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left,
                        color: Color(0xFF9E9EBE), size: 28),
                    onPressed: state.currentExerciseIndex > 0
                        ? () => ref
                            .read(activeWorkoutProvider.notifier)
                            .previousExercise()
                        : null,
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(activeWorkoutProvider.notifier).skipExercise(),
                    child: const Text('SKIP EXERCISE',
                        style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF9E9EBE))),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right,
                        color: Color(0xFF9E9EBE), size: 28),
                    onPressed:
                        state.currentExerciseIndex < state.totalExercises - 1
                            ? () => ref
                                .read(activeWorkoutProvider.notifier)
                                .nextExercise()
                            : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
}

class _RestTimerPainter extends CustomPainter {
  final double progress;
  const _RestTimerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = const Color(0xFF252538)
          ..strokeWidth = 10
          ..style = PaintingStyle.stroke);
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -1.5708,
        progress * 2 * 3.14159,
        false,
        Paint()
          ..color = const Color(0xFFFF6584)
          ..strokeWidth = 10
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_RestTimerPainter old) => old.progress != progress;
}
