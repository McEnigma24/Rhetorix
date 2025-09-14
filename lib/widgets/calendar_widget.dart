import 'package:flutter/material.dart';
import '../models/calendar_event.dart';
import '../services/calendar_service.dart';

class CalendarWidget extends StatefulWidget {
  final DateTime currentMonth;
  final Function(DateTime)? onDateSelected;

  const CalendarWidget({
    super.key,
    required this.currentMonth,
    this.onDateSelected,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _currentMonth;
  List<CalendarEvent> _events = [];
  Map<String, int> _eventCounts = {};

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.currentMonth;
    _loadEvents();
  }

  @override
  void didUpdateWidget(CalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentMonth != widget.currentMonth) {
      _currentMonth = widget.currentMonth;
      _loadEvents();
    }
  }

  Future<void> _loadEvents() async {
    final events = await CalendarService.getEventsForMonth(_currentMonth);
    final counts = await CalendarService.getEventCountsForMonth(_currentMonth);
    
    setState(() {
      _events = events;
      _eventCounts = counts;
    });
  }

  List<CalendarEvent> _getEventsForDate(DateTime date) {
    return _events.where((event) => 
      event.date.year == date.year &&
      event.date.month == date.month &&
      event.date.day == date.day
    ).toList();
  }

  List<DateTime> _getDaysInMonth() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekday = firstDay.weekday;
    
    final days = <DateTime>[];
    
    // Dodaj puste dni z poprzedniego miesiąca
    for (int i = firstWeekday - 1; i > 0; i--) {
      days.add(firstDay.subtract(Duration(days: i)));
    }
    
    // Dodaj dni z obecnego miesiąca
    for (int day = 1; day <= lastDay.day; day++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, day));
    }
    
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth();
    final monthNames = [
      'Styczeń', 'Luty', 'Marzec', 'Kwiecień', 'Maj', 'Czerwiec',
      'Lipiec', 'Sierpień', 'Wrzesień', 'Październik', 'Listopad', 'Grudzień'
    ];

    return Column(
      children: [
        // Nagłówek z nazwą miesiąca i rokiem
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            '${monthNames[_currentMonth.month - 1]} ${_currentMonth.year}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        
        // Legenda z kategoriami i liczbami
        if (_eventCounts.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: _eventCounts.entries.map((entry) {
                final color = CalendarService.eventCategories[entry.key] ?? Colors.grey;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${entry.key}: ${entry.value}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
        
        // Kalendarz
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Nagłówki dni tygodnia
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: ['Pon', 'Wt', 'Śr', 'Czw', 'Pt', 'Sob', 'Ndz']
                      .map((day) => Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                day,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
              
              // Siatka dni
              ...List.generate((days.length / 7).ceil(), (weekIndex) {
                final weekDays = days.skip(weekIndex * 7).take(7).toList();
                return Row(
                  children: weekDays.map((day) {
                    final isCurrentMonth = day.month == _currentMonth.month;
                    final dayEvents = isCurrentMonth ? _getEventsForDate(day) : [];
                    
                    return Expanded(
                      child: GestureDetector(
                        onTap: isCurrentMonth ? () {
                          widget.onDateSelected?.call(day);
                        } : null,
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            children: [
                              // Numer dnia
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isCurrentMonth ? Colors.black : Colors.grey[400],
                                    fontWeight: isCurrentMonth ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                ),
                              ),
                              
                              // Kuleczki z wydarzeniami
                              if (dayEvents.isNotEmpty)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: dayEvents.take(3).map((event) {
                                        return Container(
                                          width: 8,
                                          height: 8,
                                          margin: const EdgeInsets.symmetric(horizontal: 1),
                                          decoration: BoxDecoration(
                                            color: event.color,
                                            shape: BoxShape.circle,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              
                              // Więcej wydarzeń (jeśli więcej niż 3)
                              if (dayEvents.length > 3)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    '+${dayEvents.length - 3}',
                                    style: const TextStyle(
                                      fontSize: 8,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
