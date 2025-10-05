import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarWidget extends StatefulWidget {
  final DateTime selectedDate;
  final List<DateTime> datesWithTasks;
  final Function(DateTime) onDateSelected;
  final Function(DateTime) onMonthChanged;

  const CalendarWidget({
    super.key,
    required this.selectedDate,
    required this.datesWithTasks,
    required this.onDateSelected,
    required this.onMonthChanged,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _currentMonth;
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month);
    _currentPage = _getPageForDate(_currentMonth);
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void didUpdateWidget(CalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      final newMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month);
      if (newMonth != _currentMonth) {
        _currentMonth = newMonth;
        final newPage = _getPageForDate(_currentMonth);
        if (newPage != _currentPage) {
          _currentPage = newPage;
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _getPageForDate(DateTime date) {
    final now = DateTime.now();
    return (date.year - now.year) * 12 + (date.month - now.month);
  }

  DateTime _getDateForPage(int page) {
    final now = DateTime.now();
    return DateTime(now.year, now.month + page, 1);
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
      _currentMonth = _getDateForPage(page);
    });
    widget.onMonthChanged(_currentMonth);
  }

  void _previousMonth() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextMonth() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month navigation header
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _previousMonth,
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Previous month',
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_currentMonth),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next month',
                ),
              ],
            ),
          ),
          
          // Calendar grid
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, page) {
                final month = _getDateForPage(page);
                return _buildMonthCalendar(month);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthCalendar(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final firstDayOfWeek = firstDayOfMonth.weekday;
    
    // Calculate the number of weeks needed
    final daysInMonth = lastDayOfMonth.day;
    final totalCells = ((firstDayOfWeek - 1) + daysInMonth + 6) ~/ 7 * 7;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Weekday headers
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          
          // Calendar grid
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
              ),
              itemCount: totalCells,
              itemBuilder: (context, index) {
                final dayIndex = index - (firstDayOfWeek - 1);
                final isCurrentMonth = dayIndex >= 0 && dayIndex < daysInMonth;
                final day = isCurrentMonth ? dayIndex + 1 : null;
                final date = isCurrentMonth
                    ? DateTime(month.year, month.month, day!)
                    : null;
                
                if (!isCurrentMonth) {
                  return const SizedBox.shrink();
                }
                
                final isSelected = date != null &&
                    date.year == widget.selectedDate.year &&
                    date.month == widget.selectedDate.month &&
                    date.day == widget.selectedDate.day;
                
                final hasTasks = date != null &&
                    widget.datesWithTasks.any((taskDate) =>
                        taskDate.year == date.year &&
                        taskDate.month == date.month &&
                        taskDate.day == date.day);
                
                final isToday = date != null &&
                    date.year == DateTime.now().year &&
                    date.month == DateTime.now().month &&
                    date.day == DateTime.now().day;
                
                return GestureDetector(
                  onTap: () => widget.onDateSelected(date!),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : isToday
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: hasTasks && !isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          day.toString(),
                          style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : isToday
                                    ? Theme.of(context).colorScheme.onPrimaryContainer
                                    : Theme.of(context).colorScheme.onSurface,
                            fontWeight: isSelected || isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        if (hasTasks && !isSelected)
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
