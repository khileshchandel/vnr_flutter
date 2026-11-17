import '../../domain/entities/search_result.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_remote_data_source.dart';

class SearchRepositoryImpl implements SearchRepository {
  const SearchRepositoryImpl(this._remote);

  final SearchRemoteDataSource _remote;

  @override
  Future<List<SearchResult>> search({required String query, int limit = 20}) =>
      _remote.search(query: query, limit: limit);
}
