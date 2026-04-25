import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiKeys {
  static const String wgerBaseUrl = 'https://wger.de/api/v2';

  /// Reads GROQ_API_KEY from .env file.
  /// Falls back to empty string so the app doesn't crash if .env is missing —
  /// AI features will show an error message instead.
  static String get groqApiKey =>
      dotenv.env['GROQ_API_KEY'] ?? '';
}
