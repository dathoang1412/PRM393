import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/publication.dart';

class OpenAlexService {
  OpenAlexService({http.Client? client}) : _client = client ?? http.Client();

  static const _apiHost = 'api.openalex.org';
  static const _selectedFields = [
    'id',
    'doi',
    'title',
    'display_name',
    'publication_year',
    'cited_by_count',
    'counts_by_year',
    'authorships',
    'primary_location',
    'abstract_inverted_index',
    'concepts',
    'type',
  ];

  final http.Client _client;

  /// Results per page. OpenAlex's basic (page-based) pagination only
  /// supports up to page * perPage <= 10,000 results — fine for this app,
  /// since users page through results incrementally via [loadMore].
  static const perPage = 100;

  Future<OpenAlexPage> searchWorks(String keyword, {int page = 1}) async {
    final queryParameters = <String, String>{
      'search': keyword,
      'page': '$page',
      'per-page': '$perPage',
      'sort': 'cited_by_count:desc',
      'select': _selectedFields.join(','),
    };

    final apiKey = dotenv.env['OPENALEX_API_KEY']?.trim();
    if (apiKey != null && apiKey.isNotEmpty) {
      queryParameters['api_key'] = apiKey;
    }

    final uri = Uri.https(_apiHost, '/works', queryParameters);

    try {
      final response = await _getWithRetry(uri);
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const OpenAlexException('Unexpected OpenAlex response format.');
      }

      final results = decoded['results'];
      final publications = results is List
          ? results
              .whereType<Map<String, dynamic>>()
              .map(Publication.fromJson)
              .toList()
          : <Publication>[];

      final meta = decoded['meta'];
      final metaCount = meta is Map<String, dynamic> ? meta['count'] : null;
      final totalCount =
          metaCount is num ? metaCount.toInt() : publications.length;

      return OpenAlexPage(publications: publications, totalCount: totalCount);
    } on SocketException {
      throw const OpenAlexException(
          'No internet connection. Check your network.');
    } on FormatException {
      throw const OpenAlexException('OpenAlex returned malformed data.');
    } on OpenAlexException {
      rethrow;
    } catch (_) {
      throw const OpenAlexException(
          'Unable to fetch publications. Try again.');
    }
  }

  Future<http.Response> _getWithRetry(Uri uri) async {
    const maxAttempts = 3;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      late final http.Response response;
      try {
        response =
            await _client.get(uri).timeout(const Duration(seconds: 30));
      } on TimeoutException {
        if (attempt < maxAttempts - 1) {
          await Future<void>.delayed(Duration(seconds: 1 << attempt));
          continue;
        }
        throw const OpenAlexException(
            'OpenAlex request timed out. Try again.');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }

      final shouldRetry =
          response.statusCode == 429 || response.statusCode >= 500;
      if (shouldRetry && attempt < maxAttempts - 1) {
        await Future<void>.delayed(Duration(seconds: 1 << attempt));
        continue;
      }

      throw OpenAlexException(_messageForStatus(response));
    }

    throw const OpenAlexException(
        'Unable to fetch publications. Try again.');
  }

  String _messageForStatus(http.Response response) {
    final apiMessage = _extractApiMessage(response.body);
    final suffix = apiMessage == null ? '' : ' $apiMessage';

    return switch (response.statusCode) {
      400 => 'OpenAlex rejected the request parameters.$suffix',
      403 => 'OpenAlex rate limit was exceeded. Try again later.$suffix',
      404 => 'OpenAlex endpoint or resource was not found.$suffix',
      429 => 'OpenAlex daily limit was exceeded. Try again later.$suffix',
      >= 500 =>
        'OpenAlex is temporarily unavailable. Try again later.$suffix',
      _ => 'OpenAlex returned status ${response.statusCode}.$suffix',
    };
  }

  String? _extractApiMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}

class OpenAlexException implements Exception {
  const OpenAlexException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// One page of search results plus the total match count reported by
/// OpenAlex, so callers know whether more pages are available.
class OpenAlexPage {
  const OpenAlexPage({required this.publications, required this.totalCount});

  final List<Publication> publications;
  final int totalCount;
}
