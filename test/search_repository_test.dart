import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:e_track/core/network/api_client.dart';
import 'package:e_track/core/network/token_provider.dart';
import 'package:e_track/features/search/data/datasources/search_remote_data_source.dart';

class _FakeTokenProvider implements TokenProvider {
  const _FakeTokenProvider();

  @override
  Future<String?> readAccessToken() async => 'test-token';
}

void main() {
  test(
    'global search calls /api/search with bearer token and parses results',
    () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/search');
        expect(request.url.queryParameters['q'], 'coffee');
        expect(request.url.queryParameters['limit'], '10');
        expect(request.headers['Authorization'], 'Bearer test-token');

        return http.Response(
          jsonEncode({
            'query': 'coffee',
            'total': 1,
            'results': [
              {
                'type': 'expense',
                'id': 'e1',
                'title': 'Coffee',
                'detail': 'Food',
                'date': '2026-11-17T00:00:00.000Z',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final dataSource = SearchRemoteDataSourceImpl(
        apiClient: ApiClient(
          client: mockClient,
          baseUrl: 'http://localhost:8000',
        ),
        tokenProvider: const _FakeTokenProvider(),
      );

      final results = await dataSource.search(query: 'coffee', limit: 10);

      expect(results, hasLength(1));
      expect(results.first.isExpense, isTrue);
      expect(results.first.id, 'e1');
      expect(results.first.title, 'Coffee');

      mockClient.close();
    },
  );
}
