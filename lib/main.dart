import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'screens/today_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/settings_screen.dart';
import 'services/database_service.dart';
import 'services/settings_service.dart';
import 'models/task.dart';

void main() {
  runApp(const StudyPlannerApp());
}

class StudyPlannerApp extends StatelessWidget {
  const StudyPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Planner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 4,
        ),
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final DatabaseService _databaseService = DatabaseService();
  final SettingsService _settingsService = SettingsService();

  final List<Widget> _screens = [
    const TodayScreen(),
    const CalendarScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize database (skip for web)
      if (!kIsWeb) {
        await _databaseService.database;
      }
      
      // Check for reminders
      await _checkReminders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing app: $e')),
        );
      }
    }
  }

  Future<void> _checkReminders() async {
    try {
      final remindersEnabled = await _settingsService.getRemindersEnabled();
      if (!remindersEnabled) return;

      final now = DateTime.now();
      final todayReminders = await _databaseService.getTodayReminders();
      
      // Filter reminders that should be shown now (within the current hour)
      final currentHour = DateTime(now.year, now.month, now.day, now.hour);
      final nextHour = currentHour.add(const Duration(hours: 1));
      
      final activeReminders = todayReminders.where((task) {
        if (task.reminderTime == null) return false;
        return task.reminderTime!.isAfter(currentHour) && 
               task.reminderTime!.isBefore(nextHour) &&
               !task.isCompleted;
      }).toList();

      if (activeReminders.isNotEmpty && mounted) {
        _showReminderDialog(activeReminders);
      }
    } catch (e) {
      // Silently handle reminder errors to not disrupt app startup
      debugPrint('Error checking reminders: $e');
    }
  }

  void _showReminderDialog(List<Task> reminders) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications, color: Colors.orange),
            SizedBox(width: 8),
            Text('Reminders'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You have upcoming tasks:'),
            const SizedBox(height: 16),
            ...reminders.map((task) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.schedule, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (task.reminderTime != null)
                          Text(
                            'Due: ${task.formattedReminderTime}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Dismiss'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _currentIndex = 0; // Switch to Today screen
              });
            },
            child: const Text('View Tasks'),
          ),
        ],
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.outline,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.today),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
