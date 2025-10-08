# Study Planner App - Architecture Documentation

## 📋 Table of Contents
- [Project Overview](#project-overview)
- [Architecture Pattern](#architecture-pattern)
- [Folder Structure](#folder-structure)
- [Data Flow](#data-flow)
- [Platform Support](#platform-support)
- [Key Design Decisions](#key-design-decisions)

## 🎯 Project Overview

The Study Planner App is a cross-platform Flutter application designed to help students organize their tasks, manage schedules, and stay on top of their academic goals. The app follows clean architecture principles with clear separation of concerns between UI, business logic, and data layers.

## 🏗️ Architecture Pattern

### Model-View-Service Architecture
The app implements a simplified clean architecture pattern:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Presentation  │    │    Business     │    │      Data       │
│     Layer       │◄──►│     Logic       │◄──►│     Layer       │
│   (Screens/     │    │   (Services)    │    │  (Database/     │
│    Widgets)     │    │                 │    │   Storage)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Layer Responsibilities

#### 1. Presentation Layer (`/screens`, `/widgets`)
- **Purpose**: User interface components and user interaction handling
- **Components**: 
  - Screens (Today, Calendar, Settings)
  - Reusable widgets (TaskTile, AddTaskDialog, CalendarWidget)
- **Responsibilities**:
  - Rendering UI components
  - Handling user input
  - Managing local widget state
  - Calling service methods

#### 2. Business Logic Layer (`/services`)
- **Purpose**: Application logic and data manipulation
- **Components**:
  - DatabaseService: Data persistence operations
  - SettingsService: App configuration management
- **Responsibilities**:
  - CRUD operations
  - Data validation
  - Business rule enforcement
  - Platform abstraction

#### 3. Data Layer (`/models`)
- **Purpose**: Data structures and serialization
- **Components**:
  - Task model: Core data structure
- **Responsibilities**:
  - Data modeling
  - Serialization/deserialization
  - Data validation

## 📁 Folder Structure

```
lib/
├── main.dart                    # App entry point and navigation setup
├── models/                      # Data models
│   └── task.dart               # Task data model with serialization
├── screens/                     # Main application screens
│   ├── today_screen.dart       # Today's tasks view
│   ├── calendar_screen.dart    # Calendar view with task highlighting
│   └── settings_screen.dart    # App settings and information
├── services/                    # Business logic and data services
│   ├── database_service.dart   # Main database service with platform detection
│   ├── database_service_io.dart # Native platform database initialization
│   ├── database_service_web.dart # Web platform database initialization
│   ├── database_service_stub.dart # Fallback stub implementation
│   ├── web_storage_service.dart # Web-specific storage using SharedPreferences
│   └── settings_service.dart   # App settings management
└── widgets/                     # Reusable UI components
    ├── add_task_dialog.dart    # Task creation/editing dialog
    ├── task_tile.dart          # Individual task display widget
    └── calendar_widget.dart    # Custom calendar component
```

## 🔄 Data Flow

### Task Creation Flow
```
User Input → AddTaskDialog → DatabaseService → Storage Layer
     ↓              ↓              ↓              ↓
  Form Data → Task Object → Platform Router → SQLite/SharedPrefs
```

### Task Retrieval Flow
```
Screen Load → DatabaseService → Storage Layer → Task Objects → UI Update
     ↓              ↓              ↓              ↓              ↓
  initState() → getTodayTasks() → Query DB → List<Task> → setState()
```

## 🌐 Platform Support

### Cross-Platform Strategy
The app uses conditional imports and platform detection to provide optimal storage solutions:

#### Native Platforms (Android, iOS, Desktop)
- **Storage**: SQLite database via `sqflite` package
- **Initialization**: `sqflite_common_ffi` for desktop platforms
- **Features**: Full relational database capabilities, complex queries

#### Web Platform
- **Storage**: SharedPreferences via browser localStorage
- **Serialization**: JSON encoding/decoding for Task objects
- **Features**: Persistent storage across browser sessions

### Platform Detection Logic
```dart
// Conditional imports choose implementation at compile time
import 'database_service_stub.dart'
    if (dart.library.io) 'database_service_io.dart'      // Native
    if (dart.library.html) 'database_service_web.dart';  // Web

// Runtime platform detection
if (kIsWeb) {
    // Use SharedPreferences storage
} else {
    // Use SQLite database
}
```

## 🎯 Key Design Decisions

### 1. Singleton Pattern for Services
**Decision**: Use singleton pattern for DatabaseService and SettingsService
**Rationale**: 
- Ensures single database connection
- Prevents resource conflicts
- Maintains consistent state across app

### 2. Platform Abstraction
**Decision**: Abstract storage layer behind unified interface
**Rationale**:
- Single codebase for all platforms
- Easy to add new storage methods
- Transparent to UI layer

### 3. Immutable Data Models
**Decision**: Use immutable Task objects with copyWith method
**Rationale**:
- Prevents accidental data modification
- Easier to track state changes
- Better performance with Flutter's rebuild optimization

### 4. State Management
**Decision**: Use StatefulWidget with setState for local state
**Rationale**:
- Simple and appropriate for app complexity
- No external dependencies
- Easy to understand and maintain

### 5. Error Handling Strategy
**Decision**: Use try-catch blocks with user-friendly error messages
**Rationale**:
- Graceful degradation on errors
- User feedback for failed operations
- Debug information for development

## 🔧 Service Layer Details

### DatabaseService
- **Pattern**: Singleton with lazy initialization
- **Responsibilities**: CRUD operations, platform routing
- **Error Handling**: Exception propagation with logging

### SettingsService
- **Pattern**: Singleton with SharedPreferences backend
- **Responsibilities**: App configuration persistence
- **Default Values**: Sensible defaults for first-time users

## 🎨 UI Architecture

### Screen Structure
Each screen follows consistent pattern:
1. StatefulWidget with private State class
2. Service instances as final fields
3. State variables for UI data
4. Lifecycle methods (initState, dispose)
5. Business logic methods (private)
6. Build method with Material Design components

### Widget Composition
- Reusable widgets in `/widgets` folder
- Props-based configuration
- Callback functions for parent communication
- Consistent Material Design theming

## 🚀 Performance Considerations

### Database Optimization
- Indexed queries for date-based operations
- Lazy database initialization
- Connection reuse via singleton pattern

### UI Performance
- IndexedStack for tab navigation (preserves state)
- Const constructors where possible
- Efficient ListView.builder for task lists

### Memory Management
- Proper disposal of TextEditingControllers
- Mounted checks before setState calls
- Singleton services prevent memory leaks

## 🔮 Future Extensibility

The architecture supports easy extension:
- **New Storage Backends**: Add new platform-specific implementations
- **Additional Features**: Extend Task model and add service methods
- **UI Themes**: Leverage existing ThemeData structure
- **Internationalization**: String externalization ready
- **State Management**: Easy migration to Provider/Bloc if needed

This architecture provides a solid foundation for a maintainable, scalable, and cross-platform Flutter application.