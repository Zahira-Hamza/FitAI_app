import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/workout.dart';
import '../../data/models/workout_session.dart';
import '../../data/services/firebase_service.dart';
import '../../core/utils/calorie_calculator.dart';
import 'user_profile_provider.dart';

class LoggedSet {
  final String exerciseId;
  final String exerciseName;
  final int setNumber;
  final int reps;
  final double weight;

  const LoggedSet({
    required this.exerciseId,
    required this.exerciseName,
    required this.setNumber,
    required this.reps,
    required this.weight,
  });

  Map<String, dynamic> toMap() => {
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'setNumber': setNumber,
        'reps': reps,
        'weight': weight,
      };
}

class ActiveWorkoutState {
  final Workout? workout;
  final int currentExerciseIndex;
  final int currentSetIndex;
  final bool isResting;
  final int restSecondsRemaining;
  final int elapsedSeconds;
  final List<LoggedSet> loggedSets;
  final Map<String, double> currentWeight;
  final bool isFinished;

  const ActiveWorkoutState({
    this.workout,
    this.currentExerciseIndex = 0,
    this.currentSetIndex = 0,
    this.isResting = false,
    this.restSecondsRemaining = 60,
    this.elapsedSeconds = 0,
    this.loggedSets = const [],
    this.currentWeight = const {},
    this.isFinished = false,
  });

  ActiveWorkoutState copyWith({
    Workout? workout,
    int? currentExerciseIndex,
    int? currentSetIndex,
    bool? isResting,
    int? restSecondsRemaining,
    int? elapsedSeconds,
    List<LoggedSet>? loggedSets,
    Map<String, double>? currentWeight,
    bool? isFinished,
  }) =>
      ActiveWorkoutState(
        workout: workout ?? this.workout,
        currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
        currentSetIndex: currentSetIndex ?? this.currentSetIndex,
        isResting: isResting ?? this.isResting,
        restSecondsRemaining: restSecondsRemaining ?? this.restSecondsRemaining,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
        loggedSets: loggedSets ?? this.loggedSets,
        currentWeight: currentWeight ?? this.currentWeight,
        isFinished: isFinished ?? this.isFinished,
      );

  bool get hasWorkout => workout != null;

  int get totalExercises => workout?.exercises.length ?? 0;

  int get totalSetsForCurrentExercise =>
      workout?.exercises[currentExerciseIndex].sets ?? 3;

  int get totalRepsForCurrentExercise =>
      workout?.exercises[currentExerciseIndex].reps ?? 12;

  String get currentExerciseName =>
      workout?.exercises[currentExerciseIndex].name ?? '';

  String get currentExerciseMuscles =>
      workout?.exercises[currentExerciseIndex].muscles.join(' • ').toUpperCase() ?? '';

  String? get nextExerciseName {
    if (workout == null) return null;
    final nextIdx = currentExerciseIndex + 1;
    if (nextIdx >= workout!.exercises.length) return null;
    return workout!.exercises[nextIdx].name;
  }

  double weightForCurrentExercise() {
    final id = workout?.exercises[currentExerciseIndex].id ?? '';
    return currentWeight[id] ?? 0;
  }

  double completionPercent() {
    if (workout == null || totalExercises == 0) return 0;
    return currentExerciseIndex / totalExercises;
  }
}

class ActiveWorkoutNotifier extends StateNotifier<ActiveWorkoutState> {
  final FirebaseService _firebaseService;
  Timer? _elapsedTimer;
  Timer? _restTimer;

  ActiveWorkoutNotifier(this._firebaseService) : super(const ActiveWorkoutState());

  void startWorkout(Workout workout) {
    _elapsedTimer?.cancel();
    _restTimer?.cancel();
    // Init weights from exercise defaults
    final weights = <String, double>{
      for (final e in workout.exercises) e.id: e.weight,
    };
    state = ActiveWorkoutState(
      workout: workout,
      currentWeight: weights,
    );
    _startElapsedTimer();
  }

  void _startElapsedTimer() {
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  void logSetComplete() {
    if (!state.hasWorkout) return;

    final exercise = state.workout!.exercises[state.currentExerciseIndex];
    final weight = state.weightForCurrentExercise();
    final newSet = LoggedSet(
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      setNumber: state.currentSetIndex + 1,
      reps: exercise.reps,
      weight: weight,
    );

    final updatedSets = [...state.loggedSets, newSet];
    final isLastSet = state.currentSetIndex >= exercise.sets - 1;
    final isLastExercise = state.currentExerciseIndex >= state.totalExercises - 1;

    if (isLastSet && isLastExercise) {
      // Workout done
      state = state.copyWith(loggedSets: updatedSets, isFinished: true);
      _elapsedTimer?.cancel();
      return;
    }

    if (isLastSet) {
      // Move to next exercise after rest
      state = state.copyWith(
        loggedSets: updatedSets,
        isResting: true,
        restSecondsRemaining: 60,
      );
      _startRestTimer(
        onComplete: () => _advanceExercise(),
      );
    } else {
      // Next set of same exercise after rest
      state = state.copyWith(
        loggedSets: updatedSets,
        isResting: true,
        restSecondsRemaining: 60,
      );
      _startRestTimer(
        onComplete: () {
          state = state.copyWith(
            isResting: false,
            currentSetIndex: state.currentSetIndex + 1,
          );
        },
      );
    }
  }

  void _startRestTimer({required VoidCallback onComplete}) {
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.restSecondsRemaining - 1;
      if (remaining <= 0) {
        timer.cancel();
        HapticFeedback.mediumImpact();
        onComplete();
      } else {
        state = state.copyWith(restSecondsRemaining: remaining);
      }
    });
  }

  void skipRest() {
    _restTimer?.cancel();
    if (state.currentSetIndex >= state.totalSetsForCurrentExercise - 1) {
      _advanceExercise();
    } else {
      state = state.copyWith(
        isResting: false,
        currentSetIndex: state.currentSetIndex + 1,
      );
    }
  }

  void _advanceExercise() {
    state = state.copyWith(
      isResting: false,
      currentExerciseIndex: state.currentExerciseIndex + 1,
      currentSetIndex: 0,
    );
  }

  void skipExercise() {
    if (!state.hasWorkout) return;
    final isLast = state.currentExerciseIndex >= state.totalExercises - 1;
    if (isLast) {
      state = state.copyWith(isFinished: true);
      _elapsedTimer?.cancel();
    } else {
      _restTimer?.cancel();
      _advanceExercise();
    }
  }

  void nextExercise() {
    if (state.currentExerciseIndex < state.totalExercises - 1) {
      _restTimer?.cancel();
      state = state.copyWith(
        currentExerciseIndex: state.currentExerciseIndex + 1,
        currentSetIndex: 0,
        isResting: false,
      );
    }
  }

  void previousExercise() {
    if (state.currentExerciseIndex > 0) {
      _restTimer?.cancel();
      state = state.copyWith(
        currentExerciseIndex: state.currentExerciseIndex - 1,
        currentSetIndex: 0,
        isResting: false,
      );
    }
  }

  void adjustWeight(String exerciseId, double delta) {
    final updated = Map<String, double>.from(state.currentWeight);
    final current = updated[exerciseId] ?? 0;
    updated[exerciseId] = (current + delta).clamp(0, 500);
    state = state.copyWith(currentWeight: updated);
  }

  Future<WorkoutSession> endWorkout({int rating = 0}) async {
    _elapsedTimer?.cancel();
    _restTimer?.cancel();

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final calories = CalorieCalculator.estimateFromDuration(state.elapsedSeconds);

    final session = WorkoutSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      workoutName: state.workout?.name ?? 'Workout',
      userId: uid,
      date: DateTime.now(),
      durationSeconds: state.elapsedSeconds,
      totalSets: state.loggedSets.length,
      exerciseCount: state.currentExerciseIndex + 1,
      caloriesBurned: calories,
      rating: rating,
      exerciseLog: state.loggedSets.map((s) => s.toMap()).toList(),
      muscleGroup: state.workout?.muscleGroup ?? '',
    );

    if (uid.isNotEmpty) {
      try {
        await _firebaseService.saveWorkoutSession(session);
      } catch (_) {}
    }

    state = const ActiveWorkoutState();
    return session;
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }
}

final activeWorkoutProvider =
    StateNotifierProvider<ActiveWorkoutNotifier, ActiveWorkoutState>((ref) {
  return ActiveWorkoutNotifier(ref.watch(firebaseServiceProvider));
});
