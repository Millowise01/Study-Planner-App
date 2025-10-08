// Web-specific storage service using SharedPreferences for browser localStorage
// Provides SQLite-like interface for web platform using JSON serialization
// Handles task persistence in browser's localStorage with automatic ID generation

import 'dart:convert';                           // JSON encoding/decoding
import 'package:shared_preferences/shared_preferences.dart'; // Browser localStorage access
import '../models/task.dart';                    // Task data model

/// Web storage service implementing task persistence using SharedPreferences
/// Mimics database operations using browser's localStorage
/// Provides same interface as SQLite implementation for platform abstraction
class WebStorageService {
  // Storage key for tasks in SharedPreferences
  static const String _tasksKey = 'tasks_storage';
  
  // Auto-incrementing ID counter for new tasks (simulates database auto-increment)
  static int _nextId = 1;

  /// Getter for SharedPreferences instance
  /// Provides access to browser's localStorage
  static Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  static Future<void> _initializeNextId() async {
    final tasks = await getAllTasks();
    if (tasks.isNotEmpty) {
      _nextId = tasks.map((t) => t.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
    }
  }

  static Future<List<Task>> getAllTasks() async {
    final prefs = await _prefs;
    final tasksJson = prefs.getStringList(_tasksKey) ?? [];
    return tasksJson.map((json) => Task.fromMap(jsonDecode(json))).toList();
  }

  static Future<int> insertTask(Task task) async {
    await _initializeNextId();
    final taskWithId = task.copyWith(id: _nextId++);
    final tasks = await getAllTasks();
    tasks.add(taskWithId);
    await _saveTasks(tasks);
    return taskWithId.id!;
  }

  static Future<void> updateTask(Task task) async {
    final tasks = await getAllTasks();
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      tasks[index] = task;
      await _saveTasks(tasks);
    }
  }

  static Future<void> deleteTask(int id) async {
    final tasks = await getAllTasks();
    tasks.removeWhere((t) => t.id == id);
    await _saveTasks(tasks);
  }

  static Future<List<Task>> getTasksForDate(DateTime date) async {
    final tasks = await getAllTasks();
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    return tasks.where((task) {
      return task.dueDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
             task.dueDate.isBefore(endOfDay.add(const Duration(seconds: 1)));
    }).toList()..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  static Future<List<Task>> getTodayTasks() async {
    return await getTasksForDate(DateTime.now());
  }

  static Future<List<Task>> getTodayReminders() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    final tasks = await getAllTasks();
    return tasks.where((task) {
      return task.reminderTime != null &&
             task.reminderTime!.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
             task.reminderTime!.isBefore(endOfDay.add(const Duration(seconds: 1))) &&
             !task.isCompleted;
    }).toList()..sort((a, b) => a.reminderTime!.compareTo(b.reminderTime!));
  }

  static Future<List<DateTime>> getDatesWithTasks(DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);
    
    final tasks = await getAllTasks();
    final dates = <DateTime>{};
    
    for (final task in tasks) {
      final taskDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      if (taskDate.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
          taskDate.isBefore(endOfMonth.add(const Duration(days: 1)))) {
        dates.add(taskDate);
      }
    }
    
    return dates.toList()..sort();
  }

  static Future<void> _saveTasks(List<Task> tasks) async {
    final prefs = await _prefs;
    final tasksJson = tasks.map((task) => jsonEncode(task.toMap())).toList();
    await prefs.setStringList(_tasksKey, tasksJson);
  }
}