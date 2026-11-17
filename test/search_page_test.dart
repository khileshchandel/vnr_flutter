import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_track/features/search/domain/entities/search_result.dart';
import 'package:e_track/features/search/domain/repositories/search_repository.dart';
import 'package:e_track/features/search/presentation/bloc/search_bloc.dart';
import 'package:e_track/features/search/presentation/pages/search_page.dart';

class _FakeSearchRepository implements SearchRepository {
  const _FakeSearchRepository(this.results);

  final List<SearchResult> results;

  @override
  Future<List<SearchResult>> search({
    required String query,
    int limit = 20,
  }) async => results;
}

void main() {
  testWidgets('search page runs a query and lists results', (tester) async {
    final bloc = SearchBloc(
      repository: _FakeSearchRepository([
        SearchResult(
          type: 'expense',
          id: 'e1',
          title: 'Coffee',
          detail: 'Food · ₹250',
          date: DateTime.utc(2026, 11, 17),
        ),
      ]),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<SearchBloc>.value(
          value: bloc,
          child: const SearchPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Find anything, fast'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'coffee');
    // Search is now debounced on input rather than tapped.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('EXPENSE'), findsOneWidget);

    bloc.close();
  });
}
