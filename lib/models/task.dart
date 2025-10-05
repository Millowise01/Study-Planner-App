import 'package:intl/intl.dart';

class Task {
  final int? id;
  final String title;
  final String? description;
  final DateTime dueDate;
  final DateTime? reminderTime;
  final bool isCompleted;

  Task({
    this.id,
    required this.title,
    this.description,
    required this.dueDate,
    this.reminderTime,
    this.isCompleted = false,
  });

  // Convert Task to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'reminderTime': reminderTime?.millisecondsSinceEpoch,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  // Create Task from Map (from database)
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate']),
      reminderTime: map['reminderTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['reminderTime'])
          : null,
      isCompleted: map['isCompleted'] == 1,
    );
  }

  // Create a copy of the task with updated fields
  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dueDate,
    DateTime? reminderTime,
    bool? isCompleted,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      reminderTime: reminderTime ?? this.reminderTime,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  // Check if task is due today
  bool get isDueToday {
    final now = DateTime.now();
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }

  // Check if task is overdue
  bool get isOverdue {
    return dueDate.isBefore(DateTime.now()) && !isCompleted;
  }

  // Get formatted due date string
  String get formattedDueDate {
    final formatter = DateFormat('MMM dd, yyyy');
    return formatter.format(dueDate);
  }

  // Get formatted reminder time string
  String? get formattedReminderTime {
    if (reminderTime == null) return null;
    final formatter = DateFormat('HH:mm');
    return formatter.format(reminderTime!);
  }

  @override
  String toString() {
    return 'Task{id: $id, title: $title, dueDate: $dueDate, isCompleted: $isCompleted}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
