import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/repositories/search_repository.dart';
import 'search_event.dart';
import 'search_state.dart';

/// Searches expenses and tasks through the API-backed repository.
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc({required this._repository}) : super(const SearchState()) {
    on<SearchSubmitted>(_onSubmitted);
    on<SearchCleared>(_onCleared);
  }

  final SearchRepository _repository;

  Future<void> _onSubmitted(
    SearchSubmitted event,
    Emitter<SearchState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(const SearchState());
      return;
    }

    emit(SearchState(status: SearchStatus.loading, query: query));
    try {
      final results = await _repository.search(query: query, limit: 20);
      emit(
        SearchState(status: SearchStatus.ready, query: query, results: results),
      );
    } on Failure catch (failure) {
      emit(
        SearchState(
          status: SearchStatus.failure,
          query: query,
          errorMessage: failure.message,
        ),
      );
    } catch (_) {
      emit(
        SearchState(
          status: SearchStatus.failure,
          query: query,
          errorMessage: 'Search failed. Please try again.',
        ),
      );
    }
  }

  void _onCleared(SearchCleared event, Emitter<SearchState> emit) {
    emit(const SearchState());
  }
}
