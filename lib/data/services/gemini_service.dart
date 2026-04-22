import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../../core/constants/api_keys.dart';
import '../../core/errors/app_exception.dart';
import '../models/user_profile.dart';

// ── Data classes ──────────────────────────────────────────────────────────────

class GeneratedExercise {
  final String name;
  final int sets;
  final String reps;
  final String tip;

  const GeneratedExercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.tip,
  });

  factory GeneratedExercise.fromMap(Map<String, dynamic> m) =>
      GeneratedExercise(
        name: m['name']?.toString() ?? 'Exercise',
        sets: (m['sets'] as num?)?.toInt() ?? 3,
        reps: m['reps']?.toString() ?? '10-12',
        tip: m['tip']?.toString() ?? '',
      );
}

class ChatMessage {
  final String role; // 'user' | 'assistant'
  final String text;
  final DateTime timestamp;

  const ChatMessage({
    required this.role,
    required this.text,
    required this.timestamp,
  });
}

// ── Service ───────────────────────────────────────────────────────────────────

class GeminiService {
  static const String _model = 'gemini-1.5-flash';

  GenerativeModel get _generativeModel => GenerativeModel(
        model: _model,
        apiKey: ApiKeys.geminiApiKey,
      );

  // ── Daily suggestion ──────────────────────────────────────────

  Future<String> getDailySuggestion(UserProfile profile) async {
    try {
      final prompt = '''
You are a professional fitness coach.
Based on this user profile:
- Goal: ${profile.goal}
- Fitness level: ${profile.level}
Give ONE short motivational workout suggestion in exactly 2 sentences.
Be specific, energetic, and mention a workout type.
Return ONLY the suggestion text, nothing else.
''';
      final response = await _generativeModel.generateContent(
        [Content.text(prompt)],
      );
      final text = response.text?.trim() ?? '';
      if (text.isEmpty) return _fallbackSuggestion(profile);
      return text;
    } catch (_) {
      return _fallbackSuggestion(profile);
    }
  }

  String _fallbackSuggestion(UserProfile profile) {
    switch (profile.goal) {
      case 'loseWeight':
        return "Based on your goals, try a 30-min HIIT cardio session today. Keep your heart rate up and burn those calories!";
      case 'buildMuscle':
        return "Based on your goals, try a 45-min upper body strength session today. Focus on compound movements for maximum gains.";
      case 'improveEndurance':
        return "Based on your goals, try a 40-min steady-state cardio session today. Your aerobic base will thank you.";
      default:
        return "Based on your goals, try a 30-min full body workout today. Your recovery looks great — perfect time to push your limits.";
    }
  }

  // ── Generate workout plan ─────────────────────────────────────

  Future<List<GeneratedExercise>> generateWorkoutPlan(
    String muscleGroup,
    int durationMinutes,
    UserProfile profile,
  ) async {
    try {
      final prompt = '''
Create a ${durationMinutes}-minute $muscleGroup workout for a ${profile.level} level person whose goal is ${profile.goal}.
Return ONLY a valid JSON array with no markdown, no code block, no explanation:
[{"name":"Exercise Name","sets":3,"reps":"8-12","tip":"short form tip in one sentence"}]
Include 4-6 exercises. Reps should be a string like "8-12" or "12-15" or "30 sec".
''';

      final response = await _generativeModel.generateContent(
        [Content.text(prompt)],
      );

      final raw = response.text?.trim() ?? '';
      if (raw.isEmpty) throw const UnknownException();

      // Strip any accidental markdown fences
      final cleaned =
          raw.replaceAll('```json', '').replaceAll('```', '').trim();

      final decoded = jsonDecode(cleaned) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(GeneratedExercise.fromMap)
          .toList();
    } on AppException {
      rethrow;
    } catch (e) {
      throw ParseException(detail: e.toString());
    }
  }

  // ── Chat ──────────────────────────────────────────────────────

  Future<String> chat(
    List<ChatMessage> history,
    String newMessage,
  ) async {
    try {
      const systemContext = '''
You are FitAI Coach, a friendly and knowledgeable fitness expert.
Keep responses concise, practical, and motivating.
Max 3 sentences per reply. Use simple language.
If asked about exercises, give specific actionable advice.
''';

      // Build conversation history for Gemini
      final contents = <Content>[];

      // Add system context as first user message
      contents.add(Content.text(systemContext));

      // Add history
      for (final msg in history) {
        if (msg.role == 'user') {
          contents.add(Content.text(msg.text));
        } else {
          contents.add(Content.model([TextPart(msg.text)]));
        }
      }

      // Add new message
      contents.add(Content.text(newMessage));

      final response = await _generativeModel.generateContent(contents);
      final text = response.text?.trim() ?? '';
      if (text.isEmpty) {
        return "I'm having trouble connecting right now. Please try again.";
      }
      return text;
    } catch (_) {
      return "I'm having trouble connecting right now. Please try again.";
    }
  }
}
