import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/sync/sync_coordinator.dart';
import '../../../../core/sync/sync_feedback.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../widgets/add_expense_sheet.dart';

final _dateFormat = DateFormat.yMMMd();
final _moneyFormat = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  late final ExpenseRepository _repository;
  late final StreamSubscription<void> _subscription;
  late List<Expense> _expenses;

  @override
  void initState() {
    super.initState();
    _repository = context.read<ExpenseRepository>();
    _expenses = _repository.getExpenses();
    _subscription = _repository.changes.listen((_) {
      if (!mounted) return;
      setState(() => _expenses = _repository.getExpenses());
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> _sync() async {
    final result = await context.read<SyncService>().run();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(syncMessage(result))));
  }

  Future<void> _delete(Expense expense) async {
    await _repository.deleteExpense(expense.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('${expense.title} deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => unawaited(_repository.cacheExpense(expense)),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            tooltip: 'Sync now',
            icon: const Icon(Icons.sync_outlined),
            onPressed: _sync,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _sync();
          if (mounted) setState(() => _expenses = _repository.getExpenses());
        },
        child: _expenses.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 56,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No expenses yet',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first expense.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: _expenses.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final expense = _expenses[index];
                  return Dismissible(
                    key: ValueKey(expense.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: theme.colorScheme.errorContainer,
                      child: Icon(
                        Icons.delete_outline,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                    onDismissed: (_) => _delete(expense),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        child: Text(
                          expense.category.substring(0, 1).toUpperCase(),
                        ),
                      ),
                      title: Text(expense.title),
                      subtitle: Text(
                        '${expense.category} · ${_dateFormat.format(expense.date)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _moneyFormat.format(expense.amount),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Edit expense',
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => showEditExpenseSheet(
                              context,
                              repository: _repository,
                              expense: expense,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddExpenseSheet(context, repository: _repository),
        tooltip: 'Add expense',
        child: const Icon(Icons.add),
      ),
    );
  }
}
