// Main entry point for the Study Planner App
// This file sets up the app's theme, navigation, and initializes core services

import 'package:flutter/material.dart';     // Flutter Material Design components
import 'package:flutter/foundation.dart';   // Platform detection utilities
import 'screens/today_screen.dart';         // Today's tasks screen
import 'screens/calendar_screen.dart';      // Calendar view screen
import 'screens/settings_screen.dart';      // App settings screen
import 'services/database_service.dart';    // Database operations service
import 'services/settings_service.dart';    // App settings service
import 'models/task.dart';                  // Task data model

/// Entry point of the application
/// Initializes the Flutter app with StudyPlannerApp as the root widget
void main() {
  runApp(const StudyPlannerApp());
}

/// Root widget of the Study Planner App
/// Configures the app's theme, title, and sets MainScreen as the home widget
/// Uses Material Design 3 with a deep purple color scheme for consistent UI
class StudyPlannerApp extends StatelessWidget {
  const StudyPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Planner',  // App title shown in task switcher
      theme: ThemeData(
        // Generate color scheme from deep purple seed color
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,  // Enable Material Design 3 components
        
        // Customize AppBar appearance across the app
        appBarTheme: const AppBarTheme(
          centerTitle: true,  // Center the title text
          elevation: 0,       // Remove shadow for modern flat design
        ),
        
        // Customize Card widgets with rounded corners and subtle elevation
        cardTheme: const CardThemeData(
          elevation: 2,  // Subtle shadow for depth
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        
        // Customize FloatingActionButton appearance
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 4,  // Standard elevation for FAB
        ),
      ),
      home: const MainScreen(),        // Set MainScreen as the initial screen
      debugShowCheckedModeBanner: false,  // Hide debug banner in debug mode
    );
  }
}

/// Main screen widget that manages bottom navigation and screen switching
/// Contains three main screens: Today, Calendar, and Settings
/// Handles app initialization, database setup, and reminder notifications
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

/// State class for MainScreen managing navigation and app lifecycle
class _MainScreenState extends State<MainScreen> {
  // Current selected tab index (0=Today, 1=Calendar, 2=Settings)
  int _currentIndex = 0;
  
  // Service instances for database and settings operations
  final DatabaseService _databaseService = DatabaseService();
  final SettingsService _settingsService = SettingsService();

  // List of screens corresponding to bottom navigation tabs
  // Using const constructors for better performance
  final List<Widget> _screens = [
    const TodayScreen(),     // Index 0: Today's tasks
    const CalendarScreen(),  // Index 1: Calendar view
    const SettingsScreen(),  // Index 2: App settings
  ];

  @override
  void initState() {
    super.initState();
    _initializeApp();  // Start app initialization process
  }

  /// Initializes the app by setting up database and checking for reminders
  /// Handles platform-specific initialization (skips database for web)
  /// Shows error messages if initialization fails
  Future<void> _initializeApp() async {
    try {
      // Initialize database connection (desktop/mobile only)
      // Web platform uses different storage mechanism
      if (!kIsWeb) {
        await _databaseService.database;
      }
      
      // Check for any active reminders that should be displayed
      await _checkReminders();
    } catch (e) {
      // Show error message to user if initialization fails
      // Only show if widget is still mounted to avoid memory leaks
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing app: $e')),
        );
      }
    }
  }

  /// Checks for active reminders and displays notification dialog if needed
  /// Only shows reminders if they are enabled in settings
  /// Filters reminders to show only those within the current hour
  Future<void> _checkReminders() async {
    try {
      // Check if user has enabled reminders in settings
      final remindersEnabled = await _settingsService.getRemindersEnabled();
      if (!remindersEnabled) return;  // Exit early if reminders are disabled

      final now = DateTime.now();
      // Get all tasks that have reminders set for today
      final todayReminders = await _databaseService.getTodayReminders();
      
      // Calculate time window for active reminders (current hour)
      final currentHour = DateTime(now.year, now.month, now.day, now.hour);
      final nextHour = currentHour.add(const Duration(hours: 1));
      
      // Filter reminders to show only active ones:
      // 1. Must have a reminder time set
      // 2. Reminder time must be within current hour
      // 3. Task must not be completed
      final activeReminders = todayReminders.where((task) {
        if (task.reminderTime == null) return false;
        return task.reminderTime!.isAfter(currentHour) && 
               task.reminderTime!.isBefore(nextHour) &&
               !task.isCompleted;
      }).toList();

      // Show reminder dialog if there are active reminders and widget is mounted
      if (activeReminders.isNotEmpty && mounted) {
        _showReminderDialog(activeReminders);
      }
    } catch (e) {
      // Silently handle reminder errors to prevent disrupting app startup
      // Use debugPrint instead of showing user-facing error
      debugPrint('Error checking reminders: $e');
    }
  }

  /// Displays a modal dialog showing active reminders to the user
  /// Dialog cannot be dismissed by tapping outside (barrierDismissible: false)
  /// Provides options to dismiss or navigate to Today screen to view tasks
  void _showReminderDialog(List<Task> reminders) {
    showDialog(
      context: context,
      barrierDismissible: false,  // Force user to interact with dialog
      builder: (context) => AlertDialog(
        // Dialog title with notification icon and "Reminders" text
        title: const Row(
          children: [
            Icon(Icons.notifications, color: Colors.orange),  // Orange notification icon
            SizedBox(width: 8),  // Spacing between icon and text
            Text('Reminders'),
          ],
        ),
        
        // Dialog content showing list of reminder tasks
        content: Column(
          mainAxisSize: MainAxisSize.min,  // Only take needed space
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You have upcoming tasks:'),
            const SizedBox(height: 16),  // Spacing before task list
            
            // Map each reminder task to a display widget
            ...reminders.map((task) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.schedule, size: 16),  // Small clock icon
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Task title in bold
                        Text(
                          task.title,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        // Show reminder time if available
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
        
        // Dialog action buttons
        actions: [
          // Dismiss button - closes dialog without action
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Dismiss'),
          ),
          // View Tasks button - closes dialog and switches to Today screen
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();  // Close dialog first
              setState(() {
                _currentIndex = 0;  // Switch to Today screen (index 0)
              });
            },
            child: const Text('View Tasks'),
          ),
        ],
      ),
    );
  }

  /// Handles bottom navigation tab selection
  /// Updates the current index and triggers a rebuild to show the selected screen
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;  // Update selected tab index
    });
  }

  /// Builds the main screen UI with bottom navigation
  /// Uses IndexedStack to preserve state across tab switches
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Main body using IndexedStack to maintain screen states
      // IndexedStack keeps all screens in memory but only shows the selected one
      // This preserves scroll position and form data when switching tabs
      body: IndexedStack(
        index: _currentIndex,  // Show screen at current index
        children: _screens,    // List of screen widgets
      ),
      
      // Bottom navigation bar with three tabs
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,        // Highlight current tab
        onTap: _onTabTapped,               // Handle tab selection
        type: BottomNavigationBarType.fixed,  // Fixed type for 3 tabs
        
        // Theme colors for selected and unselected tabs
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.outline,
        
        // Define the three navigation tabs
        items: const [
          // Today tab - shows tasks due today
          BottomNavigationBarItem(
            icon: Icon(Icons.today),
            label: 'Today',
          ),
          // Calendar tab - shows monthly calendar view
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          // Settings tab - shows app configuration
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
