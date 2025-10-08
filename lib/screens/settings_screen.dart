// Settings screen for configuring app preferences and viewing app information
// Provides toggles for reminders, displays storage information, and app statistics
// Includes data management options like resetting settings and clearing tasks

import 'package:flutter/material.dart';      // Flutter Material Design components
import '../services/settings_service.dart';  // Service for managing app settings
import '../services/database_service.dart';  // Service for database operations

/// Settings screen widget for app configuration and information display
/// Provides user interface for managing app preferences and viewing statistics
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

/// State class for SettingsScreen managing settings data and user interactions
class _SettingsScreenState extends State<SettingsScreen> {
  // Service instances for settings and database operations
  final SettingsService _settingsService = SettingsService();
  final DatabaseService _databaseService = DatabaseService();
  
  // State variables for UI display
  bool _remindersEnabled = true;    // Current reminder toggle state
  String _storageMethod = 'SQLite'; // Current storage method being used
  int _totalTasks = 0;              // Total number of tasks in database
  bool _isLoading = true;           // Loading state for async operations

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadTaskCount();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _settingsService.getAllSettings();
      setState(() {
        _remindersEnabled = settings['remindersEnabled'] as bool;
        _storageMethod = settings['storageMethod'] as String;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    }
  }

  Future<void> _loadTaskCount() async {
    try {
      final tasks = await _databaseService.getAllTasks();
      setState(() {
        _totalTasks = tasks.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading task count: $e')),
        );
      }
    }
  }

  Future<void> _toggleReminders(bool value) async {
    try {
      await _settingsService.setRemindersEnabled(value);
      setState(() {
        _remindersEnabled = value;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value ? 'Reminders enabled' : 'Reminders disabled',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating reminders: $e')),
        );
      }
    }
  }

  Future<void> _resetSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to their default values?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _settingsService.resetToDefaults();
        await _loadSettings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings reset successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error resetting settings: $e')),
          );
        }
      }
    }
  }

  Future<void> _clearAllTasks() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Tasks'),
        content: const Text(
          'Are you sure you want to delete all tasks? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Note: This is a simplified approach. In a real app, you might want
        // to add a method to DatabaseService to clear all tasks
        final tasks = await _databaseService.getAllTasks();
        for (final task in tasks) {
          if (task.id != null) {
            await _databaseService.deleteTask(task.id!);
          }
        }
        await _loadTaskCount();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All tasks deleted successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting tasks: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // App Information Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'App Information',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          'App Name',
                          'Study Planner',
                          Icons.apps,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          'Version',
                          '1.0.0',
                          Icons.info,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          'Total Tasks',
                          _totalTasks.toString(),
                          Icons.task_alt,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Storage Information Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Storage Information',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          'Storage Method',
                          _storageMethod,
                          Icons.storage,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          'Database',
                          'SQLite (Local)',
                          Icons.storage,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          'Data Location',
                          'Device Storage',
                          Icons.phone_android,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Reminder Settings Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reminder Settings',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Enable Reminders'),
                          subtitle: const Text(
                            'Show reminder notifications for tasks',
                          ),
                          value: _remindersEnabled,
                          onChanged: _toggleReminders,
                          secondary: const Icon(Icons.notifications),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Data Management Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Management',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.refresh, color: Colors.blue),
                          title: const Text('Reset Settings'),
                          subtitle: const Text('Reset all settings to defaults'),
                          onTap: _resetSettings,
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.delete_forever, color: Colors.red),
                          title: const Text('Clear All Tasks'),
                          subtitle: const Text('Delete all tasks permanently'),
                          onTap: _clearAllTasks,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // About Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Study Planner App is a comprehensive task management application built with Flutter. It helps you organize your study schedule, track tasks, and stay on top of your academic goals.',
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Features:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text('• Task management with due dates'),
                        const Text('• Calendar view with task highlighting'),
                        const Text('• Reminder system'),
                        const Text('• Local data storage'),
                        const Text('• Material Design UI'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
