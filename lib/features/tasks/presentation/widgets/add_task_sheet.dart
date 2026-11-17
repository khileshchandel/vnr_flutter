import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/task_item.dart';
import '../../domain/repositories/task_repository.dart';

final _dateFormat = DateFormat.yMMMd();

Future<void> showTaskSheet(
  BuildContext context, {
  required TaskRepository repository,
  TaskItem? task,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => AddTaskSheet(repository: repository, task: task),
  );
}

Future<void> showAddTaskSheet(
  BuildContext context, {
  required TaskRepository repository,
}) => showTaskSheet(context, repository: repository);

Future<void> showEditTaskSheet(
  BuildContext context, {
  required TaskRepository repository,
  required TaskItem task,
}) => showTaskSheet(context, repository: repository, task: task);

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key, required this.repository, this.task});

  final TaskRepository repository;
  final TaskItem? task;

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late TaskCategory _category;
  late DateTime? _dueDate;
  bool _saving = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _noteController = TextEditingController(text: task?.note ?? '');
    _category = task?.category ?? TaskCategory.personal;
    _dueDate = task?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(2000),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (picked != null && mounted) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final note = _noteController.text.trim();
    final task = TaskItem(
      id: widget.task?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      category: _category,
      note: note.isEmpty ? null : note,
      dueDate: _dueDate,
      isCompleted: widget.task?.isCompleted ?? false,
      isSynced: widget.task?.isSynced ?? false,
      updatedAt: widget.task?.updatedAt,
    );

    await widget.repository.cacheTask(task);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? 'Edit task' : 'Add task',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a title.'
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TaskCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final category in TaskCategory.values)
                  DropdownMenuItem(
                    value: category,
                    child: Text(category.wireValue),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDueDate,
                    icon: const Icon(Icons.event_outlined),
                    label: Text(
                      _dueDate == null
                          ? 'Add due date'
                          : 'Due ${_dateFormat.format(_dueDate!)}',
                    ),
                  ),
                ),
                if (_dueDate != null)
                  IconButton(
                    tooltip: 'Clear due date',
                    icon: const Icon(Icons.close_outlined),
                    onPressed: () => setState(() => _dueDate = null),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Save changes' : 'Save task'),
            ),
          ],
        ),
      ),
    );
  }
}
