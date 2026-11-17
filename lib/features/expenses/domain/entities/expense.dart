class Expense {
  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    this.isSynced = false,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String? note;
  final bool isSynced;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'category': category,
    'date': date.toIso8601String(),
    'note': note,
    'isSynced': isSynced,
    'updatedAt': updatedAt?.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  Expense copyWith({
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? note,
    bool? isSynced,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearNote = false,
    bool clearUpdatedAt = false,
    bool clearDeletedAt = false,
  }) {
    return Expense(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: clearNote ? null : (note ?? this.note),
      isSynced: isSynced ?? this.isSynced,
      updatedAt: clearUpdatedAt ? null : (updatedAt ?? this.updatedAt),
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    final updatedAt = json['updatedAt'] as String?;
    final deletedAt = json['deletedAt'] as String?;

    return Expense(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
      isSynced: json['isSynced'] as bool? ?? false,
      updatedAt: updatedAt == null ? null : DateTime.tryParse(updatedAt),
      deletedAt: deletedAt == null ? null : DateTime.tryParse(deletedAt),
    );
  }
}
