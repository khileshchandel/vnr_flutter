/// One hit from the global search endpoint. `type` is `expense` or `task`.
class SearchResult {
  const SearchResult({
    required this.type,
    required this.id,
    required this.title,
    required this.detail,
    required this.date,
  });

  final String type;
  final String id;
  final String title;
  final String detail;
  final DateTime date;

  bool get isExpense => type == 'expense';
  bool get isTask => type == 'task';

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      type: json['type'] as String? ?? '',
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
    );
  }
}
