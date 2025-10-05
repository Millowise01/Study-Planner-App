import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const String _remindersEnabledKey = 'reminders_enabled';
  static const String _storageMethodKey = 'storage_method';

  // Get SharedPreferences instance
  Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  // Get reminders enabled status
  Future<bool> getRemindersEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_remindersEnabledKey) ?? true; // Default to enabled
  }

  // Set reminders enabled status
  Future<void> setRemindersEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_remindersEnabledKey, enabled);
  }

  // Get storage method
  Future<String> getStorageMethod() async {
    final prefs = await _prefs;
    return prefs.getString(_storageMethodKey) ?? 'SQLite'; // Default to SQLite
  }

  // Set storage method
  Future<void> setStorageMethod(String method) async {
    final prefs = await _prefs;
    await prefs.setString(_storageMethodKey, method);
  }

  // Get all settings as a map
  Future<Map<String, dynamic>> getAllSettings() async {
    final prefs = await _prefs;
    return {
      'remindersEnabled': prefs.getBool(_remindersEnabledKey) ?? true,
      'storageMethod': prefs.getString(_storageMethodKey) ?? 'SQLite',
    };
  }

  // Reset all settings to defaults
  Future<void> resetToDefaults() async {
    final prefs = await _prefs;
    await prefs.setBool(_remindersEnabledKey, true);
    await prefs.setString(_storageMethodKey, 'SQLite');
  }
}
