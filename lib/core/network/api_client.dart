import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';
import '../error/failures.dart';

/// Minimal JSON API client for the E Track Deno backend.
///
/// Kept in core so any feature can talk to the API without depending on a
/// specific HTTP implementation in its domain layer.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = _normalizeBaseUrl(baseUrl ?? AppConstants.apiBaseUrl);

  final http.Client _client;
  final String _baseUrl;

  /// Accepts either the host root or a URL that already ends in `/api`.
  static String _normalizeBaseUrl(String url) {
    final trimmed = url.replaceAll(RegExp(r'/+$'), '');
    return trimmed.endsWith('/api') ? trimmed : '$trimmed/api';
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? queryParameters,
    String? token,
  }) async {
    final uri = Uri.parse('$_baseUrl$path')
        .replace(queryParameters: queryParameters);

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
        throw const ServerFailure('Unexpected response format.');
      }

      if (response.statusCode == 401) {
        throw const AuthFailure('Session expired. Please sign in again.');
      }

      throw ServerFailure('Request failed (${response.statusCode}).');
    } on Failure {
      rethrow;
    } on http.ClientException {
      throw const NetworkFailure('Unable to reach the server.');
    } catch (_) {
      throw const UnknownFailure('Something went wrong while calling the API.');
    }
  }

  void close() => _client.close();
}
