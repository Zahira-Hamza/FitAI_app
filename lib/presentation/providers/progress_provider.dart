import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/workout_session.dart';
import '../../data/models/personal_record.dart';
import '../../data/services/firebase_service.dart';
import 'user_profile_provider.dart';

class ProgressState {
  final DateTime selectedDate;
  final List<WorkoutSession> weeklySessions;
  final List<WorkoutSession> last6WeeksSessions;
  final List<PersonalRecord> personalRecords;
  final bool isLoading;
  final String? error;

  const ProgressState({
    required this.selectedDate,
    this.weeklySessions = const [],
    this.last6WeeksSessions = const [],
    this.personalRecords = const [],
    this.isLoading = false,
    this.error,
  });

  ProgressState copyWith({
    DateTime? selectedDate,
    List<WorkoutSession>? weeklySessions,
    List<WorkoutSession>? last6WeeksSessions,
    List<PersonalRecord>? personalRecords,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      ProgressState(
        selectedDate: selectedDate ?? this.selectedDate,
        weeklySessions: weeklySessions ?? this.weeklySessions,
        last6WeeksSessions: last6WeeksSessions ?? this.last6WeeksSessions,
        personalRecords: personalRecords ?? this.personalRecords,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );

  // ── Week helpers ─────────────────────────────────────────────

  List<DateTime> getWeekDays() {
    final monday = selectedDate
        .subtract(Duration(days: selectedDate.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  DateTime get _mondayOfSelected =>
      selectedDate.subtract(Duration(days: selectedDate.weekday - 1));

  // ── Computed stats ───────────────────────────────────────────

  int get totalWorkouts => weeklySessions.length;

  String get totalDurationFormatted {
    final secs =
    weeklySessions.fold<int>(0, (s, e) => s + e.durationSeconds);
    final hours = secs / 3600;
    return '${hours.toStringAsFixed(1)}h';
  }

  String get totalCaloriesFormatted {
    final cal =
    weeklySessions.fold<double>(0, (s, e) => s + e.caloriesBurned);
    return cal >= 1000
        ? '${(cal / 1000).toStringAsFixed(1)}k'
        : cal.toStringAsFixed(0);
  }

  /// Workout count per week for the last 6 weeks (oldest → newest).
  List<double> get workoutsPerWeek {
    final now = DateTime.now();
    final thisMonday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(6, (i) {
      final weekStart = DateTime(
        thisMonday.year,
        thisMonday.month,
        thisMonday.day,
      ).subtract(Duration(days: (5 - i) * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));
      return last6WeeksSessions
          .where((s) =>
      !s.date.isBefore(weekStart) && s.date.isBefore(weekEnd))
          .length
          .toDouble();
    });
  }

  /// Calories per day for the selected week (Mon–Sun).
  List<double> get caloriesPerDay {
    return getWeekDays().map((day) {
      return weeklySessions
          .where((s) =>
      s.date.year == day.year &&
          s.date.month == day.month &&
          s.date.day == day.day)
          .fold<double>(0, (s, e) => s + e.caloriesBurned);
    }).toList();
  }

  double get avgDailyCalories {
    final nonZero = caloriesPerDay.where((c) => c > 0).toList();
    if (nonZero.isEmpty) return 0;
    return nonZero.reduce((a, b) => a + b) / nonZero.length;
  }

  /// Consecutive days with ≥1 session, counting back from today.
  int calculateStreak(List<WorkoutSession> allSessions) {
    if (allSessions.isEmpty) return 0;
    final sessionDays = allSessions
        .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
        .toSet();
    int streak = 0;
    var day = DateTime.now();
    day = DateTime(day.year, day.month, day.day);
    while (sessionDays.contains(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }
}

class ProgressNotifier extends StateNotifier<ProgressState> {
  final FirebaseService _svc;

  ProgressNotifier(this._svc)
      : super(ProgressState(selectedDate: DateTime.now())) {
    loadData();
  }

  Future<void> loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final sixWeeksAgo =
      weekStart.subtract(const Duration(days: 35));

      final results = await Future.wait([
        _svc.getWeeklySessions(
            uid,
            DateTime(
                weekStart.year, weekStart.month, weekStart.day)),
        _svc.getAllSessionsSince(uid,
            DateTime(sixWeeksAgo.year, sixWeeksAgo.month, sixWeeksAgo.day)),
        _svc.getPersonalRecords(uid),
      ]);

      state = state.copyWith(
        isLoading: false,
        weeklySessions: results[0] as List<WorkoutSession>,
        last6WeeksSessions: results[1] as List<WorkoutSession>,
        personalRecords: results[2] as List<PersonalRecord>,
      );
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          error: 'Failed to load progress data.');
    }
  }

  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
    _reloadWeekly(date);
  }

  Future<void> _reloadWeekly(DateTime date) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final monday =
      date.subtract(Duration(days: date.weekday - 1));
      final weekStart =
      DateTime(monday.year, monday.month, monday.day);
      final sessions =
      await _svc.getWeeklySessions(uid, weekStart);
      state = state.copyWith(weeklySessions: sessions);
    } catch (_) {}
  }

  void resetToCurrentWeek() {
    state = state.copyWith(selectedDate: DateTime.now());
    loadData();
  }
}

final progressProvider =
StateNotifierProvider<ProgressNotifier, ProgressState>((ref) {
  return ProgressNotifier(ref.watch(firebaseServiceProvider));
});

