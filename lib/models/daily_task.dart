class DailyTask {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime date;

  DailyTask({
    required this.id,
    required this.title,
    required this.description,
    this.isCompleted = false,
    required this.date,
  });

  DailyTask copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? date,
  }) {
    return DailyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'date': date.toIso8601String(),
    };
  }

  factory DailyTask.fromJson(Map<String, dynamic> json) {
    return DailyTask(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      isCompleted: json['isCompleted'],
      date: DateTime.parse(json['date']),
    );
  }
}
