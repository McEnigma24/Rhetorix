import 'package:flutter/material.dart';
import '../services/task_service.dart';
import '../models/daily_task.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  DailyTask? _task;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    final tasks = await TaskService.getTodayTasks();
    final readingTask = tasks.firstWhere(
      (task) => task.id == 'reading',
      orElse: () => DailyTask(
        id: 'reading',
        title: 'Czytanie z korkiem',
        description: 'Przeczytaj 2 strony książki z korkiem w ustach',
        date: DateTime.now(),
      ),
    );
    
    setState(() {
      _task = readingTask;
      _isLoading = false;
    });
  }

  Future<void> _toggleTask() async {
    if (_task == null) return;
    
    final updatedTask = _task!.copyWith(isCompleted: !_task!.isCompleted);
    await TaskService.updateTask(updatedTask);
    
    setState(() {
      _task = updatedTask;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Czytanie z korkiem'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Instrukcje
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.menu_book,
                          color: Colors.green,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Instrukcje',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '1. Weź korek (np. z butelki wina) i włóż go do ust\n'
                      '2. Otwórz książkę na dowolnej stronie\n'
                      '3. Przeczytaj dokładnie 2 strony z korkiem w ustach\n'
                      '4. Staraj się wymawiać słowa jak najwyraźniej\n'
                      '5. Po zakończeniu zaznacz zadanie jako wykonane',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Checkbox zadania
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Checkbox(
                      value: _task?.isCompleted ?? false,
                      onChanged: (_) => _toggleTask(),
                      activeColor: Colors.green,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _task?.title ?? 'Czytanie z korkiem',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              decoration: _task?.isCompleted == true 
                                ? TextDecoration.lineThrough 
                                : null,
                              color: _task?.isCompleted == true 
                                ? Colors.grey 
                                : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _task?.description ?? 'Przeczytaj 2 strony książki z korkiem w ustach',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Dodatkowe informacje
            Card(
              color: Colors.blue.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Wskazówki',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Ćwiczenie to pomaga w poprawie wymowy i artykulacji\n'
                      '• Korek zmusza mięśnie jamy ustnej do większego wysiłku\n'
                      '• Regularne wykonywanie tego ćwiczenia poprawia płynność mowy\n'
                      '• Możesz użyć dowolnej książki - ważne jest czytanie na głos',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            
            const Spacer(),
            
            // Status zadania
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _task?.isCompleted == true 
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _task?.isCompleted == true 
                    ? Colors.green
                    : Colors.orange,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _task?.isCompleted == true 
                      ? Icons.check_circle
                      : Icons.schedule,
                    color: _task?.isCompleted == true 
                      ? Colors.green
                      : Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _task?.isCompleted == true 
                      ? 'Zadanie wykonane!'
                      : 'Zadanie do wykonania',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _task?.isCompleted == true 
                        ? Colors.green
                        : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
