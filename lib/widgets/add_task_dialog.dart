import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class AddTaskDialog extends StatefulWidget {
  final Task? task;

  const AddTaskDialog({super.key, this.task});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _dueDate = DateTime.now();
  TimeOfDay _dueTime = TimeOfDay.now();
  TimeOfDay? _reminderTimeOfDay;
  bool _hasReminder = false;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description ?? '';
      _dueDate = widget.task!.dueDate;
      _dueTime = TimeOfDay.fromDateTime(widget.task!.dueDate);
      if (widget.task!.reminderTime != null) {
        _reminderTimeOfDay = TimeOfDay.fromDateTime(widget.task!.reminderTime!);
        _hasReminder = true;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _dueDate = date;
      });
    }
  }

  Future<void> _selectDueTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _dueTime,
    );
    if (time != null) {
      setState(() {
        _dueTime = time;
      });
    }
  }

  Future<void> _selectReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTimeOfDay ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        _reminderTimeOfDay = time;
        _hasReminder = true;
      });
    }
  }

  void _saveTask() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }

    final dueDateTime = DateTime(
      _dueDate.year,
      _dueDate.month,
      _dueDate.day,
      _dueTime.hour,
      _dueTime.minute,
    );

    DateTime? reminderDateTime;
    if (_hasReminder && _reminderTimeOfDay != null) {
      reminderDateTime = DateTime(
        _dueDate.year,
        _dueDate.month,
        _dueDate.day,
        _reminderTimeOfDay!.hour,
        _reminderTimeOfDay!.minute,
      );
    }

    final task = Task(
      id: widget.task?.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      dueDate: dueDateTime,
      reminderTime: reminderDateTime,
      isCompleted: widget.task?.isCompleted ?? false,
    );

    Navigator.of(context).pop(task);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.task == null ? 'Add New Task' : 'Edit Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title field
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
                hintText: 'Enter task title',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),

            // Description field
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                hintText: 'Enter task description (optional)',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Due date and time
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Due Date'),
                    subtitle: Text(DateFormat('MMM dd, yyyy').format(_dueDate)),
                    onTap: _selectDueDate,
                  ),
                ),
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Due Time'),
                    subtitle: Text(_dueTime.format(context)),
                    onTap: _selectDueTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Reminder toggle and time
            SwitchListTile(
              title: const Text('Set Reminder'),
              subtitle: _hasReminder && _reminderTimeOfDay != null
                  ? Text('Reminder at ${_reminderTimeOfDay!.format(context)}')
                  : const Text('No reminder set'),
              value: _hasReminder,
              onChanged: (value) {
                setState(() {
                  _hasReminder = value;
                  if (value && _reminderTimeOfDay == null) {
                    _reminderTimeOfDay = TimeOfDay.now();
                  }
                });
              },
              secondary: const Icon(Icons.notifications),
            ),
            if (_hasReminder) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _selectReminderTime,
                  icon: const Icon(Icons.schedule),
                  label: Text(
                    _reminderTimeOfDay != null
                        ? 'Reminder: ${_reminderTimeOfDay!.format(context)}'
                        : 'Select Reminder Time',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveTask,
          child: Text(widget.task == null ? 'Add Task' : 'Update Task'),
        ),
      ],
    );
  }
}
