import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onToggleComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = task.isOverdue;
    final isCompleted = task.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: isCompleted ? 1 : 2,
      child: ListTile(
        leading: Checkbox(
          value: isCompleted,
          onChanged: (_) => onToggleComplete(),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted ? theme.colorScheme.outline : null,
            fontWeight: isCompleted ? FontWeight.normal : FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  task.description!,
                  style: TextStyle(
                    color: isCompleted ? theme.colorScheme.outline : null,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: isOverdue && !isCompleted
                      ? Colors.red
                      : theme.colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDueTime(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isOverdue && !isCompleted
                        ? Colors.red
                        : theme.colorScheme.outline,
                    fontWeight: isOverdue && !isCompleted ? FontWeight.w600 : null,
                  ),
                ),
                if (task.reminderTime != null) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.notifications,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    task.formattedReminderTime!,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: onToggleComplete,
      ),
    );
  }

  String _formatDueTime() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
    
    if (taskDate == today) {
      return 'Today at ${DateFormat('HH:mm').format(task.dueDate)}';
    } else if (taskDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow at ${DateFormat('HH:mm').format(task.dueDate)}';
    } else if (taskDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday at ${DateFormat('HH:mm').format(task.dueDate)}';
    } else {
      return DateFormat('MMM dd, HH:mm').format(task.dueDate);
    }
  }
}
