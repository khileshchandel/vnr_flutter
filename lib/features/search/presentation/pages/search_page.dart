import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';

final _date = DateFormat.yMMMd();

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String value) {
    FocusScope.of(context).unfocus();
    context.read<SearchBloc>().add(SearchSubmitted(value));
  }

  void _clear() {
    _controller.clear();
    context.read<SearchBloc>().add(const SearchCleared());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SearchBloc>().state;

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: _submit,
              decoration: InputDecoration(
                hintText: 'Search expenses and tasks',
                prefixIcon: const Icon(Icons.search_outlined),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.close_outlined),
                      onPressed: _clear,
                    ),
                    IconButton(
                      tooltip: 'Search',
                      icon: const Icon(Icons.arrow_forward_outlined),
                      onPressed: () => _submit(_controller.text),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: _SearchBody(state: state)),
        ],
      ),
    );
  }
}

class _SearchBody extends StatelessWidget {
  const _SearchBody({required this.state});

  final SearchState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (state.isInitial) {
      return _Message(
        icon: Icons.search_outlined,
        title: 'Find anything, fast',
        message: 'Search across your expenses and tasks in one place.',
      );
    }

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == SearchStatus.failure) {
      return _Message(
        icon: Icons.error_outline,
        title: 'Could not search',
        message: state.errorMessage ?? 'Please try again.',
      );
    }

    if (state.results.isEmpty) {
      return _Message(
        icon: Icons.search_off_outlined,
        title: 'No matches',
        message: 'Nothing found for "${state.query}". Try another search.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: state.results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final result = state.results[index];
        final detail = result.detail.trim().isEmpty
            ? _date.format(result.date)
            : '${result.detail} · ${_date.format(result.date)}';

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            child: Icon(
              result.isExpense
                  ? Icons.receipt_long_outlined
                  : result.isTask
                  ? Icons.checklist_outlined
                  : Icons.search_outlined,
              size: 20,
            ),
          ),
          title: Text(result.title),
          subtitle: Text(detail),
          trailing: Text(
            result.type.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
