import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import '../services/gemini_service.dart';

export '../services/gemini_service.dart' show GeneratedExercise, ChatMessage;

class AiRepository {
  final GeminiService _gemini;

  AiRepository(this._gemini);

  // ── Daily suggestion with same-day cache ──────────────────────

  Future<String> getDailySuggestion(UserProfile profile) async {
    final today = _todayKey();
    final cacheKey = 'daily_suggestion_$today';

    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(cacheKey);
      if (cached != null && cached.isNotEmpty) return cached;
    } catch (_) {}

    final suggestion = await _gemini.getDailySuggestion(profile);

    try {
      final prefs = await SharedPreferences.getInstance();
      // Cache only today — clear yesterday's key automatically next day
      await prefs.setString(cacheKey, suggestion);
    } catch (_) {}

    return suggestion;
  }

  // ── Plan generation — no cache (user picks params each time) ──

  Future<List<GeneratedExercise>> generateWorkoutPlan(
    String muscleGroup,
    int durationMinutes,
    UserProfile profile,
  ) async {
    return _gemini.generateWorkoutPlan(muscleGroup, durationMinutes, profile);
  }

  // ── Chat — always live ─────────────────────────────────────────

  Future<String> chat(
    List<ChatMessage> history,
    String newMessage,
  ) async {
    return _gemini.chat(history, newMessage);
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepository(ref.watch(geminiServiceProvider));
});
