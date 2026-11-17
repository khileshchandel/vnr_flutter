import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/sync/sync_status_badge.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/premium_widgets.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../expenses/presentation/widgets/add_expense_sheet.dart';
import '../../../tasks/domain/entities/task_item.dart';
import '../../../tasks/domain/repositories/task_repository.dart';
import '../../../tasks/presentation/widgets/add_task_sheet.dart';
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

const _tabular = [FontFeature.tabularFigures()];

/// Dashboard with the financial summary, visual breakdown and recent activity.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _refresh(BuildContext context) async {
    HapticFeedback.lightImpact();
    context.read<DashboardBloc>().add(const DashboardStarted());
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final summary = context.watch<DashboardBloc>().state.summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: const [SyncStatusBadge(), SizedBox(width: 8)],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(context),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (summary == null)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Reveal(
                      dy: 20,
                      duration: const Duration(milliseconds: 700),
                      child: _SummaryCard(summary: summary),
                    ),
                    const SizedBox(height: 12),
                    Reveal(
                      delay: const Duration(milliseconds: 80),
                      dy: 20,
                      duration: const Duration(milliseconds: 700),
                      child: _BreakdownCard(summary: summary),
                    ),
                    const SizedBox(height: 12),
                    Reveal(
                      delay: const Duration(milliseconds: 160),
                      dy: 20,
                      duration: const Duration(milliseconds: 700),
                      child: _RecentCard(summary: summary),
                    ),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Summary ───────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final DashboardSummary summary;

  Future<void> _editBudget(BuildContext context) async {
    HapticFeedback.selectionClick();
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
              if (!formKey.currentState!.validate()) {
                HapticFeedback.heavyImpact();
                return;
              }
              HapticFeedback.lightImpact();
              Navigator.of(dialogContext).pop(double.parse(controller.text));
            },
            style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
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
    final scheme = theme.colorScheme;
    final isOverBudget = summary.remaining < 0;
    final used = summary.usedPercent;

    final barColor = isOverBudget || used > 100
        ? scheme.error
        : used >= 85
        ? scheme.secondary
        : scheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Remaining budget',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Edit budget',
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: scheme.onSurfaceVariant,
                  onPressed: () => _editBudget(context),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _CountUpMoney(
                value: summary.remaining,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: isOverBudget ? scheme.error : scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: BudgetProgressBar(
                fraction: summary.usedFraction,
                color: barColor,
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _Stat(label: 'Spent', value: summary.totalSpent),
                  ),
                  Expanded(
                    child: _Stat(label: 'Budget', value: summary.budget),
                  ),
                  Text(
                    '${used.toStringAsFixed(0)}% used',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: barColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountUpMoney extends StatelessWidget {
  const _CountUpMoney({required this.value, this.style});

  final double value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: AppTheme.emphasized,
      builder: (context, v, _) => Text(
        _money.format(v),
        style: style?.copyWith(fontFeatures: _tabular),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final double value;

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
        const SizedBox(height: 2),
        Text(
          _money.format(value),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontFeatures: _tabular,
          ),
        ),
      ],
    );
  }
}

// ── Breakdown ─────────────────────────────────────────────────────────────

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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Spend by category', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            if (slices.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
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
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
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
              fontFeatures: _tabular,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent activity ───────────────────────────────────────────────────────

class _RecentCard extends StatefulWidget {
  const _RecentCard({required this.summary});

  final DashboardSummary summary;

  @override
  State<_RecentCard> createState() => _RecentCardState();
}

class _RecentCardState extends State<_RecentCard> {
  int _index = 0; // 0 = tasks, 1 = expenses

  void _add() {
    HapticFeedback.lightImpact();
    if (_index == 0) {
      showAddTaskSheet(context, repository: context.read<TaskRepository>());
    } else {
      showAddExpenseSheet(
        context,
        repository: context.read<ExpenseRepository>(),
      );
    }
  }

  void _seeAll() {
    HapticFeedback.selectionClick();
    context.go(_index == 0 ? AppRoutes.tasks : AppRoutes.expenses);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final summary = widget.summary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Recent activity', style: theme.textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  tooltip: _index == 0 ? 'Add task' : 'Add expense',
                  icon: const Icon(Icons.add_rounded),
                  onPressed: _add,
                ),
                TextButton(onPressed: _seeAll, child: const Text('See all')),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.transparent,
                    selectedBackgroundColor: scheme.primaryContainer,
                    selectedForegroundColor: scheme.onPrimaryContainer,
                    side: BorderSide(color: scheme.outlineVariant),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  segments: [
                    ButtonSegment(
                      value: 0,
                      label: Text('Tasks (${summary.recentTasks.length})'),
                    ),
                    ButtonSegment(
                      value: 1,
                      label: Text(
                        'Expenses (${summary.recentExpenses.length})',
                      ),
                    ),
                  ],
                  selected: {_index},
                  onSelectionChanged: (s) {
                    HapticFeedback.selectionClick();
                    setState(() => _index = s.first);
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 350),
                curve: AppTheme.emphasized,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: KeyedSubtree(
                    key: ValueKey(_index),
                    child: _index == 0
                        ? _TaskList(tasks: summary.recentTasks, onAdd: _add)
                        : _ExpenseList(
                            expenses: summary.recentExpenses,
                            onAdd: _add,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList({required this.tasks, required this.onAdd});

  final List<TaskItem> tasks;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return _EmptyState(
        icon: Icons.checklist_rounded,
        label: 'No tasks yet',
        actionLabel: 'Add task',
        onAdd: onAdd,
      );
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        for (var i = 0; i < tasks.length; i++) ...[
          if (i > 0) const Divider(),
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            onTap: () => context.read<TaskRepository>().cacheTask(
              tasks[i].copyWith(isCompleted: !tasks[i].isCompleted),
            ),
            leading: Icon(
              tasks[i].isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: tasks[i].isCompleted
                  ? scheme.primary
                  : scheme.onSurfaceVariant,
            ),
            title: Text(
              tasks[i].title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: tasks[i].isCompleted ? scheme.onSurfaceVariant : null,
                decoration: tasks[i].isCompleted
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            subtitle: Text(
              '${tasks[i].category.wireValue} · '
              '${tasks[i].dueDate == null ? 'No due date' : 'Due ${_date.format(tasks[i].dueDate!)}'}',
            ),
          ),
        ],
      ],
    );
  }
}

class _ExpenseList extends StatelessWidget {
  const _ExpenseList({required this.expenses, required this.onAdd});

  final List<Expense> expenses;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return _EmptyState(
        icon: Icons.receipt_long_rounded,
        label: 'No expenses yet',
        actionLabel: 'Add expense',
        onAdd: onAdd,
      );
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        for (var i = 0; i < expenses.length; i++) ...[
          if (i > 0) const Divider(),
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                expenses[i].category.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
            title: Text(
              expenses[i].title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              '${expenses[i].category} · ${_date.format(expenses[i].date)}',
            ),
            trailing: Text(
              _money.format(expenses[i].amount),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: _tabular,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.label,
    required this.actionLabel,
    required this.onAdd,
  });

  final IconData icon;
  final String label;
  final String actionLabel;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: muted),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
            const SizedBox(height: 4),
            TextButton(onPressed: onAdd, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
