import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../widgets/task_tile.dart';
import '../widgets/add_task_dialog.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Task> _todayTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodayTasks();
  }

  Future<void> _loadTodayTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tasks = await _databaseService.getTodayTasks();
      setState(() {
        _todayTasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tasks: $e')),
        );
      }
    }
  }

  Future<void> _addTask() async {
    final result = await showDialog<Task>(
      context: context,
      builder: (context) => const AddTaskDialog(),
    );

    if (result != null) {
      try {
        print('Attempting to save task: ${result.title}');
        final taskId = await _databaseService.insertTask(result);
        print('Task saved with ID: $taskId');
        await _loadTodayTasks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task added successfully!')),
          );
        }
      } catch (e) {
        print('Error adding task: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding task: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    try {
      final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
      await _databaseService.updateTask(updatedTask);
      await _loadTodayTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating task: $e')),
        );
      }
    }
  }

  Future<void> _deleteTask(Task task) async {
    if (task.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.deleteTask(task.id!);
        await _loadTodayTasks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task deleted successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting task: $e')),
          );
        }
      }
    }
  }

  Future<void> _editTask(Task task) async {
    final result = await showDialog<Task>(
      context: context,
      builder: (context) => AddTaskDialog(task: task),
    );

    if (result != null) {
      try {
        await _databaseService.updateTask(result);
        await _loadTodayTasks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task updated successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating task: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM dd, yyyy').format(today);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTodayTasks,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with date
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Text(
                  formattedDate,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_todayTasks.length} task${_todayTasks.length != 1 ? 's' : ''} for today',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          
          // Tasks list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _todayTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.task_alt,
                              size: 64,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No tasks for today!',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the + button to add a new task',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTodayTasks,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _todayTasks.length,
                          itemBuilder: (context, index) {
                            final task = _todayTasks[index];
                            return TaskTile(
                              task: task,
                              onToggleComplete: () => _toggleTaskCompletion(task),
                              onEdit: () => _editTask(task),
                              onDelete: () => _deleteTask(task),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ),
    );
  }
}
