import 'package:e_track/core/error/failures.dart';
import 'package:e_track/core/network/api_client.dart';
import 'package:e_track/core/network/token_provider.dart';

import '../../domain/entities/search_result.dart';

abstract interface class SearchRemoteDataSource {
  Future<List<SearchResult>> search({required String query, int limit});
}

class SearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  const SearchRemoteDataSourceImpl({
    required this._apiClient,
    required this._tokenProvider,
  });

  final ApiClient _apiClient;
  final TokenProvider _tokenProvider;

  @override
  Future<List<SearchResult>> search({
    required String query,
    int limit = 20,
  }) async {
    final response = await _apiClient.getJson(
      '/search',
      queryParameters: {'q': query, 'limit': '$limit'},
      token: await _tokenProvider.readAccessToken(),
    );

    final results = response['results'];
    if (results is! List<dynamic>) {
      throw const ServerFailure('Unexpected search response.');
    }

    return results
        .whereType<Map<String, dynamic>>()
        .map(SearchResult.fromJson)
        .toList();
  }
}
