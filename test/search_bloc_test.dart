import 'package:flutter_test/flutter_test.dart';

import 'package:e_track/core/error/failures.dart';
import 'package:e_track/features/search/domain/entities/search_result.dart';
import 'package:e_track/features/search/domain/repositories/search_repository.dart';
import 'package:e_track/features/search/presentation/bloc/search_bloc.dart';
import 'package:e_track/features/search/presentation/bloc/search_event.dart';
import 'package:e_track/features/search/presentation/bloc/search_state.dart';

class _FakeSearchRepository implements SearchRepository {
  _FakeSearchRepository({this.results = const [], this.failure});

  final List<SearchResult> results;
  final Failure? failure;
  String? lastQuery;

  @override
  Future<List<SearchResult>> search({
    required String query,
    int limit = 20,
  }) async {
    lastQuery = query;
    final error = failure;
    if (error != null) throw error;
    return results;
  }
}

SearchResult _result(String title) => SearchResult(
  type: 'expense',
  id: title,
  title: title,
  detail: 'Food',
  date: DateTime.utc(2026, 11, 17),
);

void main() {
  test('submitted query returns results from the repository', () async {
    final repository = _FakeSearchRepository(results: [_result('Coffee')]);
    final bloc = SearchBloc(repository: repository);
    final ready = bloc.stream.firstWhere((s) => s.status == SearchStatus.ready);

    bloc.add(const SearchSubmitted('coffee'));
    final state = await ready;

    expect(repository.lastQuery, 'coffee');
    expect(state.results, hasLength(1));
    expect(state.results.first.title, 'Coffee');

    bloc.close();
  });

  test('empty query resets the search state', () async {
    final bloc = SearchBloc(repository: _FakeSearchRepository());
    bloc.add(const SearchSubmitted('coffee'));
    await bloc.stream.firstWhere((s) => s.status == SearchStatus.ready);

    final cleared = bloc.stream.firstWhere(
      (s) => s.status == SearchStatus.initial,
    );
    bloc.add(const SearchCleared());
    final state = await cleared;

    expect(state.query, isEmpty);
    expect(state.results, isEmpty);

    bloc.close();
  });

  test('repository failures are shown to the user', () async {
    final bloc = SearchBloc(
      repository: _FakeSearchRepository(
        failure: const NetworkFailure('No internet connection.'),
      ),
    );
    final failed = bloc.stream.firstWhere(
      (s) => s.status == SearchStatus.failure,
    );

    bloc.add(const SearchSubmitted('coffee'));
    final state = await failed;

    expect(state.errorMessage, 'No internet connection.');

    bloc.close();
  });
}
