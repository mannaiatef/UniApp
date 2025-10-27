import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MedicalChatService {
  static String get apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  static const String baseUrl = 'https://api.openai.com/v1/chat/completions';

  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
      if (apiKey.isEmpty) {
        throw Exception('OPENAI_API_KEY is missing in .env file');
      }
      print('MedicalChatService initialized with API key: ${apiKey.substring(0, 4)}...');
    } catch (e) {
      print('Failed to initialize MedicalChatService: $e');
      throw Exception('Failed to initialize MedicalChatService: $e');
    }
  }

  static Future<String> sendMedicalMessage(String message, {String model = 'gpt-4o'}) async {
    if (apiKey.isEmpty) {
      throw Exception('API key is missing. Ensure MedicalChatService is initialized.');
    }

    try {
      print('Sending request to $baseUrl with message: $message');
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({
          'model': model,
          'messages': [
            {'role': 'system', 'content': 'You are a medical assistant. Provide general advice.'},
            {'role': 'user', 'content': message},
          ],
          'max_tokens': 200,
          'temperature': 0.5,
        }),
      );

      print('Response received: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Failed to send message: $e');
      throw Exception('Failed to send message: $e');
    }
  }
}