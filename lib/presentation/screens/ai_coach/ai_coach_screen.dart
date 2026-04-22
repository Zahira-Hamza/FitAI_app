import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/exercise.dart';
import '../../../data/models/workout.dart';
import '../../../data/services/wger_service.dart';
import '../../providers/active_workout_provider.dart';
import '../../providers/ai_coach_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/workout_provider.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../widgets/common/fitai_button.dart';
import '../../widgets/common/fitai_card.dart';
import '../../widgets/common/shimmer_loader.dart';

class AiCoachScreen extends ConsumerStatefulWidget {
  const AiCoachScreen({super.key});

  @override
  ConsumerState<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends ConsumerState<AiCoachScreen> {
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();

  static const _muscleGroups = [
    'Full Body',
    'Chest',
    'Back',
    'Legs',
    'Core',
  ];
  static const _durations = [20, 30, 45, 60];
  static const _suggestions = [
    'Create a workout plan',
    'How do I lose weight?',
    'What should I eat post-workout?',
  ];

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _chatController.clear();
    ref.read(aiCoachProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiCoachProvider);

    // Auto-scroll when new message arrives
    ref.listen(aiCoachProvider, (_, next) {
      if (!next.isChatLoading) _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: const Color(0xFF12121D),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: const [
                  Icon(Icons.auto_awesome, color: Color(0xFFC4C0FF), size: 22),
                  SizedBox(width: 10),
                  Text(
                    'AI Coach',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable body ──────────────────────────────────
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                children: [
                  // Plan generator card
                  _PlanGeneratorCard(state: state),
                  const SizedBox(height: 16),

                  // Generated plan
                  if (state.isGenerating)
                    ShimmerLoader(type: ShimmerType.listTile, count: 4),

                  if (!state.isGenerating && state.generatedPlan.isNotEmpty)
                    _GeneratedPlanCard(
                      state: state,
                      onStartWorkout: () =>
                          _startGeneratedWorkout(context, ref, state),
                    ),

                  if (state.planError != null)
                    _ErrorCard(
                      message: state.planError!,
                      onRetry: () {
                        final profile = ref.read(userProfileProvider).profile;
                        if (profile != null) {
                          ref
                              .read(aiCoachProvider.notifier)
                              .generatePlan(profile);
                        }
                      },
                    ),

                  const SizedBox(height: 8),
                  const Divider(color: Color(0xFF252538)),
                  const SizedBox(height: 8),

                  // Chat section header
                  const Row(
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          color: Color(0xFF9E9EBE), size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Chat with Coach',
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Empty chat suggestions
                  if (state.chatMessages.isEmpty)
                    _SuggestionChips(
                      suggestions: _suggestions,
                      onTap: _sendMessage,
                    ),

                  // Messages
                  ...state.chatMessages.map((msg) => _ChatBubble(msg: msg)),

                  // Typing indicator
                  if (state.isChatLoading) const _TypingIndicator(),

                  // Chat error
                  if (state.chatError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        state.chatError!,
                        style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            color: Color(0xFFFF6584)),
                      ),
                    ),

                  const SizedBox(height: 8),
                ],
              ),
            ),

            // ── Chat input ───────────────────────────────────────
            _ChatInput(
              controller: _chatController,
              isLoading: state.isChatLoading,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
      bottomNavigationBar: const FitAIBottomNavBar(currentIndex: 2),
    );
  }

  void _startGeneratedWorkout(
      BuildContext context, WidgetRef ref, AiCoachState state) {
    final exercises = state.generatedPlan.map((e) {
      final sets = e.sets;
      final reps = int.tryParse(e.reps.split('-').first) ?? 12;
      return Exercise(
        id: e.name.replaceAll(' ', '_').toLowerCase(),
        name: e.name,
        description: e.tip,
        muscleGroup: state.selectedMuscleGroup,
        sets: sets,
        reps: reps,
      );
    }).toList();

    final workout = ref.read(wgerServiceProvider).buildWorkoutFromExercises(
          exercises,
          '${state.selectedMuscleGroup} ${state.selectedDuration}min',
          state.selectedMuscleGroup,
        );

    ref.read(activeWorkoutProvider.notifier).startWorkout(workout);
    context.go('/active-workout');
  }
}

// ── Plan Generator Card ───────────────────────────────────────────────────────

class _PlanGeneratorCard extends ConsumerWidget {
  final AiCoachState state;
  const _PlanGeneratorCard({required this.state});

  static const _muscleGroups = [
    'Full Body',
    'Chest',
    'Back',
    'Legs',
    'Core',
  ];
  static const _durations = [20, 30, 45, 60];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FitAICard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Generate a Plan',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Tell me your focus and available time.',
            style: TextStyle(
                fontFamily: 'Manrope', fontSize: 13, color: Color(0xFF9E9EBE)),
          ),
          const SizedBox(height: 14),

          // Muscle groups
          const Text('MUSCLE GROUPS',
              style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF9E9EBE),
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _muscleGroups.map((g) {
              final sel = state.selectedMuscleGroup == g;
              return _Pill(
                label: g,
                selected: sel,
                onTap: () =>
                    ref.read(aiCoachProvider.notifier).setMuscleGroup(g),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Duration
          const Text('DURATION',
              style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF9E9EBE),
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          Row(
            children: _durations.map((d) {
              final sel = state.selectedDuration == d;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _Pill(
                  label: '$d min',
                  selected: sel,
                  onTap: () =>
                      ref.read(aiCoachProvider.notifier).setDuration(d),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          FitAIButton(
            label: '⚡ Generate with AI',
            isLoading: state.isGenerating,
            onPressed: () {
              final profile = ref.read(userProfileProvider).profile;
              if (profile == null) return;
              ref.read(aiCoachProvider.notifier).generatePlan(profile);
            },
          ),
        ],
      ),
    );
  }
}

// ── Generated Plan Card ───────────────────────────────────────────────────────

class _GeneratedPlanCard extends StatelessWidget {
  final AiCoachState state;
  final VoidCallback onStartWorkout;
  const _GeneratedPlanCard({required this.state, required this.onStartWorkout});

  @override
  Widget build(BuildContext context) {
    return FitAICard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  color: Color(0xFFC4C0FF), size: 16),
              const SizedBox(width: 8),
              const Text(
                'Generated Plan',
                style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${state.selectedMuscleGroup} · ${state.selectedDuration} min',
                  style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      color: Color(0xFFC4C0FF)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...state.generatedPlan
              .asMap()
              .entries
              .map((e) => _ExerciseRow(index: e.key + 1, exercise: e.value)),
          const SizedBox(height: 14),
          FitAIButton(
            label: 'Start This Workout',
            onPressed: onStartWorkout,
          ),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final int index;
  final GeneratedExercise exercise;
  const _ExerciseRow({required this.index, required this.exercise});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: Color(0xFF6C63FF),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          exercise.name,
                          style: const TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                      Text(
                        '${exercise.sets} × ${exercise.reps}',
                        style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            color: Color(0xFF9E9EBE)),
                      ),
                    ],
                  ),
                  if (exercise.tip.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        exercise.tip,
                        style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF9E9EBE)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
}

// ── Chat Widgets ──────────────────────────────────────────────────────────────

class _SuggestionChips extends StatelessWidget {
  final List<String> suggestions;
  final void Function(String) onTap;
  const _SuggestionChips({required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions
            .map((s) => GestureDetector(
                  onTap: () => onTap(s),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C2E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF6C63FF).withOpacity(0.3)),
                    ),
                    child: Text(
                      s,
                      style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          color: Color(0xFFC4C0FF)),
                    ),
                  ),
                ))
            .toList(),
      );
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage msg;
  const _ChatBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_outlined,
                  color: Color(0xFFC4C0FF), size: 16),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color:
                    isUser ? const Color(0xFF6C63FF) : const Color(0xFF1C1C2E),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: const Color(0xFF6C63FF).withOpacity(0.15)),
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  color: isUser ? Colors.white : const Color(0xFFE8E8FF),
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_outlined,
                  color: Color(0xFFC4C0FF), size: 16),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFF6C63FF).withOpacity(0.15)),
              ),
              child: FadeTransition(
                opacity: _anim,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    3,
                    (i) => Container(
                      width: 6,
                      height: 6,
                      margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF9E9EBE),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final void Function(String) onSend;
  const _ChatInput(
      {required this.controller,
      required this.isLoading,
      required this.onSend});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF12121D),
          border: Border(
            top: BorderSide(color: const Color(0xFF6C63FF).withOpacity(0.15)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style:
                    const TextStyle(color: Colors.white, fontFamily: 'Manrope'),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: isLoading ? null : onSend,
                decoration: InputDecoration(
                  hintText: 'Message AI Coach...',
                  hintStyle: const TextStyle(color: Color(0xFF5A5A7A)),
                  filled: true,
                  fillColor: const Color(0xFF1C1C2E),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:
                        const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: isLoading ? null : () => onSend(controller.text),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isLoading
                      ? const Color(0xFF252538)
                      : const Color(0xFF6C63FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: isLoading ? const Color(0xFF5A5A7A) : Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      );
}

// ── Shared pill widget ────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Pill(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF6C63FF) : const Color(0xFF252538),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? const Color(0xFF6C63FF)
                  : const Color(0xFF6C63FF).withOpacity(0.2),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF9E9EBE),
            ),
          ),
        ),
      );
}

// ── Error card ────────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFF6584).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFFF6584), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      color: Color(0xFF9E9EBE))),
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry',
                  style: TextStyle(
                      color: Color(0xFFC4C0FF),
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
}
