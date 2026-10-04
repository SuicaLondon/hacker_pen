import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_exception.dart';
import 'ai_provider.dart';
import 'ai_settings.dart';

class AiApiClient {
  AiApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<List<String>> listModels({
    required AiSettings settings,
    required String apiKey,
  }) async {
    final models = <String>{};
    final cursors = <String>{};
    String? cursor;
    do {
      final query = switch (settings.providerId) {
        AiProviderId.anthropic => {'limit': '1000', 'after_id': ?cursor},
        AiProviderId.gemini => {'pageSize': '1000', 'pageToken': ?cursor},
        _ => <String, String>{},
      };
      final endpoint = _endpoint(settings.baseUrl, 'models');
      final response = await _httpClient
          .get(
            query.isEmpty ? endpoint : endpoint.replace(queryParameters: query),
            headers: _headers(settings.providerId, apiKey),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AiException(
          response.statusCode == 401 || response.statusCode == 403
              ? 'The provider rejected this API key. Check your key and permissions.'
              : 'Could not load models from this provider. Please try again.',
          statusCode: response.statusCode,
        );
      }
      final body = _tryDecodeJson(response.body);
      if (body is! Map<String, dynamic>) {
        throw const AiException('The provider returned an invalid model list.');
      }
      final entries =
          body[settings.providerId == AiProviderId.gemini ? 'models' : 'data'];
      if (entries is! List) {
        throw const AiException('The provider returned an invalid model list.');
      }
      for (final entry in entries.whereType<Map<String, dynamic>>()) {
        if (settings.providerId == AiProviderId.gemini &&
            (entry['supportedGenerationMethods'] is! List ||
                !(entry['supportedGenerationMethods'] as List).contains(
                  'generateContent',
                ))) {
          continue;
        }
        final id =
            entry[settings.providerId == AiProviderId.gemini ? 'name' : 'id'];
        if (id is String && id.trim().isNotEmpty) {
          models.add(id.trim().replaceFirst(RegExp(r'^models/'), ''));
        }
      }
      cursor = switch (settings.providerId) {
        AiProviderId.anthropic when body['has_more'] == true =>
          body['last_id'] as String?,
        AiProviderId.gemini => body['nextPageToken'] as String?,
        _ => null,
      };
      if (cursor != null && cursor.isNotEmpty && !cursors.add(cursor)) {
        throw const AiException('The provider returned an invalid model page.');
      }
    } while (cursor != null && cursor.isNotEmpty);
    return models.toList()..sort();
  }

  Future<String> completeText({
    required AiSettings settings,
    required String apiKey,
    required String systemPrompt,
    required String userPrompt,
  }) async {
    if (settings.model.trim().isEmpty) {
      throw const AiException('Choose a provider and model in Settings first.');
    }
    final path = switch (settings.providerId) {
      AiProviderId.anthropic => 'messages',
      AiProviderId.gemini =>
        'models/${Uri.encodeComponent(settings.model)}:generateContent',
      _ => 'chat/completions',
    };
    final payload = switch (settings.providerId) {
      AiProviderId.anthropic => {
        'model': settings.model,
        'max_tokens': 4096,
        'system': systemPrompt,
        'messages': [
          {'role': 'user', 'content': userPrompt},
        ],
      },
      AiProviderId.gemini => {
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt},
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': userPrompt},
            ],
          },
        ],
      },
      _ => {
        'model': settings.model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
      },
    };
    final response = await _httpClient.post(
      _endpoint(settings.baseUrl, path),
      headers: {
        ..._headers(settings.providerId, apiKey),
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );
    final body = _tryDecodeJson(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = switch (body) {
        {'error': {'message': final String message}} => message,
        _ => 'AI request failed.',
      };
      throw AiException(message, statusCode: response.statusCode);
    }
    final content = switch (settings.providerId) {
      AiProviderId.anthropic => switch (body) {
        {'content': final List blocks} =>
          blocks
              .whereType<Map<String, dynamic>>()
              .where((block) => block['type'] == 'text')
              .map((block) => block['text'])
              .whereType<String>()
              .join('\n')
              .trim(),
        _ => '',
      },
      AiProviderId.gemini => switch (body) {
        {'candidates': [{'content': {'parts': final List parts}}, ...]} =>
          parts
              .whereType<Map<String, dynamic>>()
              .where((part) => part['thought'] != true)
              .map((part) => part['text'])
              .whereType<String>()
              .join('\n')
              .trim(),
        _ => '',
      },
      _ => switch (body) {
        {'choices': [{'message': {'content': final String content}}, ...]} =>
          content.trim(),
        _ => '',
      },
    };
    if (content.isNotEmpty) return content;
    throw const AiException('AI response did not include text content.');
  }

  Map<String, String> _headers(AiProviderId provider, String apiKey) =>
      switch (provider) {
        AiProviderId.anthropic => {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        AiProviderId.gemini => {'x-goog-api-key': apiKey},
        _ => {'Authorization': 'Bearer $apiKey'},
      };

  dynamic _tryDecodeJson(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  Uri _endpoint(String baseUrl, String path) {
    final trimmed = baseUrl.trim();
    if (trimmed.isEmpty) {
      throw const AiException('AI provider base URL is not configured.');
    }
    final normalizedBaseUrl = trimmed.endsWith('/') ? trimmed : '$trimmed/';
    return Uri.parse(normalizedBaseUrl).resolve(path);
  }
}
