import 'package:flutter/material.dart';
import 'dart:async';
import '../services/task_service.dart';
import '../services/streak_service.dart';
import '../models/daily_task.dart';
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

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _loadStreak();
  }

  Future<void> _loadTasks() async {
    final tasks = await TaskService.getTodayTasks();
    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  Future<void> _loadStreak() async {
    await StreakService.checkAndResetStreak();
    final streak = await StreakService.getCurrentStreak();
    setState(() {
      _currentStreak = streak;
    });
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
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Streak counter
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
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
                  
                  Expanded(
                    child: ListView(
                      children: [
                        _buildTaskCard(
                          context,
                          'Skojarzenia',
                          '',
                          Icons.psychology,
                          Colors.blue,
                          _tasks.isNotEmpty ? _tasks[0].isCompleted : false,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AssociationsScreen()),
                          ).then((_) {
                            _loadTasks();
                            _loadStreak();
                          }),
                        ),
                        _buildTaskCard(
                          context,
                          'Czytanie z korkiem',
                          '',
                          Icons.menu_book,
                          Colors.green,
                          _tasks.length > 1 ? _tasks[1].isCompleted : false,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ReadingScreen()),
                          ).then((_) {
                            _loadTasks();
                            _loadStreak();
                          }),
                        ),
                        _buildTaskCard(
                          context,
                          'Opowiadanie historii',
                          '',
                          Icons.mic,
                          Colors.orange,
                          _tasks.length > 2 ? _tasks[2].isCompleted : false,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const StorytellingScreen()),
                          ).then((_) {
                            _loadTasks();
                            _loadStreak();
                          }),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Kalendarz
                        const Text(
                          'Kalendarz postępów:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        CalendarWidget(
                          onDateSelected: (date) {
                            // Można dodać funkcjonalność wyboru daty
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Wybrano datę: ${date.day}.${date.month}.${date.year}'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    bool isCompleted,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? Colors.grey : null,
                  ),
                ),
              ),
              if (isCompleted)
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                )
              else
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
