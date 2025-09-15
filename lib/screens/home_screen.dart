import 'package:flutter/material.dart';
import 'dart:async';
import '../services/task_service.dart';
import '../services/streak_service.dart';
import '../services/calendar_service.dart';
import '../models/daily_task.dart';
import '../models/calendar_event.dart';
import '../widgets/calendar_widget.dart';
import 'associations_screen.dart';
import 'reading_screen.dart';
import 'storytelling_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<DailyTask> _tasks = [];
  bool _isLoading = true;
  int _currentStreak = 0;
  DateTime _currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clearAllEvents();
    _loadTasks();
    _loadStreak();
  }

  Future<void> _clearAllEvents() async {
    await CalendarService.clearAllEvents();
  }

  Future<void> _refreshCalendar() async {
    print('🔄 _refreshCalendar() - START');
    
    // Załaduj zadania i zsynchronizuj z kalendarzem
    final tasks = await TaskService.getTodayTasks();
    print('📋 Załadowane zadania: ${tasks.length}');
    for (var task in tasks) {
      print('  - ${task.title}: ${task.isCompleted ? "✅" : "❌"}');
    }
    
    await _syncTasksWithCalendar();
    print('🔄 Synchronizacja z kalendarzem zakończona');
    
    // Załaduj streak
    await StreakService.checkAndResetStreak();
    final streak = await StreakService.getCurrentStreak();
    print('🔥 Streak: $streak');
    
    // Odśwież interfejs - wymuś odświeżenie kalendarza
    setState(() {
      _tasks = tasks;
      _currentStreak = streak;
      // Wymuś odświeżenie kalendarza przez zmianę klucza
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month);
    });
    print('🔄 _refreshCalendar() - END - setState() wywołane');
  }

  Future<void> _loadTasks() async {
    final tasks = await TaskService.getTodayTasks();
    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
    // Synchronizuj z kalendarzem po załadowaniu zadań
    await _syncTasksWithCalendar();
  }

  Future<void> _loadStreak() async {
    await StreakService.checkAndResetStreak();
    final streak = await StreakService.getCurrentStreak();
    setState(() {
      _currentStreak = streak;
    });
  }

  Future<void> _syncTasksWithCalendar() async {
    final today = DateTime.now();
    final todayTasks = await TaskService.getTodayTasks();
    print('🔄 _syncTasksWithCalendar() - START dla ${today.day}.${today.month}.${today.year}');
    
    // Usuń wszystkie wydarzenia z dzisiaj
    await _clearTodayEvents(today);
    print('🗑️ Wyczyszczono wydarzenia z dzisiaj');
    
    // Dodaj ukończone zadania do kalendarza
    int addedEvents = 0;
    for (final task in todayTasks) {
      if (task.isCompleted) {
        await _addTaskToCalendar(task, today);
        addedEvents++;
        print('➕ Dodano wydarzenie: ${task.title}');
      }
    }
    print('🔄 _syncTasksWithCalendar() - END - dodano $addedEvents wydarzeń');
  }

  Future<void> _clearTodayEvents(DateTime date) async {
    final month = DateTime(date.year, date.month);
    final events = await CalendarService.getEventsForMonth(month);
    final todayEvents = events.where((event) => 
      event.date.year == date.year &&
      event.date.month == date.month &&
      event.date.day == date.day
    ).toList();
    
    for (final event in todayEvents) {
      await CalendarService.removeEvent(event.id, date);
    }
  }

  Future<void> _addTaskToCalendar(DailyTask task, DateTime date) async {
    final category = _getTaskCategory(task.id);
    if (category != null) {
      final event = CalendarEvent(
        id: '${task.id}_${date.millisecondsSinceEpoch}',
        title: task.title,
        color: CalendarService.eventCategories[category]!,
        date: date,
        category: category,
      );
      await CalendarService.addEvent(event);
    }
  }

  String? _getTaskCategory(String taskId) {
    switch (taskId) {
      case 'associations':
        return 'Skojarzenia';
      case 'reading':
        return 'Czytanie z korkiem';
      case 'storytelling':
        return 'Opowiadanie historii';
      default:
        return null;
    }
  }

  int get _completedTasksCount {
    return _tasks.where((task) => task.isCompleted).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rhetorix',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Streak counter
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Streak: $_currentStreak dni',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Kalendarz
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: CalendarWidget(
                      key: ValueKey('${_currentMonth.year}-${_currentMonth.month}-${_tasks.map((t) => t.isCompleted).join()}'),
                      currentMonth: _currentMonth,
                      onMonthChanged: (newMonth) {
                        setState(() {
                          _currentMonth = newMonth;
                        });
                      },
                    ),
                  ),
                ),
                
                // Przyciski zadań
                Container(
                  key: ValueKey(_tasks.map((t) => t.isCompleted).join()),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTaskButton(
                        'Skojarzenia',
                        Icons.psychology,
                        Colors.blue,
                        _tasks.isNotEmpty ? _tasks[0].isCompleted : false,
                        () {
                          print('🔵 Kliknięto Skojarzenia');
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AssociationsScreen()),
                          ).then((_) {
                            print('🔵 Powrót z Skojarzeń - wywołuję _refreshCalendar()');
                            _refreshCalendar();
                          });
                        },
                      ),
                      _buildTaskButton(
                        'Czytanie',
                        Icons.menu_book,
                        Colors.green,
                        _tasks.length > 1 ? _tasks[1].isCompleted : false,
                        () {
                          print('🟢 Kliknięto Czytanie');
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ReadingScreen()),
                          ).then((_) {
                            print('🟢 Powrót z Czytania - wywołuję _refreshCalendar()');
                            _refreshCalendar();
                          });
                        },
                      ),
                      _buildTaskButton(
                        'Historie',
                        Icons.mic,
                        Colors.orange,
                        _tasks.length > 2 ? _tasks[2].isCompleted : false,
                        () {
                          print('🟠 Kliknięto Historie');
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const StorytellingScreen()),
                          ).then((_) {
                            print('🟠 Powrót z Historii - wywołuję _refreshCalendar()');
                            _refreshCalendar();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
      );
  }

  Widget _buildTaskButton(
    String title,
    IconData icon,
    Color color,
    bool isCompleted,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isCompleted ? color.withOpacity(0.2) : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCompleted ? color : color.withOpacity(0.3),
            width: isCompleted ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isCompleted ? color : color.withOpacity(0.7),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isCompleted ? color : color.withOpacity(0.8),
              ),
            ),
            if (isCompleted)
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

}
