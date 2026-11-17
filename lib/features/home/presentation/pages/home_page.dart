import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../tasks/domain/entities/task_item.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../widgets/budget_progress_bar.dart';
import '../widgets/category_donut_chart.dart';

final _money = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);
final _date = DateFormat.yMMMd();

/// Dashboard with the financial summary, visual breakdown and recent activity.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final summary = context.watch<DashboardBloc>().state.summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () =>
                context.read<DashboardBloc>().add(const DashboardStarted()),
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_outlined),
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthSignOutRequested()),
          ),
        ],
      ),
      body: summary == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _SummaryCard(summary: summary),
                const SizedBox(height: 12),
                _BreakdownCard(summary: summary),
                const SizedBox(height: 12),
                const _RecentCard(),
              ],
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final DashboardSummary summary;

  Future<void> _editBudget(BuildContext context) async {
    final controller = TextEditingController(
      text: summary.budget.toStringAsFixed(0),
    );
    final formKey = GlobalKey<FormState>();

    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit total budget'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Total budget',
              prefixText: '₹ ',
            ),
            validator: (value) {
              final parsed = double.tryParse(value ?? '');
              if (parsed == null || parsed <= 0) {
                return 'Enter an amount greater than zero.';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(dialogContext).pop(double.parse(controller.text));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (amount != null && context.mounted) {
      context.read<DashboardBloc>().add(BudgetUpdated(amount));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverBudget = summary.remaining < 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Financial summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Edit budget',
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _editBudget(context),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: _MoneyTile(
                    label: 'Total budget',
                    value: summary.budget,
                  ),
                ),
                Expanded(
                  child: _MoneyTile(
                    label: 'Total spend',
                    value: summary.totalSpent,
                  ),
                ),
                Expanded(
                  child: _MoneyTile(
                    label: 'Remaining',
                    value: summary.remaining,
                    valueColor: isOverBudget ? theme.colorScheme.error : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MoneyTile extends StatelessWidget {
  const _MoneyTile({required this.label, required this.value, this.valueColor});

  final String label;
  final double value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _money.format(value),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slices = <CategorySlice>[
      for (var i = 0; i < summary.categorySpend.length; i++)
        CategorySlice(
          category: summary.categorySpend[i].category,
          share: summary.categorySpend[i].share,
          color: AppTheme.chartPalette[i % AppTheme.chartPalette.length],
        ),
    ];
    final overBudget = summary.usedPercent > 100;
    final barColor = overBudget
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Spend overview',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${summary.usedPercent.toStringAsFixed(0)}% of budget',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: overBudget ? theme.colorScheme.error : null,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            BudgetProgressBar(fraction: summary.usedFraction, color: barColor),
            const SizedBox(height: 8),
            Text(
              '${_money.format(summary.totalSpent)} spent of ${_money.format(summary.budget)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: 24),
            if (slices.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Add an expense to see the category breakdown.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CategoryDonutChart(
                    slices: slices,
                    centerLabel: '${slices.length}\ncategories',
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: [
                        for (var i = 0; i < slices.length; i++)
                          _LegendRow(
                            color: slices[i].color,
                            label: slices[i].category,
                            amount: summary.categorySpend[i].amount,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.amount,
  });

  final Color color;
  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            _money.format(amount),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: _RecentTabs(),
      ),
    );
  }
}

class _RecentTabs extends StatelessWidget {
  const _RecentTabs();

  @override
  Widget build(BuildContext context) {
    final summary = context.watch<DashboardBloc>().state.summary!;

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Tasks (${summary.recentTasks.length})'),
              Tab(text: 'Expenses (${summary.recentExpenses.length})'),
            ],
          ),
          SizedBox(
            height: 320,
            child: TabBarView(
              children: [
                _TaskList(tasks: summary.recentTasks),
                _ExpenseList(expenses: summary.recentExpenses),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList({required this.tasks});

  final List<TaskItem> tasks;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const _EmptyState(
        icon: Icons.checklist_outlined,
        label: 'No tasks yet',
      );
    }

    final theme = Theme.of(context);
    return ListView.separated(
      shrinkWrap: true,
      itemCount: tasks.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final task = tasks[index];
        final due = task.dueDate == null
            ? 'No due date'
            : 'Due ${_date.format(task.dueDate!)}';
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            task.isCompleted
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: task.isCompleted ? theme.colorScheme.primary : null,
          ),
          title: Text(
            task.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text('${task.category.wireValue} · $due'),
        );
      },
    );
  }
}

class _ExpenseList extends StatelessWidget {
  const _ExpenseList({required this.expenses});

  final List<Expense> expenses;

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const _EmptyState(
        icon: Icons.receipt_long_outlined,
        label: 'No expenses yet',
      );
    }

    final theme = Theme.of(context);
    return ListView.separated(
      shrinkWrap: true,
      itemCount: expenses.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 18,
            child: Text(expense.category.substring(0, 1).toUpperCase()),
          ),
          title: Text(expense.title),
          subtitle: Text('${expense.category} · ${_date.format(expense.date)}'),
          trailing: Text(
            _money.format(expense.amount),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
