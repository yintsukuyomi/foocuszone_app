class Task {
  String id;
  String title;
  String description;
  bool isCompleted;
  DateTime createdAt;
  String category;
  int pomodoroCount;
  int estimatedPomodoros;
  DateTime? dueDate;
  int priority; // 1 = düşük, 2 = orta, 3 = yüksek

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    required this.createdAt,
    this.category = 'Diğer',
    this.pomodoroCount = 0,
    this.estimatedPomodoros = 1,
    this.dueDate,
    this.priority = 2, // Orta öncelik varsayılan
  });

  void incrementPomodoro() {
    pomodoroCount++;
  }

  double get completionPercentage {
    if (estimatedPomodoros <= 0) return 0;
    return (pomodoroCount / estimatedPomodoros).clamp(0.0, 1.0);
  }

  // Method to convert a Task object to a Map object for JSON encoding
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
        'category': category,
        'pomodoroCount': pomodoroCount,
        'estimatedPomodoros': estimatedPomodoros,
        'dueDate': dueDate?.toIso8601String(),
        'priority': priority,
      };

  // Factory constructor to create a Task object from a Map object (JSON decoding)
  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        title: json['title'],
        description: json['description'] ?? '',
        isCompleted: json['isCompleted'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
        category: json['category'] ?? 'Diğer',
        pomodoroCount: json['pomodoroCount'] ?? 0,
        estimatedPomodoros: json['estimatedPomodoros'] ?? 1,
        dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
        priority: json['priority'] ?? 2,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
