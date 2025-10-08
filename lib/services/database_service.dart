// Database service for managing task data persistence across platforms
// Implements singleton pattern to ensure single database connection
// Supports both SQLite (native) and SharedPreferences (web) storage
// Provides CRUD operations for Task objects with platform abstraction

import 'dart:async';                      // For Future and async operations
import 'package:sqflite/sqflite.dart';   // SQLite database operations
import 'package:path/path.dart';          // Path utilities for database file location
import '../models/task.dart';             // Task data model
import 'package:flutter/foundation.dart'; // For kIsWeb platform detection and debug printing
import 'web_storage_service.dart';        // Web-specific storage implementation

// Conditional imports for platform-specific database initialization
// Dart's conditional import system selects appropriate implementation at compile time
import 'database_service_stub.dart'       // Fallback stub (unused)
    if (dart.library.io) 'database_service_io.dart'      // Native platforms (Android, iOS, Desktop)
    if (dart.library.html) 'database_service_web.dart';  // Web platform

/// Singleton database service class for managing task persistence
/// Provides unified interface for both SQLite (native) and SharedPreferences (web)
/// Automatically detects platform and routes operations to appropriate storage method
class DatabaseService {
  // Singleton pattern implementation
  static final DatabaseService _instance = DatabaseService._internal();
  
  /// Factory constructor returns the singleton instance
  /// Ensures only one database connection exists throughout app lifecycle
  factory DatabaseService() => _instance;
  
  /// Private constructor for singleton pattern
  DatabaseService._internal();

  // Static database instance (null until first access)
  // Only used on native platforms (mobile/desktop)
  static Database? _database;

  /// Getter for database instance with lazy initialization
  /// Returns existing database connection or creates new one
  /// Throws UnsupportedError on web platform (uses SharedPreferences instead)
  Future<Database> get database async {
    if (kIsWeb) {
      // Web platform uses SharedPreferences via WebStorageService
      // SQLite is not available in web browsers
      throw UnsupportedError('SQLite not used on web platform');
    }
    
    // Return existing database connection if available
    if (_database != null) return _database!;
    
    // Initialize database on first access
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

  /// Inserts a new task into the database
  /// Routes to appropriate storage method based on platform
  /// Returns the auto-generated task ID from database
  /// Throws exception if insertion fails
  Future<int> insertTask(Task task) async {
    try {
      print('DatabaseService: Attempting to insert task: ${task.title}');
      
      // Use SharedPreferences storage for web platform
      if (kIsWeb) {
        return await WebStorageService.insertTask(task);
      }
      
      // Use SQLite for native platforms
      final db = await database;
      print('DatabaseService: Database obtained');
      
      // Convert Task object to Map for database insertion
      final taskMap = task.toMap();
      print('DatabaseService: Task map: $taskMap');
      
      // Insert into tasks table and get auto-generated ID
      final result = await db.insert('tasks', taskMap);
      print('DatabaseService: Task inserted with ID: $result');
      return result;
    } catch (e) {
      print('DatabaseService: Error inserting task: $e');
      rethrow;  // Re-throw exception to caller
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
