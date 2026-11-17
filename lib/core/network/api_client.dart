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
    return _send(() => _client.get(uri, headers: _headers(token)));
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    return _send(
      () => _client.post(
        uri,
        headers: _headers(token, withBody: true),
        body: jsonEncode(body ?? const <String, dynamic>{}),
      ),
    );
  }

  Map<String, String> _headers(String? token, {bool withBody = false}) => {
    'Accept': 'application/json',
    if (withBody) 'Content-Type': 'application/json',
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    late final http.Response response;
    try {
      response = await request();
    } on http.ClientException {
      throw const NetworkFailure('Unable to reach the server.');
    } catch (_) {
      throw const UnknownFailure('Something went wrong while calling the API.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw const ServerFailure('Unexpected response format.');
    }

    throw _mapError(response);
  }

  Failure _mapError(http.Response response) {
    String? message;
    String? code;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          message = error['message'] as String?;
          code = error['code'] as String?;
        }
      }
    } catch (_) {
      // Non-JSON error body; fall back to a generic message.
    }

    switch (response.statusCode) {
      case 401:
        if (code == 'INVALID_CREDENTIALS') {
          return AuthFailure(message ?? 'Invalid email or password.');
        }
        return const AuthFailure('Session expired. Please sign in again.');
      case 409:
        return AuthFailure(message ?? 'That email is already in use.');
      case 400:
        return ValidationFailure(
          message ?? 'Check your details and try again.',
        );
      case >= 500:
        return const ServerFailure(
          'The server had a problem. Try again later.',
        );
      default:
        return ServerFailure(
          message ?? 'Request failed (${response.statusCode}).',
        );
    }
  }

  void close() => _client.close();
}
