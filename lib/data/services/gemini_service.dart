import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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
  // Groq free tier: 30 req/min, 14,400 req/day — no credit card needed
  static const String _model = 'llama-3.3-70b-versatile';
  static const String _baseUrl = 'https://api.groq.com/openai/v1';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiKeys.groqApiKey}',
      },
    ),
  );

  // ── Core request ──────────────────────────────────────────────

  void _validateApiKey() {
    final key = ApiKeys.groqApiKey;
    if (key.isEmpty) {
      throw const ServerException(
        message: 'AI API key not configured. Please check your .env file.',
      );
    }
  }

  Future<String> _complete({
    required String systemPrompt,
    required String userMessage,
    List<ChatMessage> history = const [],
    int maxTokens = 500,
  }) async {
    _validateApiKey();
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      ...history.map(
        (m) => {
          'role': m.role == 'user' ? 'user' : 'assistant',
          'content': m.text,
        },
      ),
      {'role': 'user', 'content': userMessage},
    ];

    final response = await _dio.post(
      '/chat/completions',
      data: {
        'model': _model,
        'messages': messages,
        'max_tokens': maxTokens,
        'temperature': 0.7,
      },
    );

    final content =
        response.data['choices'][0]['message']['content']?.toString().trim() ??
        '';
    return content;
  }

  // ── Error classifier ──────────────────────────────────────────

  _AIErrorType _classifyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('rate_limit') ||
        msg.contains('429') ||
        msg.contains('quota')) {
      return _AIErrorType.quota;
    }
    if (msg.contains('401') ||
        msg.contains('invalid_api_key') ||
        msg.contains('unauthorized')) {
      return _AIErrorType.auth;
    }
    if (msg.contains('network') ||
        msg.contains('connection') ||
        msg.contains('socket') ||
        msg.contains('timeout')) {
      return _AIErrorType.network;
    }
    return _AIErrorType.unknown;
  }

  // ── Daily suggestion ──────────────────────────────────────────

  Future<String> getDailySuggestion(UserProfile profile) async {
    try {
      final text = await _complete(
        systemPrompt:
            'You are a professional fitness coach. Give short, energetic, specific advice.',
        userMessage:
            'User goal: ${profile.goal}, level: ${profile.level}. '
            'Give ONE workout suggestion in exactly 2 sentences. '
            'Return only the suggestion text, nothing else.',
        maxTokens: 100,
      );
      if (text.isEmpty) return _fallbackSuggestion(profile);
      return text;
    } catch (e) {
      debugPrint('[AI getDailySuggestion error] $e');
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
      final text = await _complete(
        systemPrompt:
            'You are a fitness coach. Return ONLY valid JSON arrays. '
            'No markdown, no code blocks, no explanation whatsoever. '
            'Your entire response must be parseable JSON.',
        userMessage:
            'Create a ${durationMinutes}-minute $muscleGroup workout '
            'for a ${profile.level} whose goal is ${profile.goal}. '
            'Return ONLY a JSON array with 4-6 exercises:\n'
            '[{"name":"Exercise Name","sets":3,"reps":"8-12","tip":"one sentence tip"}]',
        maxTokens: 600,
      );

      if (text.isEmpty) throw const UnknownException();

      // Strip any accidental markdown fences
      final cleaned = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // Extract JSON array even if model adds surrounding text
      final startIdx = cleaned.indexOf('[');
      final endIdx = cleaned.lastIndexOf(']');
      if (startIdx == -1 || endIdx == -1) {
        throw ParseException(
          detail: 'No JSON array found in response: $cleaned',
        );
      }
      final jsonStr = cleaned.substring(startIdx, endIdx + 1);

      final decoded = jsonDecode(jsonStr) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(GeneratedExercise.fromMap)
          .toList();
    } on AppException {
      rethrow;
    } catch (e) {
      debugPrint('[AI generateWorkoutPlan error] $e');
      final type = _classifyError(e);
      switch (type) {
        case _AIErrorType.quota:
          throw const ServerException(
            message:
                'AI rate limit reached. Please wait a moment and try again.',
          );
        case _AIErrorType.auth:
          throw const ServerException(
            message: 'Invalid AI API key. Please check api_keys.dart.',
          );
        case _AIErrorType.network:
          throw const NetworkException();
        default:
          throw ParseException(detail: e.toString());
      }
    }
  }

  // ── Chat ──────────────────────────────────────────────────────

  Future<String> chat(List<ChatMessage> history, String newMessage) async {
    try {
      final text = await _complete(
        systemPrompt:
            'You are FitAI Coach, a friendly and knowledgeable fitness expert. '
            'Keep responses concise, practical, and motivating. '
            'Max 3 sentences per reply. Use simple language.',
        userMessage: newMessage,
        history: history,
        maxTokens: 200,
      );
      if (text.isEmpty) {
        return "I'm having trouble connecting right now. Please try again.";
      }
      return text;
    } catch (e) {
      debugPrint('[AI chat error] $e');
      final type = _classifyError(e);
      switch (type) {
        case _AIErrorType.quota:
          return "I'm a bit busy right now — please try again in a moment! 🕐";
        case _AIErrorType.auth:
          return "AI configuration error. Please check your API key.";
        case _AIErrorType.network:
          return "No internet connection. Please check your network.";
        default:
          return "I'm having trouble connecting right now. Please try again.";
      }
    }
  }
}

enum _AIErrorType { quota, auth, network, unknown }
