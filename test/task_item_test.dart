import 'package:flutter_test/flutter_test.dart';

import 'package:e_track/features/tasks/domain/entities/task_item.dart';

void main() {
  test('TaskItem JSON round trip preserves due date and completion', () {
    final task = TaskItem(
      id: 'task-1',
      title: 'Pay electricity bill',
      category: TaskCategory.work,
      note: 'Before the 20th',
      dueDate: DateTime.utc(2026, 11, 20),
      isCompleted: true,
    );

    final restored = TaskItem.fromJson(task.toJson());

    expect(restored.id, task.id);
    expect(restored.title, task.title);
    expect(restored.category, TaskCategory.work);
    expect(restored.toJson()['category'], 'Work');
    expect(restored.note, task.note);
    expect(restored.dueDate, task.dueDate);
    expect(restored.isCompleted, isTrue);
  });
}
