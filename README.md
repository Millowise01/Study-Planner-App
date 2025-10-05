# Study Planner App

A comprehensive task management application built with Flutter that helps you organize your study schedule, track tasks, and stay on top of your academic goals.

## Features

- **Task Management**: Create, edit, and delete tasks with due dates and descriptions
- **Calendar View**: Visual calendar with task highlighting and date selection
- **Reminder System**: Set reminders for tasks with notification support
- **Today View**: Quick overview of today's tasks and their completion status
- **Settings**: Configure app preferences and manage data
- **Local Storage**: All data is stored locally using SQLite database
- **Material Design**: Modern, clean UI following Material Design principles

## Screenshots

The app includes three main screens:
- **Today**: Shows tasks due today with completion tracking
- **Calendar**: Monthly calendar view with task visualization
- **Settings**: App configuration and data management

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Windows development environment (for Windows desktop)
- Visual Studio 2022 (for Windows builds)

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd Study-Planner-App
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run -d windows
   ```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── task.dart            # Task data model
├── screens/
│   ├── today_screen.dart    # Today's tasks view
│   ├── calendar_screen.dart # Calendar view
│   └── settings_screen.dart # Settings and preferences
├── services/
│   ├── database_service.dart # SQLite database operations
│   └── settings_service.dart # App settings management
└── widgets/
    ├── add_task_dialog.dart  # Task creation/editing dialog
    ├── calendar_widget.dart  # Custom calendar widget
    └── task_tile.dart       # Individual task display widget
```

## Dependencies

- `flutter`: Flutter SDK
- `sqflite`: SQLite database for local storage
- `path`: File path utilities
- `intl`: Internationalization and date formatting
- `shared_preferences`: Simple key-value storage for settings
- `cupertino_icons`: iOS-style icons

## Recent Fixes

The following issues were identified and fixed:

### Compilation Errors
- **CardTheme Type Issue**: Fixed `CardTheme` to `CardThemeData` in main.dart
- **Icons.database**: Replaced non-existent `Icons.database` with `Icons.storage`
- **Test File**: Updated test to use correct `StudyPlannerApp` class name

### Code Quality Issues
- **Unused Imports**: Removed unused import of `settings_service.dart` in today_screen.dart
- **Unused Fields**: Removed unused `_remindersEnabled`, `_reminderTime`, and `_settingsService` fields
- **Deprecated Methods**: Updated `withOpacity()` to `withValues(alpha:)` for color transparency

### Layout Issues
- **Calendar Widget**: Fixed unbounded height constraints by:
  - Using `Flexible` instead of `Expanded` widgets
  - Setting fixed height (400px) for calendar container
  - Preventing layout overflow in calendar grid

### Platform Support
- **Windows Desktop**: Added Windows desktop support using `flutter create --platforms=windows`

## Usage

### Adding Tasks
1. Tap the "+" floating action button on any screen
2. Fill in task title (required) and description (optional)
3. Set due date and time
4. Optionally set a reminder time
5. Tap "Add Task" to save

### Managing Tasks
- **Complete**: Tap the checkbox or task tile to mark as complete
- **Edit**: Use the menu button (⋮) on any task tile
- **Delete**: Use the menu button and confirm deletion

### Calendar Navigation
- Use arrow buttons to navigate between months
- Tap any date to view tasks for that day
- Dates with tasks are highlighted with a border and dot indicator

### Settings
- Toggle reminder notifications on/off
- View app information and task statistics
- Reset settings to defaults
- Clear all tasks (with confirmation)

## Development

### Running Tests
```bash
flutter test
```

### Code Analysis
```bash
flutter analyze
```

### Building for Release
```bash
flutter build windows
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and analysis
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions, please create an issue in the repository or contact the development team.