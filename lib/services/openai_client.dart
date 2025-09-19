import 'dart:convert';

import 'package:http/http.dart' as http;

class OpenAIClient {
  final String apiKey;
  final String baseUrl;

  OpenAIClient({required this.apiKey, this.baseUrl = 'https://api.openai.com/v1'});

  Future<String> chatCompletion({
    required List<Map<String, String>> messages,
    String model = 'gpt-4o-mini',
    double temperature = 0.2,
    int maxTokens = 600,
  }) async {
    final uri = Uri.parse('$baseUrl/chat/completions');
    final body = jsonEncode({
      'model': model,
      'messages': messages,
      'temperature': temperature,
      'max_tokens': maxTokens,
    });

    final resp = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>?;
      if (choices != null && choices.isNotEmpty) {
        final msg = choices.first['message'] as Map<String, dynamic>;
        return (msg['content'] as String?)?.trim() ?? '';
      }
      return '';
    }
    throw Exception('OpenAI error ${resp.statusCode}: ${resp.body}');
  }
}

