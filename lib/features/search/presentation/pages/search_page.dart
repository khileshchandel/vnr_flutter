import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/premium_widgets.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';

final _date = DateFormat.yMMMd();

/// How long the user must pause typing before a search is fired.
const _debounce = Duration(milliseconds: 400);

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  Timer? _timer;

  /// Last query actually sent to the bloc, so we never fire the same one twice.
  String _lastQuery = '';

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _dispatch(String query) {
    if (!mounted || query == _lastQuery) return;
    _lastQuery = query;
    context.read<SearchBloc>().add(SearchSubmitted(query));
  }

  /// Runs on every keystroke; restarts the 400ms countdown each time.
  void _onChanged(String value) {
    _timer?.cancel();
    final query = value.trim();

    if (query.isEmpty) {
      if (_lastQuery.isNotEmpty) {
        _lastQuery = '';
        context.read<SearchBloc>().add(const SearchCleared());
      }
      return;
    }

    _timer = Timer(_debounce, () => _dispatch(query));
  }

  /// Keyboard "search" key: skip the wait and search right away.
  void _submit(String value) {
    _timer?.cancel();
    FocusScope.of(context).unfocus();
    final query = value.trim();
    if (query.isEmpty) return;
    HapticFeedback.selectionClick();
    _dispatch(query);
  }

  void _clear() {
    HapticFeedback.selectionClick();
    _timer?.cancel();
    _controller.clear();
    if (_lastQuery.isNotEmpty) {
      _lastQuery = '';
      context.read<SearchBloc>().add(const SearchCleared());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SearchBloc>().state;

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              autocorrect: false,
              onChanged: _onChanged,
              onSubmitted: _submit,
              decoration: InputDecoration(
                hintText: 'Search expenses and tasks',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (context, value, _) => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: value.text.isEmpty
                        ? const SizedBox.shrink(key: ValueKey('empty'))
                        : IconButton(
                            key: const ValueKey('clear'),
                            tooltip: 'Clear',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: _clear,
                          ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 2,
            child: state.isLoading
                ? const LinearProgressIndicator(minHeight: 2)
                : null,
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _SearchBody(state: state),
            ),
          ),
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
    if (state.isInitial) {
      return const _Message(
        key: ValueKey('initial'),
        icon: Icons.search_rounded,
        title: 'Find anything, fast',
        message: 'Search across your expenses and tasks in one place.',
      );
    }

    // While a new search is in flight, keep showing what we have instead of
    // flashing a spinner or an empty state between keystrokes.
    if (state.isLoading) {
      return state.results.isEmpty
          ? const SizedBox.expand(key: ValueKey('loading'))
          : _ResultList(key: const ValueKey('list'), state: state);
    }

    if (state.status == SearchStatus.failure) {
      return _Message(
        key: const ValueKey('failure'),
        icon: Icons.error_outline_rounded,
        title: 'Could not search',
        message: state.errorMessage ?? 'Please try again.',
      );
    }

    if (state.results.isEmpty) {
      return _Message(
        key: const ValueKey('empty'),
        icon: Icons.search_off_rounded,
        title: 'No matches',
        message: 'Nothing found for "${state.query}". Try another search.',
      );
    }

    return _ResultList(key: const ValueKey('list'), state: state);
  }
}

class _ResultList extends StatelessWidget {
  const _ResultList({super.key, required this.state});

  final SearchState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: state.results.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, index) {
        final result = state.results[index];
        final detail = result.detail.trim().isEmpty
            ? _date.format(result.date)
            : '${result.detail} · ${_date.format(result.date)}';

        // Only the first few rows animate, and rows keep their state while
        // the list updates between keystrokes, so typing never flickers.
        return Reveal(
          delay: Duration(milliseconds: 30 * (index < 8 ? index : 8)),
          duration: const Duration(milliseconds: 450),
          dy: 10,
          fromScale: 1,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                result.isExpense
                    ? Icons.receipt_long_rounded
                    : result.isTask
                    ? Icons.checklist_rounded
                    : Icons.search_rounded,
                size: 20,
                color: scheme.onPrimaryContainer,
              ),
            ),
            title: _Highlighted(
              text: result.title,
              query: state.query,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              highlightColor: scheme.primary,
            ),
            subtitle: Text(detail),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                result.type.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Bolds and tints the first case-insensitive match of [query] inside [text].
class _Highlighted extends StatelessWidget {
  const _Highlighted({
    required this.text,
    required this.query,
    required this.style,
    required this.highlightColor,
  });

  final String text;
  final String query;
  final TextStyle? style;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final lower = text.toLowerCase();
    final start = (q.isEmpty || lower.length != text.length)
        ? -1
        : lower.indexOf(q);

    if (start < 0) return Text(text, style: style);

    final end = start + q.length;
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: text.substring(0, start)),
          TextSpan(
            text: text.substring(start, end),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: highlightColor,
            ),
          ),
          TextSpan(text: text.substring(end)),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    super.key,
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
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge - 6),
              ),
              child: Icon(icon, size: 30, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 20),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
