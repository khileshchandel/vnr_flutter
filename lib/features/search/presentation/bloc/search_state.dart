import '../../domain/entities/search_result.dart';

enum SearchStatus { initial, loading, ready, failure }

class SearchState {
  const SearchState({
    this.status = SearchStatus.initial,
    this.query = '',
    this.results = const [],
    this.errorMessage,
  });

  final SearchStatus status;
  final String query;
  final List<SearchResult> results;
  final String? errorMessage;

  bool get isInitial => status == SearchStatus.initial;
  bool get isLoading => status == SearchStatus.loading;
  bool get hasResults => status == SearchStatus.ready && results.isNotEmpty;
}
