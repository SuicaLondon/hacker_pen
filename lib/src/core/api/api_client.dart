import 'dart:convert';

import 'package:cached_query/cached_query.dart';
import 'package:http/http.dart' as http;

import 'api_exception.dart';

typedef JsonDecoder<T> = T Function(dynamic json);

class ApiClient {
  ApiClient({required String baseUrl, http.Client? httpClient})
    : _baseUri = Uri.parse(baseUrl),
      _httpClient = httpClient ?? http.Client();

  final Uri _baseUri;
  final http.Client _httpClient;

  Future<T> getJson<T>({
    required Object queryKey,
    required String path,
    required JsonDecoder<T> decode,
  }) async {
    final state = await Query<T>(
      key: queryKey,
      queryFn: () async {
        final json = await _getDecodedJson(path);
        return decode(json);
      },
    ).fetch();
    final data = state.data;

    if (data != null) return data;

    throw ApiException('No cached or fetched response for $path');
  }

  Future<dynamic> _getDecodedJson(String path) async {
    final uri = _baseUri.resolve(
      path.startsWith('/') ? path.substring(1) : path,
    );
    final response = await _httpClient.get(uri);

    if (response.statusCode != 200) {
      throw ApiException(
        'Request failed for $path',
        statusCode: response.statusCode,
      );
    }

    return jsonDecode(response.body);
  }
}
