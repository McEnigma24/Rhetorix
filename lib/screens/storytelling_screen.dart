import 'package:flutter/material.dart';
import 'dart:async';
import '../services/task_service.dart';
import '../services/tts_service.dart';
import '../services/settings_service.dart';
import '../models/daily_task.dart';

class StorytellingScreen extends StatefulWidget {
  const StorytellingScreen({super.key});

  @override
  State<StorytellingScreen> createState() => _StorytellingScreenState();
}

class _StorytellingScreenState extends State<StorytellingScreen> {
  DailyTask? _task;
  bool _isLoading = true;
  bool _isRunning = false;
  double _duration = 5.0; // minuty jako double
  int _remainingSeconds = 0;
  Timer? _timer;
  String _currentPhase = 'ready'; // ready, running, finished

  @override
  void initState() {
    super.initState();
    TTSService.initialize();
    _loadTask();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final duration = await SettingsService.getStorytellingSettings();
    setState(() {
      _duration = duration;
      _remainingSeconds = (_duration * 60).round();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadTask() async {
    final tasks = await TaskService.getTodayTasks();
    final storytellingTask = tasks.firstWhere(
      (task) => task.id == 'storytelling',
      orElse: () => DailyTask(
        id: 'storytelling',
        title: 'Opowiadanie historii',
        description: 'Opowiadaj historię przez 5 minut bez przerywników',
        date: DateTime.now(),
      ),
    );
    
    setState(() {
      _task = storytellingTask;
      _isLoading = false;
    });
  }

  void _startTimer() {
    if (_isRunning) return;
    
    setState(() {
      _isRunning = true;
      _remainingSeconds = (_duration * 60).round();
      _currentPhase = 'running';
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        _finishTimer();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _currentPhase = 'paused';
    });
  }

  Future<void> _finishTimer() async {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _currentPhase = 'finished';
    });
    
    // Odtwórz alarm
    await TTSService.playAlarm();
    
    // Zaznacz zadanie jako wykonane
    await _markTaskAsCompleted();
  }

  Future<void> _markTaskAsCompleted() async {
    if (_task == null) return;
    
    final updatedTask = _task!.copyWith(isCompleted: true);
    await TaskService.updateTask(updatedTask);
    
    setState(() {
      _task = updatedTask;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = (_duration * 60).round();
      _currentPhase = 'ready';
    });
  }

  void _resumeTimer() {
    if (_isRunning) return;
    
    setState(() {
      _isRunning = true;
      _currentPhase = 'running';
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        _finishTimer();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _saveSettings() async {
    await SettingsService.saveStorytellingSettings(duration: _duration);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Opowiadanie historii'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
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
                          Icons.mic,
                          color: Colors.orange,
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
                      '1. Naciśnij "Start" aby rozpocząć 5-minutowe opowiadanie\n'
                      '2. Opowiadaj dowolną historię na głos\n'
                      '3. Staraj się unikać przerywników: "e", "a", "o", "u"\n'
                      '4. Używaj bogatego słownictwa i dbaj o płynność\n'
                      '5. Po zakończeniu zadanie zostanie automatycznie zaznaczone',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Timer
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: _currentPhase == 'running' 
                  ? Colors.orange.withOpacity(0.1)
                  : _currentPhase == 'finished'
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _currentPhase == 'running' 
                    ? Colors.orange
                    : _currentPhase == 'finished'
                      ? Colors.green
                      : Colors.grey,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _currentPhase == 'running' 
                      ? Icons.mic
                      : _currentPhase == 'finished'
                        ? Icons.check_circle
                        : Icons.timer,
                    size: 48,
                    color: _currentPhase == 'running' 
                      ? Colors.orange
                      : _currentPhase == 'finished'
                        ? Colors.green
                        : Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _formatTime(_remainingSeconds),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: _currentPhase == 'running' 
                        ? Colors.orange
                        : _currentPhase == 'finished'
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentPhase == 'running' 
                      ? 'Opowiadaj historię...'
                      : _currentPhase == 'finished'
                        ? 'Zakończone!'
                        : 'Gotowy do startu',
                    style: TextStyle(
                      fontSize: 18,
                      color: _currentPhase == 'running' 
                        ? Colors.orange
                        : _currentPhase == 'finished'
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Kontrolki
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (_currentPhase == 'ready')
                  ElevatedButton.icon(
                    onPressed: _startTimer,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                
                if (_currentPhase == 'running')
                  ElevatedButton.icon(
                    onPressed: _stopTimer,
                    icon: const Icon(Icons.pause),
                    label: const Text('Wstrzymaj'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                
                if (_currentPhase == 'paused')
                  ElevatedButton.icon(
                    onPressed: _resumeTimer,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Wznów'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                
                if (_currentPhase == 'paused' || _currentPhase == 'finished')
                  ElevatedButton.icon(
                    onPressed: _resetTimer,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Ustawienia czasu
            if (_currentPhase == 'ready') ...[
              const Text('Czas trwania (minuty):'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _duration > 0.5 ? () {
                      setState(() {
                        _duration -= 0.5;
                        _remainingSeconds = (_duration * 60).round();
                      });
                      _saveSettings();
                    } : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text(
                    '${_duration.toStringAsFixed(1)} min',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: _duration < 30 ? () {
                      setState(() {
                        _duration += 0.5;
                        _remainingSeconds = (_duration * 60).round();
                      });
                      _saveSettings();
                    } : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
            
            const Spacer(),
          ],
        ),
        ),
      ),
    );
  }
}
