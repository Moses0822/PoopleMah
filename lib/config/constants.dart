import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  
  static const String modelName = 'gemini-1.5-flash-latest';
  
  static String get geminiApiUrl => 
      'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent';
  
  static bool get isApiKeyValid => geminiApiKey.isNotEmpty;
}