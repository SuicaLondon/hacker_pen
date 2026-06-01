import 'package:cached_query/cached_query.dart';
import 'package:http/http.dart' as http;

import '../utils/text_sanitizer.dart';
import 'ai_api_client.dart';
import 'ai_exception.dart';
import 'ai_provider.dart';
import 'ai_query_keys.dart';
import 'ai_settings_repository.dart';

class AiContentRepository {
  AiContentRepository({
    required AiSettingsRepository settingsRepository,
    AiApiClient? aiApiClient,
    http.Client? httpClient,
  }) : _settingsRepository = settingsRepository,
       _aiApiClient = aiApiClient ?? AiApiClient(),
       _httpClient = httpClient ?? http.Client();

  final AiSettingsRepository _settingsRepository;
  final AiApiClient _aiApiClient;
  final http.Client _httpClient;

  Future<String> summarizeWebPageUrl(String url) async {
    final pageText = await _fetchReadableUrlText(url);
    final settings = await _settingsRepository.load();
    final apiKey = await _requireApiKey(settings.providerId);

    final state = await Query<String>(
      key: AiQueryKeys.webPageSummary(
        provider: settings.providerId.storageKey,
        model: settings.model,
        language: settings.targetLanguage,
        url: url,
        content: pageText,
      ),
      queryFn: () => _aiApiClient.completeText(
        settings: settings,
        apiKey: apiKey,
        systemPrompt:
            'You summarize web pages for a Hacker News reader. '
            'Be concise, factual, and preserve important technical details.',
        userPrompt:
            'Summarize the following web page in ${settings.targetLanguage}. '
            'Return 3-6 bullet points and one short takeaway.\n\n'
            'URL: $url\n\n'
            '$pageText',
      ),
    ).fetch();

    return _requireCachedQueryData(state.data);
  }

  Future<String> translateComment(String rawCommentText) async {
    final commentText = TextSanitizer.stripHtml(rawCommentText);
    if (commentText.isEmpty) {
      throw const AiException('Comment text is empty.');
    }

    final settings = await _settingsRepository.load();
    final apiKey = await _requireApiKey(settings.providerId);

    final state = await Query<String>(
      key: AiQueryKeys.commentTranslation(
        provider: settings.providerId.storageKey,
        model: settings.model,
        language: settings.targetLanguage,
        comment: commentText,
      ),
      queryFn: () => _aiApiClient.completeText(
        settings: settings,
        apiKey: apiKey,
        systemPrompt:
            'You translate Hacker News comments. Preserve code, URLs, '
            'usernames, and quoted text. Do not add commentary.',
        userPrompt:
            'Translate this comment into ${settings.targetLanguage}:\n\n'
            '$commentText',
      ),
    ).fetch();

    return _requireCachedQueryData(state.data);
  }

  Future<String> _fetchReadableUrlText(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const AiException('Enter a valid URL to summarize.');
    }

    final response = await _httpClient.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiException(
        'Failed to load web page.',
        statusCode: response.statusCode,
      );
    }

    final text = TextSanitizer.stripHtml(
      response.body,
    ).replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) {
      throw const AiException('Web page did not include readable text.');
    }

    const maxCharacters = 24000;
    if (text.length <= maxCharacters) return text;
    return text.substring(0, maxCharacters);
  }

  Future<String> _requireApiKey(AiProviderId providerId) async {
    final apiKey = await _settingsRepository.readApiKey(providerId);
    if (apiKey == null || apiKey.isEmpty) {
      throw const AiException('Add an AI API key in Settings first.');
    }
    return apiKey;
  }

  String _requireCachedQueryData(String? data) {
    if (data != null && data.isNotEmpty) return data;
    throw const AiException('No AI result was returned.');
  }
}
