import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';
import 'package:flutter/foundation.dart';
import 'web_storage_service.dart';

// Conditional imports for platform-specific code
import 'database_service_stub.dart'
    if (dart.library.io) 'database_service_io.dart'
    if (dart.library.html) 'database_service_web.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (kIsWeb) {
      // For web, we don't use SQLite, return a dummy database
      throw UnsupportedError('SQLite not used on web platform');
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite not used on web platform');
    }
    try {
      print('DatabaseService: Initializing database...');
      // Initialize database factory based on platform
      await initializeDatabaseFactory();
      print('DatabaseService: Database factory initialized');
      
      String path = join(await getDatabasesPath(), 'study_planner.db');
      print('DatabaseService: Database path: $path');
      
      final db = await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
      print('DatabaseService: Database opened successfully');
      return db;
    } catch (e) {
      print('DatabaseService: Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      print('DatabaseService: Creating tasks table...');
      await db.execute('''
        CREATE TABLE tasks(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT,
          dueDate INTEGER NOT NULL,
          reminderTime INTEGER,
          isCompleted INTEGER NOT NULL DEFAULT 0
        )
      ''');
      print('DatabaseService: Tasks table created successfully');
    } catch (e) {
      print('DatabaseService: Error creating table: $e');
      rethrow;
    }
  }

  // Insert a new task
  Future<int> insertTask(Task task) async {
    try {
      print('DatabaseService: Attempting to insert task: ${task.title}');
      if (kIsWeb) {
        return await WebStorageService.insertTask(task);
      }
      final db = await database;
      print('DatabaseService: Database obtained');
      final taskMap = task.toMap();
      print('DatabaseService: Task map: $taskMap');
      final result = await db.insert('tasks', taskMap);
      print('DatabaseService: Task inserted with ID: $result');
      return result;
    } catch (e) {
      print('DatabaseService: Error inserting task: $e');
      rethrow;
    }
  }

  // Get all tasks
  Future<List<Task>> getAllTasks() async {
    if (kIsWeb) {
      return await WebStorageService.getAllTasks();
    }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tasks');
    return List.generate(maps.length, (i) {
      return Task.fromMap(maps[i]);
    });
  }

  // Get tasks for a specific date
  Future<List<Task>> getTasksForDate(DateTime date) async {
    if (kIsWeb) {
      return await WebStorageService.getTasksForDate(date);
    }
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'dueDate >= ? AND dueDate <= ?',
      whereArgs: [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch],
      orderBy: 'dueDate ASC',
    );
    
    return List.generate(maps.length, (i) {
      return Task.fromMap(maps[i]);
    });
  }

  // Get today's tasks
  Future<List<Task>> getTodayTasks() async {
    if (kIsWeb) {
      return await WebStorageService.getTodayTasks();
    }
    return await getTasksForDate(DateTime.now());
  }

  // Get tasks with reminders for today
  Future<List<Task>> getTodayReminders() async {
    if (kIsWeb) {
      return await WebStorageService.getTodayReminders();
    }
    final db = await database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'reminderTime >= ? AND reminderTime <= ? AND isCompleted = 0',
      whereArgs: [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch],
      orderBy: 'reminderTime ASC',
    );
    
    return List.generate(maps.length, (i) {
      return Task.fromMap(maps[i]);
    });
  }

  // Update a task
  Future<int> updateTask(Task task) async {
    if (kIsWeb) {
      await WebStorageService.updateTask(task);
      return 1; // Return success indicator
    }
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  // Delete a task
  Future<int> deleteTask(int id) async {
    if (kIsWeb) {
      await WebStorageService.deleteTask(id);
      return 1; // Return success indicator
    }
    final db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get tasks for a date range (for calendar highlighting)
  Future<List<Task>> getTasksForDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'dueDate >= ? AND dueDate <= ?',
      whereArgs: [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ],
    );
    
    return List.generate(maps.length, (i) {
      return Task.fromMap(maps[i]);
    });
  }

  // Get dates that have tasks (for calendar highlighting)
  Future<List<DateTime>> getDatesWithTasks(DateTime month) async {
    if (kIsWeb) {
      return await WebStorageService.getDatesWithTasks(month);
    }
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);
    
    final tasks = await getTasksForDateRange(startOfMonth, endOfMonth);
    final dates = <DateTime>{};
    
    for (final task in tasks) {
      dates.add(DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day));
    }
    
    return dates.toList()..sort();
  }

  // Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
