import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_exception.dart';
import 'ai_settings.dart';

class AiApiClient {
  AiApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<String> completeText({
    required AiSettings settings,
    required String apiKey,
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final endpoint = _chatCompletionsEndpoint(settings.baseUrl);
    final response = await _httpClient.post(
      endpoint,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': settings.model,
        'temperature': 0.2,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
      }),
    );

    final body = _tryDecodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = switch (body) {
        {'error': {'message': final String message}} => message,
        _ => 'AI request failed.',
      };
      throw AiException(message, statusCode: response.statusCode);
    }

    final content = switch (body) {
      {'choices': [{'message': {'content': final String content}}, ...]} =>
        content.trim(),
      _ => '',
    };

    if (content.isNotEmpty) return content;
    throw const AiException('AI response did not include text content.');
  }

  dynamic _tryDecodeJson(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  Uri _chatCompletionsEndpoint(String baseUrl) {
    final trimmed = baseUrl.trim();
    if (trimmed.isEmpty) {
      throw const AiException('AI provider base URL is not configured.');
    }

    final normalizedBaseUrl = trimmed.endsWith('/') ? trimmed : '$trimmed/';
    return Uri.parse(normalizedBaseUrl).resolve('chat/completions');
  }
}
