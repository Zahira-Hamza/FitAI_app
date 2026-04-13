import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/workout_session.dart';
import '../../../data/services/firebase_service.dart';
import '../../providers/user_profile_provider.dart';
import '../../widgets/common/fitai_card.dart';
import '../../widgets/common/fitai_button.dart';
import '../../widgets/common/stat_card.dart';
import '../../widgets/common/shimmer_loader.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../widgets/workout/workout_card.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _todaySessionsProvider = FutureProvider.autoDispose<List<WorkoutSession>>((ref) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return [];
  return ref.watch(firebaseServiceProvider).getTodaySessions(uid);
});

final _recentSessionsProvider = FutureProvider.autoDispose<List<WorkoutSession>>((ref) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return [];
  return ref.watch(firebaseServiceProvider).getRecentSessions(uid, limit: 3);
});

// Stub for AI suggestion — replaced in Module 5
final _aiSuggestionProvider = FutureProvider.autoDispose<String>((ref) async {
  await Future.delayed(const Duration(milliseconds: 800));
  return "Based on your goals, try a 30-min upper body session today. Your recovery looks great — perfect time to push your limits.";
});

// ── Screen ────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _quickStartCategories = [
    'Chest', 'Back', 'Legs', 'Arms', 'Cardio', 'Full Body',
  ];

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(userProfileProvider);
    final firstName = profileState.profile?.firstName ?? 'Athlete';

    return Scaffold(
      backgroundColor: const Color(0xFF12121D),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF6C63FF),
          backgroundColor: const Color(0xFF1C1C2E),
          onRefresh: () async {
            ref.invalidate(_todaySessionsProvider);
            ref.invalidate(_recentSessionsProvider);
            ref.invalidate(_aiSuggestionProvider);
          },
          child: CustomScrollView(
            slivers: [
              // ── App Bar ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      _AvatarWidget(
                        avatarUrl: profileState.profile?.avatarUrl ?? '',
                        name: firstName,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_greeting()}, $firstName 👋',
                              style: const TextStyle(
                                fontFamily: 'SpaceGrotesk',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              "Let's crush it today",
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 13,
                                color: Color(0xFF9E9EBE),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined,
                            color: Colors.white),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Notifications coming soon',
                                  style: TextStyle(color: Colors.white)),
                              backgroundColor: Color(0xFF252538),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // ── AI Suggestion ─────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _AISuggestionBanner(ref: ref),
                ),
              ),

              // ── Today's Summary ───────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's Summary",
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _TodaySummaryRow(ref: ref),
                    ],
                  ),
                ),
              ),

              // ── Quick Start ───────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Start',
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _quickStartCategories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final cat = _quickStartCategories[i];
                            return GestureDetector(
                              onTap: () => context.go(
                                '/workouts',
                                extra: {'category': cat},
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF252538),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF6C63FF)
                                        .withOpacity(0.2),
                                  ),
                                ),
                                child: Text(
                                  cat,
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF9E9EBE),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Recent Workouts ───────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Workouts',
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/workouts'),
                        child: const Text(
                          'SEE ALL',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFC4C0FF),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                sliver: _RecentWorkoutsSliver(ref: ref),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const FitAIBottomNavBar(currentIndex: 0),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _AvatarWidget extends StatelessWidget {
  final String avatarUrl;
  final String name;
  const _AvatarWidget({required this.avatarUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(avatarUrl),
      );
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFF6C63FF),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'A',
        style: const TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _AISuggestionBanner extends ConsumerWidget {
  final WidgetRef ref;
  const _AISuggestionBanner({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestion = ref.watch(_aiSuggestionProvider);

    return suggestion.when(
      loading: () => const ShimmerLoader(type: ShimmerType.card, count: 1),
      error: (_, __) => FitAICard(
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFFFB347), size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Couldn't load suggestion.",
                style: TextStyle(
                    fontFamily: 'Manrope',
                    color: Color(0xFF9E9EBE),
                    fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(_aiSuggestionProvider),
              child: const Text('Retry',
                  style: TextStyle(color: Color(0xFFC4C0FF))),
            ),
          ],
        ),
      ),
      data: (text) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2D2B5E), Color(0xFF1C1C2E)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF6C63FF).withOpacity(0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.auto_awesome,
                    color: Color(0xFFC4C0FF), size: 16),
                SizedBox(width: 8),
                Text(
                  "TODAY'S AI SUGGESTION",
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC4C0FF),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              text,
              style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: 120,
              child: FitAIButton(
                label: 'View Plan',
                onPressed: () => context.go('/ai-coach'),
                borderRadius: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodaySummaryRow extends ConsumerWidget {
  final WidgetRef ref;
  const _TodaySummaryRow({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(_todaySessionsProvider);

    return sessions.when(
      loading: () => const ShimmerLoader(type: ShimmerType.statCard, count: 3),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) {
        final workouts = list.length;
        final kcal = list.fold<double>(0, (s, e) => s + e.caloriesBurned);
        final mins = list.fold<int>(0, (s, e) => s + e.durationMinutes);

        return Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.fitness_center,
                iconColor: const Color(0xFFFF6584),
                value: '$workouts',
                label: 'WORKOUTS',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                icon: Icons.local_fire_department,
                iconColor: const Color(0xFF43E97B),
                value: kcal.toStringAsFixed(0),
                label: 'KCAL',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                icon: Icons.timer_outlined,
                iconColor: const Color(0xFFC4C0FF),
                value: '$mins',
                label: 'MIN',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RecentWorkoutsSliver extends ConsumerWidget {
  final WidgetRef ref;
  const _RecentWorkoutsSliver({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(_recentSessionsProvider);

    return sessions.when(
      loading: () => SliverToBoxAdapter(
        child: ShimmerLoader(type: ShimmerType.listTile, count: 3),
      ),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (list) {
        if (list.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  const Icon(Icons.fitness_center,
                      color: Color(0xFF5A5A7A), size: 56),
                  const SizedBox(height: 16),
                  const Text(
                    'No workouts yet',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start your first workout to see it here',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      color: Color(0xFF9E9EBE),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 200,
                    child: FitAIButton(
                      label: 'Start a Workout',
                      onPressed: () => context.go('/workouts'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) => WorkoutCard(
              session: list[i],
              onTap: () {},
            ),
            childCount: list.length,
          ),
        );
      },
    );
  }
}
