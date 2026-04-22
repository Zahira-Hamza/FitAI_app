import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/personal_record.dart';
import '../../providers/progress_provider.dart';
import '../../widgets/charts/calories_bar_chart.dart';
import '../../widgets/charts/weekly_line_chart.dart';
import '../../widgets/common/bottom_nav_bar.dart';
import '../../widgets/common/fitai_card.dart';
import '../../widgets/common/shimmer_loader.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(progressProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF12121D),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF6C63FF),
          backgroundColor: const Color(0xFF1C1C2E),
          onRefresh: () => ref.read(progressProvider.notifier).loadData(),
          child: CustomScrollView(
            slivers: [
              // ── Header ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(state.selectedDate),
                        style: const TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref
                            .read(progressProvider.notifier)
                            .resetToCurrentWeek(),
                        child: const Text(
                          'THIS WEEK',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFC4C0FF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Date Strip ────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _DateStrip(state: state, ref: ref),
                ),
              ),

              // ── Loading ───────────────────────────────────────
              if (state.isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      children: [
                        ShimmerLoader(type: ShimmerType.statCard, count: 3),
                        const SizedBox(height: 16),
                        ShimmerLoader(type: ShimmerType.card, count: 2),
                      ],
                    ),
                  ),
                )
              else ...[
                // ── Stats Row ─────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _MiniStat(
                            icon: Icons.fitness_center,
                            iconColor: const Color(0xFFFF6584),
                            value: '${state.totalWorkouts}',
                            label: 'WORKOUTS',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniStat(
                            icon: Icons.timer_outlined,
                            iconColor: const Color(0xFFFF6584),
                            value: state.totalDurationFormatted,
                            label: 'DURATION',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniStat(
                            icon: Icons.local_fire_department,
                            iconColor: const Color(0xFF43E97B),
                            value: state.totalCaloriesFormatted,
                            label: 'CALORIES',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Line Chart ────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: FitAICard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Workouts per week',
                                style: TextStyle(
                                  fontFamily: 'SpaceGrotesk',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Icon(Icons.show_chart,
                                  color: Color(0xFF9E9EBE), size: 18),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Last 6 weeks',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 12,
                              color: Color(0xFF43E97B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          WeeklyLineChart(data: state.workoutsPerWeek),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Bar Chart ─────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: FitAICard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Calories burned',
                                style: TextStyle(
                                  fontFamily: 'SpaceGrotesk',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Icon(Icons.bar_chart,
                                  color: Color(0xFF9E9EBE), size: 18),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Daily average: ${state.avgDailyCalories.toStringAsFixed(0)} kcal',
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 12,
                              color: Color(0xFF9E9EBE),
                            ),
                          ),
                          const SizedBox(height: 16),
                          CaloriesBarChart(
                            data: state.caloriesPerDay,
                            todayIndex:
                                (DateTime.now().weekday - 1).clamp(0, 6),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Personal Records ──────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Personal Records',
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (state.personalRecords.length > 3)
                          TextButton(
                            onPressed: () =>
                                _showAllRecords(context, state.personalRecords),
                            child: const Text(
                              'VIEW ALL',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFC4C0FF),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                if (state.personalRecords.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: _EmptyRecords(),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _RecordTile(
                          record: state.personalRecords[i],
                          rank: i,
                        ),
                        childCount: state.personalRecords.length.clamp(0, 3),
                      ),
                    ),
                  ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const FitAIBottomNavBar(currentIndex: 3),
    );
  }

  void _showAllRecords(BuildContext context, List<PersonalRecord> records) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, ctrl) => Column(
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
            const Text('All Personal Records',
                style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: records.length,
                itemBuilder: (_, i) => _RecordTile(record: records[i], rank: i),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Date Strip ────────────────────────────────────────────────────────────────

class _DateStrip extends StatelessWidget {
  final ProgressState state;
  final WidgetRef ref;
  const _DateStrip({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    final days = state.getWeekDays();
    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days.map((day) {
          final isSel = day.year == state.selectedDate.year &&
              day.month == state.selectedDate.month &&
              day.day == state.selectedDate.day;
          final isToday = day.year == today.year &&
              day.month == today.month &&
              day.day == today.day;
          return GestureDetector(
            onTap: () => ref.read(progressProvider.notifier).selectDate(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isSel ? const Color(0xFF6C63FF) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('E').format(day)[0],
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSel ? Colors.white : const Color(0xFF9E9EBE),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSel
                          ? Colors.white
                          : isToday
                              ? const Color(0xFFC4C0FF)
                              : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Mini Stat Card ────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  const _MiniStat(
      {required this.icon,
      required this.iconColor,
      required this.value,
      required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.15)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 10,
                    color: Color(0xFF9E9EBE),
                    letterSpacing: 0.5)),
          ],
        ),
      );
}

// ── Record Tile ───────────────────────────────────────────────────────────────

class _RecordTile extends StatelessWidget {
  final PersonalRecord record;
  final int rank;
  const _RecordTile({required this.record, required this.rank});

  @override
  Widget build(BuildContext context) {
    final trophyColor = rank == 0
        ? const Color(0xFFFFD700)
        : rank == 1
            ? const Color(0xFF43E97B)
            : const Color(0xFF9E9EBE);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: trophyColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                Icon(Icons.emoji_events_rounded, color: trophyColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.exerciseName,
                    style: const TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                if (record.category.isNotEmpty)
                  Text(record.category,
                      style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11,
                          color: Color(0xFF9E9EBE))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${record.value.toStringAsFixed(1)} ${record.unit}',
                style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              Text(
                DateFormat('MMM d').format(record.date),
                style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11,
                    color: Color(0xFF9E9EBE)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyRecords extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C2E),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Column(
          children: [
            Icon(Icons.emoji_events_outlined,
                color: Color(0xFF5A5A7A), size: 48),
            SizedBox(height: 12),
            Text('No records yet',
                style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            SizedBox(height: 6),
            Text('Complete workouts to set records!',
                style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    color: Color(0xFF9E9EBE))),
          ],
        ),
      );
}
