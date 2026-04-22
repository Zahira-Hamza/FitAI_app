import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_profile.dart';
import '../../data/repositories/ai_repository.dart';

export '../../data/repositories/ai_repository.dart'
    show GeneratedExercise, ChatMessage;

// ── State ─────────────────────────────────────────────────────────────────────

class AiCoachState {
  final String selectedMuscleGroup;
  final int selectedDuration;
  final List<GeneratedExercise> generatedPlan;
  final bool isGenerating;
  final List<ChatMessage> chatMessages;
  final bool isChatLoading;
  final String? planError;
  final String? chatError;

  const AiCoachState({
    this.selectedMuscleGroup = 'Full Body',
    this.selectedDuration = 30,
    this.generatedPlan = const [],
    this.isGenerating = false,
    this.chatMessages = const [],
    this.isChatLoading = false,
    this.planError,
    this.chatError,
  });

  AiCoachState copyWith({
    String? selectedMuscleGroup,
    int? selectedDuration,
    List<GeneratedExercise>? generatedPlan,
    bool? isGenerating,
    List<ChatMessage>? chatMessages,
    bool? isChatLoading,
    String? planError,
    bool clearPlanError = false,
    String? chatError,
    bool clearChatError = false,
  }) =>
      AiCoachState(
        selectedMuscleGroup: selectedMuscleGroup ?? this.selectedMuscleGroup,
        selectedDuration: selectedDuration ?? this.selectedDuration,
        generatedPlan: generatedPlan ?? this.generatedPlan,
        isGenerating: isGenerating ?? this.isGenerating,
        chatMessages: chatMessages ?? this.chatMessages,
        isChatLoading: isChatLoading ?? this.isChatLoading,
        planError: clearPlanError ? null : (planError ?? this.planError),
        chatError: clearChatError ? null : (chatError ?? this.chatError),
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AiCoachNotifier extends StateNotifier<AiCoachState> {
  final AiRepository _repo;

  AiCoachNotifier(this._repo) : super(const AiCoachState());

  void setMuscleGroup(String group) =>
      state = state.copyWith(selectedMuscleGroup: group);

  void setDuration(int minutes) =>
      state = state.copyWith(selectedDuration: minutes);

  Future<void> generatePlan(UserProfile profile) async {
    state = state.copyWith(
      isGenerating: true,
      clearPlanError: true,
      generatedPlan: [],
    );
    try {
      final plan = await _repo.generateWorkoutPlan(
        state.selectedMuscleGroup,
        state.selectedDuration,
        profile,
      );
      state = state.copyWith(
        isGenerating: false,
        generatedPlan: plan,
      );
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        planError: "Couldn't generate plan. Check your internet and try again.",
      );
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      role: 'user',
      text: text.trim(),
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      chatMessages: [...state.chatMessages, userMsg],
      isChatLoading: true,
      clearChatError: true,
    );

    try {
      final response = await _repo.chat(
        // Pass history without the message just added
        state.chatMessages.sublist(0, state.chatMessages.length - 1),
        text.trim(),
      );
      final aiMsg = ChatMessage(
        role: 'assistant',
        text: response,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        chatMessages: [...state.chatMessages, aiMsg],
        isChatLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        isChatLoading: false,
        chatError: "Couldn't reach AI. Check your connection.",
      );
    }
  }

  void clearPlan() =>
      state = state.copyWith(generatedPlan: [], clearPlanError: true);

  void clearChatError() => state = state.copyWith(clearChatError: true);
}

// ── Provider ──────────────────────────────────────────────────────────────────

final aiCoachProvider =
    StateNotifierProvider<AiCoachNotifier, AiCoachState>((ref) {
  return AiCoachNotifier(ref.watch(aiRepositoryProvider));
});
