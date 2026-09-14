import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../models/pexels_photo.dart';

/// HTTP client for the Pexels API v1.
///
/// Fetches curated pose photography by predefined search queries.
/// Never exposes a user-facing search — queries are controlled internally.
class PexelsService {
  static const String _baseUrl = 'https://api.pexels.com/v1';

  String get _apiKey => dotenv.env['PEXELS_API_KEY'] ?? '';

  /// Fetch photos for a preset category query.
  ///
  /// Throws [PexelsApiException] on non-200 responses.
  /// Throws [PexelsNetworkException] on connectivity failures.
  Future<List<PexelsPhoto>> fetchCategory(
    String query, {
    int perPage = 20,
  }) async {
    if (_apiKey.isEmpty) {
      throw const PexelsApiException(
        'PEXELS_API_KEY not found in .env file',
        statusCode: 0,
      );
    }

    final uri = Uri.parse('$_baseUrl/search').replace(
      queryParameters: {
        'query': query,
        'per_page': perPage.toString(),
      },
    );

    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': _apiKey},
      );

      if (response.statusCode != 200) {
        throw PexelsApiException(
          'Pexels API returned ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final photos = (body['photos'] as List<dynamic>)
          .map((e) => PexelsPhoto.fromJson(e as Map<String, dynamic>))
          .toList();

      return photos;
    } on PexelsApiException {
      rethrow;
    } catch (e) {
      throw PexelsNetworkException(e.toString());
    }
  }
}

/// Thrown when the Pexels API returns a non-200 status code.
class PexelsApiException implements Exception {
  final String message;
  final int statusCode;

  const PexelsApiException(this.message, {required this.statusCode});

  @override
  String toString() => 'PexelsApiException($statusCode): $message';
}

/// Thrown on network connectivity failures.
class PexelsNetworkException implements Exception {
  final String message;

  const PexelsNetworkException(this.message);

  @override
  String toString() => 'PexelsNetworkException: $message';
}

/// Riverpod provider for the Pexels HTTP client.
final pexelsServiceProvider = Provider<PexelsService>((ref) {
  return PexelsService();
});
