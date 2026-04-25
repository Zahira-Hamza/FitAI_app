import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/exercise.dart';
import '../../data/services/wger_service.dart';

final wgerServiceProvider = Provider<WgerService>((ref) => WgerService());

class WorkoutBrowserState {
  final List<Exercise> exercises;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final String? selectedCategory;
  final String searchQuery;
  final int currentPage;
  final bool hasMore;

  const WorkoutBrowserState({
    this.exercises = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.selectedCategory,
    this.searchQuery = '',
    this.currentPage = 0,
    this.hasMore = true,
  });

  WorkoutBrowserState copyWith({
    List<Exercise>? exercises,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    String? selectedCategory,
    bool clearCategory = false,
    String? searchQuery,
    int? currentPage,
    bool? hasMore,
    bool clearError = false,
  }) => WorkoutBrowserState(
    exercises: exercises ?? this.exercises,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    error: clearError ? null : (error ?? this.error),
    selectedCategory: clearCategory
        ? null
        : (selectedCategory ?? this.selectedCategory),
    searchQuery: searchQuery ?? this.searchQuery,
    currentPage: currentPage ?? this.currentPage,
    hasMore: hasMore ?? this.hasMore,
  );
}

class WorkoutBrowserNotifier extends StateNotifier<WorkoutBrowserState> {
  final WgerService _wger;
  Timer? _debounce;

  WorkoutBrowserNotifier(this._wger) : super(const WorkoutBrowserState()) {
    loadExercises();
  }

  Future<void> loadExercises() async {
    state = state.copyWith(isLoading: true, currentPage: 0, clearError: true);
    try {
      final results = await _wger.getExercises(
        category: state.selectedCategory,
        page: 0,
      );
      state = state.copyWith(
        isLoading: false,
        exercises: results,
        currentPage: 0,
        hasMore: results.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.searchQuery.isNotEmpty)
      return;
    final nextPage = state.currentPage + 1;
    state = state.copyWith(isLoadingMore: true);
    try {
      final results = await _wger.getExercises(
        category: state.selectedCategory,
        page: nextPage,
      );
      state = state.copyWith(
        isLoadingMore: false,
        exercises: [...state.exercises, ...results],
        currentPage: nextPage,
        hasMore: results.length >= 20,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void setCategory(String? category) {
    if (state.selectedCategory == category) return;
    state = state.copyWith(
      selectedCategory: category,
      clearCategory: category == null,
      searchQuery: '',
    );
    loadExercises();
  }

  void setSearch(String query) {
    _debounce?.cancel();
    state = state.copyWith(searchQuery: query);

    if (query.isEmpty) {
      loadExercises();
      return;
    }

    // Don't search until user has typed at least 3 characters
    if (query.trim().length < 3) {
      // Clear results and show hint — don't show error
      state = state.copyWith(
        exercises: [],
        isLoading: false,
        hasMore: false,
        clearError: true,
      );
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 200), () async {
      state = state.copyWith(isLoading: true, clearError: true);
      try {
        final results = await _wger.searchExercises(query);
        state = state.copyWith(
          isLoading: false,
          exercises: results,
          hasMore: false,
        );
      } catch (e) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    });
  }

  Future<void> refresh() async => loadExercises();

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final workoutBrowserProvider =
    StateNotifierProvider<WorkoutBrowserNotifier, WorkoutBrowserState>(
      (ref) => WorkoutBrowserNotifier(ref.watch(wgerServiceProvider)),
    );
