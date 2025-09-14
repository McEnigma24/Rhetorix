import 'package:flutter/material.dart';
import '../services/calendar_service.dart';

class CalendarWidget extends StatefulWidget {
  final Function(DateTime) onDateSelected;
  
  const CalendarWidget({
    super.key,
    required this.onDateSelected,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  DateTime _currentMonth = DateTime.now();
  List<int> _completedDays = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompletedDays();
  }

  Future<void> _loadCompletedDays() async {
    final completedDays = await CalendarService.getCompletedDaysInMonth(_currentMonth);
    setState(() {
      _completedDays = completedDays;
      _isLoading = false;
    });
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _isLoading = true;
    });
    _loadCompletedDays();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      _isLoading = true;
    });
    _loadCompletedDays();
  }

  String _getMonthName(int month) {
    const months = [
      'Styczeń', 'Luty', 'Marzec', 'Kwiecień', 'Maj', 'Czerwiec',
      'Lipiec', 'Sierpień', 'Wrzesień', 'Październik', 'Listopad', 'Grudzień'
    ];
    return months[month - 1];
  }

  List<Widget> _buildCalendarDays() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    List<Widget> dayWidgets = [];

    // Nagłówki dni tygodnia
    const weekdays = ['P', 'W', 'Ś', 'C', 'P', 'S', 'N'];
    for (String day in weekdays) {
      dayWidgets.add(
        Container(
          height: 28,
          alignment: Alignment.center,
          child: Text(
            day,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    // Puste miejsca na początku miesiąca
    for (int i = 1; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox(height: 28));
    }

    // Dni miesiąca
    for (int day = 1; day <= daysInMonth; day++) {
      final isToday = day == DateTime.now().day && 
                     _currentMonth.month == DateTime.now().month && 
                     _currentMonth.year == DateTime.now().year;
      
      dayWidgets.add(
        GestureDetector(
          onTap: () {
            final selectedDate = DateTime(_currentMonth.year, _currentMonth.month, day);
            widget.onDateSelected(selectedDate);
          },
          child: Container(
            height: 28,
            width: 28,
            decoration: BoxDecoration(
              color: isToday 
                ? Colors.teal.withOpacity(0.2)
                : null,
              borderRadius: BorderRadius.circular(14),
              border: isToday 
                ? Border.all(color: Colors.teal, width: 2)
                : null,
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    day.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday 
                        ? Colors.teal
                        : Colors.black,
                    ),
                  ),
                ),
                // Kropki zadań
                Positioned(
                  bottom: 1,
                  child: _buildTaskDots(day),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return dayWidgets;
  }

  Widget _buildTaskDots(int day) {
    return FutureBuilder<Map<String, bool>>(
      future: CalendarService.getDayTasksInMonth(_currentMonth, day),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        
        final tasks = snapshot.data!;
        final completedTasks = tasks.entries.where((entry) => entry.value).toList();
        
        if (completedTasks.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: completedTasks.map((task) {
            Color color;
            switch (task.key) {
              case 'associations':
                color = Colors.blue;
                break;
              case 'reading':
                color = Colors.green;
                break;
              case 'storytelling':
                color = Colors.orange;
                break;
              default:
                color = Colors.grey;
            }
            
            return Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 0.5),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Nagłówek z miesiącem i strzałkami
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _previousMonth,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Kalendarz
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: _buildCalendarDays(),
              ),
            
            const SizedBox(height: 16),
            
            // Legenda
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 4,
              children: [
                _buildLegendItem(
                  'Dzisiaj',
                  Colors.teal,
                  Icons.circle,
                ),
                _buildLegendItem(
                  'Skojarzenia',
                  Colors.blue,
                  Icons.fiber_manual_record,
                ),
                _buildLegendItem(
                  'Czytanie',
                  Colors.green,
                  Icons.fiber_manual_record,
                ),
                _buildLegendItem(
                  'Opowiadanie',
                  Colors.orange,
                  Icons.fiber_manual_record,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
