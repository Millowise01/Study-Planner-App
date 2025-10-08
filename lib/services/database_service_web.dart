import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// For web platform, we'll use SharedPreferences as a fallback
// since SQLite support on web can be complex
Future<void> initializeDatabaseFactory() async {
  // No initialization needed for SharedPreferences
  print('Web platform: Using SharedPreferences for data storage');
}

// We'll need to modify the main database service to handle web differently
// This is a placeholder that indicates web platform initialization