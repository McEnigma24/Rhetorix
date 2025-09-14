import 'package:flutter/material.dart';
import 'dart:async';
import '../services/task_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await TaskService.getTodayTasks();
    setState(() {
      _tasks = tasks;
      _isLoading = false;
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
                  // Status wykonanych zadań
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dzisiejszy postęp',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_completedTasksCount z ${_tasks.length} zadań wykonanych',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        CircularProgressIndicator(
                          value: _completedTasksCount / _tasks.length,
                          backgroundColor: Colors.teal.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  const Text(
                    'Dzisiejsze ćwiczenia:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  Expanded(
                    child: ListView(
                      children: [
                        _buildTaskCard(
                          context,
                          'Skojarzenia',
                          'Generuj losowe słowa i mów skojarzenia',
                          Icons.psychology,
                          Colors.blue,
                          _tasks.isNotEmpty ? _tasks[0].isCompleted : false,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AssociationsScreen()),
                          ).then((_) => _loadTasks()),
                        ),
                        const SizedBox(height: 12),
                        _buildTaskCard(
                          context,
                          'Czytanie z korkiem',
                          'Przeczytaj 2 strony książki z korkiem w ustach',
                          Icons.menu_book,
                          Colors.green,
                          _tasks.length > 1 ? _tasks[1].isCompleted : false,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ReadingScreen()),
                          ).then((_) => _loadTasks()),
                        ),
                        const SizedBox(height: 12),
                        _buildTaskCard(
                          context,
                          'Opowiadanie historii',
                          'Opowiadaj historię przez 5 minut bez przerywników',
                          Icons.mic,
                          Colors.orange,
                          _tasks.length > 2 ? _tasks[2].isCompleted : false,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const StorytellingScreen()),
                          ).then((_) => _loadTasks()),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Kalendarz
                  const Text(
                    'Kalendarz postępów:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
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
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                              color: isCompleted ? Colors.grey : null,
                            ),
                          ),
                        ),
                        if (isCompleted)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 24,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
