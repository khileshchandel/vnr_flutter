/// Supported categories for a task.
enum TaskCategory { personal, work, travel, food, other }

extension TaskCategoryX on TaskCategory {
  /// Wire value shared with the Deno API (capitalized labels).
  String get wireValue => switch (this) {
    TaskCategory.personal => 'Personal',
    TaskCategory.work => 'Work',
    TaskCategory.travel => 'Travel',
    TaskCategory.food => 'Food',
    TaskCategory.other => 'Other',
  };
}

/// Parses both `Work` and `work`; unknown values fall back to `other`.
TaskCategory taskCategoryFromString(String value) {
  return switch (value.toLowerCase()) {
    'personal' => TaskCategory.personal,
    'work' => TaskCategory.work,
    'travel' => TaskCategory.travel,
    'food' => TaskCategory.food,
    _ => TaskCategory.other,
  };
}

/// Domain entity for a task. No Flutter/Hive imports by design.
class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    this.category = TaskCategory.personal,
    this.note,
    this.dueDate,
    this.isCompleted = false,
    this.isSynced = false,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String title;
  final TaskCategory category;
  final String? note;
  final DateTime? dueDate;
  final bool isCompleted;
  final bool isSynced;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category.wireValue,
    'note': note,
    'dueDate': dueDate?.toIso8601String(),
    'isCompleted': isCompleted,
    'isSynced': isSynced,
    'updatedAt': updatedAt?.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  TaskItem copyWith({
    String? title,
    TaskCategory? category,
    String? note,
    DateTime? dueDate,
    bool? isCompleted,
    bool? isSynced,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearNote = false,
    bool clearDueDate = false,
    bool clearUpdatedAt = false,
    bool clearDeletedAt = false,
  }) {
    return TaskItem(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      note: clearNote ? null : (note ?? this.note),
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      isCompleted: isCompleted ?? this.isCompleted,
      isSynced: isSynced ?? this.isSynced,
      updatedAt: clearUpdatedAt ? null : (updatedAt ?? this.updatedAt),
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    final dueDate = json['dueDate'] as String?;
    final updatedAt = json['updatedAt'] as String?;
    final deletedAt = json['deletedAt'] as String?;

    return TaskItem(
      id: json['id'] as String,
      title: json['title'] as String,
      category: taskCategoryFromString(
        json['category'] as String? ?? 'Personal',
      ),
      note: json['note'] as String?,
      dueDate: dueDate == null ? null : DateTime.tryParse(dueDate),
      isCompleted: json['isCompleted'] as bool? ?? false,
      isSynced: json['isSynced'] as bool? ?? false,
      updatedAt: updatedAt == null ? null : DateTime.tryParse(updatedAt),
      deletedAt: deletedAt == null ? null : DateTime.tryParse(deletedAt),
    );
  }
}
