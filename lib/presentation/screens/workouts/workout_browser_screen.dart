import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/exercise.dart';
import '../../providers/workout_provider.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../widgets/common/fitai_button.dart';
import '../../widgets/common/shimmer_loader.dart';

class WorkoutBrowserScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  const WorkoutBrowserScreen({super.key, this.initialCategory});

  @override
  ConsumerState<WorkoutBrowserScreen> createState() =>
      _WorkoutBrowserScreenState();
}

class _WorkoutBrowserScreenState extends ConsumerState<WorkoutBrowserScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  static const _categories = [
    'All',
    'Chest',
    'Back',
    'Legs',
    'Arms',
    'Cardio',
    'Core',
    'Shoulders',
  ];

  @override
  void initState() {
    super.initState();
    // Apply initial category from home quick-start chips
    if (widget.initialCategory != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(workoutBrowserProvider.notifier)
            .setCategory(widget.initialCategory);
      });
    }
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(workoutBrowserProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workoutBrowserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF12121D),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF6C63FF),
          backgroundColor: const Color(0xFF1C1C2E),
          onRefresh: () => ref.read(workoutBrowserProvider.notifier).refresh(),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // ── Header ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Workouts',
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Search bar
                      TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        onChanged: (v) => ref
                            .read(workoutBrowserProvider.notifier)
                            .setSearch(v),
                        decoration: InputDecoration(
                          hintText: 'Search exercises...',
                          hintStyle: const TextStyle(color: Color(0xFF5A5A7A)),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF5A5A7A),
                          ),
                          suffixIcon: state.searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Color(0xFF5A5A7A),
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref
                                        .read(workoutBrowserProvider.notifier)
                                        .setSearch('');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xFF1C1C2E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF6C63FF),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Category chips
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final cat = _categories[i];
                            final isAll = cat == 'All';
                            final selected = isAll
                                ? state.selectedCategory == null
                                : state.selectedCategory == cat;
                            return GestureDetector(
                              onTap: () => ref
                                  .read(workoutBrowserProvider.notifier)
                                  .setCategory(isAll ? null : cat),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFF6C63FF)
                                      : const Color(0xFF1C1C2E),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFF6C63FF)
                                        : const Color(
                                            0xFF6C63FF,
                                          ).withOpacity(0.2),
                                  ),
                                ),
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? Colors.white
                                        : const Color(0xFF9E9EBE),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // ── Content ───────────────────────────────────────
              if (state.isLoading)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: ShimmerLoader(type: ShimmerType.grid, count: 6),
                  ),
                )
              else if (state.error != null)
                SliverFillRemaining(
                  child: _ErrorState(
                    message: state.error!,
                    onRetry: () =>
                        ref.read(workoutBrowserProvider.notifier).refresh(),
                  ),
                )
              else if (state.exercises.isEmpty)
                SliverFillRemaining(
                  child: _EmptyState(
                    hasFilter:
                        state.selectedCategory != null ||
                        state.searchQuery.isNotEmpty,
                    onClear: () {
                      _searchController.clear();
                      ref
                          .read(workoutBrowserProvider.notifier)
                          .setCategory(null);
                      ref.read(workoutBrowserProvider.notifier).setSearch('');
                    },
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _ExerciseGridCard(
                        exercise: state.exercises[i],
                        onTap: () => _openDetail(context, state.exercises[i]),
                      ),
                      childCount: state.exercises.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                  ),
                ),
                if (state.isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF6C63FF),
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: const FitAIBottomNavBar(currentIndex: 1),
    );
  }

  void _openDetail(BuildContext context, Exercise exercise) {
    context.push(
      '/workout-detail/${exercise.id}',
      extra: {'exerciseName': exercise.name, 'category': exercise.muscleGroup},
    );
  }
}

// ── Grid Card ─────────────────────────────────────────────────────────────────

class _ExerciseGridCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;

  const _ExerciseGridCard({required this.exercise, required this.onTap});

  Color _categoryColor(String cat) {
    switch (cat.toLowerCase()) {
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

  IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'cardio':
        return Icons.directions_run;
      case 'legs':
        return Icons.accessibility_new;
      case 'core':
        return Icons.self_improvement;
      case 'shoulders':
        return Icons.accessibility;
      default:
        return Icons.fitness_center;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(exercise.muscleGroup);
    final icon = _categoryIcon(exercise.muscleGroup);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // KEY FIX — don't force max height
          children: [
            // Image / icon area
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
              child: exercise.imageUrl.isNotEmpty
                  ? Image.network(
                      exercise.imageUrl,
                      height: 90,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _IconPlaceholder(color: color, icon: icon),
                    )
                  : _IconPlaceholder(color: color, icon: icon),
            ),
            // Text section — no Expanded, no Spacer, no overflow
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    exercise.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  if (exercise.muscleGroup.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      exercise.muscleGroup,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 10,
                        color: Color(0xFF9E9EBE),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '3 × 12',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Shared placeholder used when image is missing
class _IconPlaceholder extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _IconPlaceholder({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    height: 90,
    width: double.infinity,
    color: color.withOpacity(0.12),
    child: Center(child: Icon(icon, color: color, size: 36)),
  );
}

// ── Empty / Error states ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onClear;
  const _EmptyState({required this.hasFilter, required this.onClear});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, color: Color(0xFF5A5A7A), size: 64),
          const SizedBox(height: 16),
          const Text(
            'No workouts found',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (hasFilter) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: 160,
              child: FitAIButton(label: 'Clear filters', onPressed: onClear),
            ),
          ],
        ],
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, color: Color(0xFF5A5A7A), size: 64),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              color: Color(0xFF9E9EBE),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 140,
            child: FitAIButton(label: 'Retry', onPressed: onRetry),
          ),
        ],
      ),
    ),
  );
}
