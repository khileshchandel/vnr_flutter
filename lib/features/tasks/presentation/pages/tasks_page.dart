import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/task_item.dart';
import '../../domain/repositories/task_repository.dart';
import '../widgets/add_task_sheet.dart';

final _dateFormat = DateFormat.yMMMd();

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  late final TaskRepository _repository;
  late final StreamSubscription<void> _subscription;
  late List<TaskItem> _tasks;

  @override
  void initState() {
    super.initState();
    _repository = context.read<TaskRepository>();
    _tasks = _repository.getTasks();
    _subscription = _repository.changes.listen((_) {
      if (!mounted) return;
      setState(() => _tasks = _repository.getTasks());
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _tasks = _repository.getTasks());
        },
        child: _tasks.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Icon(
                    Icons.checklist_outlined,
                    size: 56,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tasks yet',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first task.',
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
                itemCount: _tasks.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  final due = task.dueDate == null
                      ? 'No due date'
                      : 'Due ${_dateFormat.format(task.dueDate!)}';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      task.isCompleted
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: task.isCompleted
                          ? theme.colorScheme.primary
                          : null,
                    ),
                    title: Text(
                      task.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Text('${task.category.wireValue} · $due'),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddTaskSheet(context, repository: _repository),
        tooltip: 'Add task',
        child: const Icon(Icons.add),
      ),
    );
  }
}
