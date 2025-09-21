import 'package:flutter/material.dart';
import 'dart:async';
import '../services/word_service.dart';
import '../services/tts_service.dart';
import '../services/task_service.dart';
import '../services/settings_service.dart';

class AssociationsScreen extends StatefulWidget {
  const AssociationsScreen({super.key});

  @override
  State<AssociationsScreen> createState() => _AssociationsScreenState();
}

class _AssociationsScreenState extends State<AssociationsScreen> {
  String _currentWord = 'Naciśnij "Rozpocznij" aby rozpocząć';
  bool _isGenerating = false;
  bool _isRunning = false;
  
  // Timer główny (całkowity czas ćwiczenia)
  double _totalDuration = 5.0; // minuty
  int _totalRemainingSeconds = 0;
  Timer? _mainTimer;
  
  // Interwał generowania słów
  double _wordInterval = 5.0; // sekundy
  int _wordIntervalMs = 0; // milisekundy
  Timer? _wordTimer;
  
  // Stan ćwiczenia
  String _currentPhase = 'ready'; // ready, running, paused, finished
  
  // Lista wylosowanych słów w bieżącej sesji
  Set<String> _usedWords = <String>{};
  
  // Czas wstrzymania (do obliczenia pozostałego czasu)
  DateTime? _pauseTime;
  int _pausedRemainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    TTSService.initialize();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsService.getAssociationsSettings();
    setState(() {
      _totalDuration = settings['duration']!;
      _wordInterval = settings['interval']!;
      _updateWordIntervalMs();
    });
  }

  @override
  void dispose() {
    _mainTimer?.cancel();
    _wordTimer?.cancel();
    super.dispose();
  }

  void _updateWordIntervalMs() {
    _wordIntervalMs = (_wordInterval * 1000).round();
  }

  Future<void> _saveSettings() async {
    await SettingsService.saveAssociationsSettings(
      duration: _totalDuration,
      interval: _wordInterval,
    );
  }

  Future<void> _generateWord() async {
    if (_isGenerating) return;
    
    setState(() {
      _isGenerating = true;
    });

    try {
      // Pobierz wszystkie dostępne słowa
      final allWords = await WordService.getAllWords();
      
      // Jeśli wszystkie słowa zostały już użyte, wyczyść listę i zacznij od nowa
      if (_usedWords.length >= allWords.length) {
        _usedWords.clear();
      }
      
      // Znajdź słowo, które nie zostało jeszcze użyte
      String word;
      int attempts = 0;
      const maxAttempts = 100; // Zabezpieczenie przed nieskończoną pętlą
      
      do {
        word = await WordService.getRandomWord();
        attempts++;
      } while (_usedWords.contains(word) && attempts < maxAttempts);
      
      // Dodaj słowo do listy użytych
      _usedWords.add(word);
      
      setState(() {
        _currentWord = word;
      });
      await TTSService.speak(word);
    } catch (e) {
      setState(() {
        _currentWord = 'Błąd: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _startExercise() {
    if (_isRunning) return;
    
    setState(() {
      _isRunning = true;
      _currentPhase = 'running';
      _totalRemainingSeconds = (_totalDuration * 60).round();
      // Wyczyść listę użytych słów przy rozpoczęciu nowej sesji
      _usedWords.clear();
    });

    // Timer główny - odlicza całkowity czas
    _mainTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _totalRemainingSeconds--;
      });

      if (_totalRemainingSeconds <= 0) {
        _finishExercise();
      }
    });

    // Timer słów - generuje nowe słowa według interwału
    _wordTimer = Timer.periodic(Duration(milliseconds: _wordIntervalMs), (timer) {
      if (_isRunning) {
        _generateWord();
      }
    });

    // Wygeneruj pierwsze słowo natychmiast
    _generateWord();
  }

  void _pauseExercise() {
    _mainTimer?.cancel();
    _wordTimer?.cancel();
    setState(() {
      _isRunning = false;
      _currentPhase = 'paused';
      _pauseTime = DateTime.now();
      _pausedRemainingSeconds = _totalRemainingSeconds;
    });
  }

  void _resumeExercise() {
    if (_isRunning) return;
    
    setState(() {
      _isRunning = true;
      _currentPhase = 'running';
      // Przywróć pozostały czas z momentu wstrzymania
      _totalRemainingSeconds = _pausedRemainingSeconds;
    });

    // Timer główny - odlicza całkowity czas
    _mainTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _totalRemainingSeconds--;
      });

      if (_totalRemainingSeconds <= 0) {
        _finishExercise();
      }
    });

    // Timer słów - generuje nowe słowa według interwału
    _wordTimer = Timer.periodic(Duration(milliseconds: _wordIntervalMs), (timer) {
      if (_isRunning) {
        _generateWord();
      }
    });
  }

  void _resetExercise() {
    _mainTimer?.cancel();
    _wordTimer?.cancel();
    setState(() {
      _isRunning = false;
      _currentPhase = 'ready';
      _totalRemainingSeconds = 0;
      _currentWord = 'Naciśnij "Rozpocznij" aby rozpocząć';
      // Wyczyść listę użytych słów przy resecie
      _usedWords.clear();
      _pauseTime = null;
      _pausedRemainingSeconds = 0;
    });
  }

  Future<void> _finishExercise() async {
    _mainTimer?.cancel();
    _wordTimer?.cancel();
    setState(() {
      _isRunning = false;
      _currentPhase = 'finished';
      _totalRemainingSeconds = 0;
    });

    // Odtwórz alarm
    await TTSService.playAlarm();

    // Zaznacz zadanie jako wykonane
    final tasks = await TaskService.getTodayTasks();
    try {
      final associationsTask = tasks.firstWhere(
        (task) => task.id == 'associations',
      );
      final updatedTask = associationsTask.copyWith(isCompleted: true);
      await TaskService.updateTask(updatedTask);
    } catch (e) {
      // Nie znaleziono zadania skojarzeń
    }

    // Pokaż dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ćwiczenie zakończone!'),
          content: const Text('Timer dobiegł końca. Ćwiczenie zostało automatycznie zaznaczone jako wykonane.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skojarzenia'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
            // Główne słowo - mniejszy kontener
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Center(
                child: Text(
                  _currentWord,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Timer główny
            if (_isRunning || _currentPhase == 'finished' || _currentPhase == 'paused') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _currentPhase == 'running' 
                    ? Colors.orange.withOpacity(0.1)
                    : _currentPhase == 'paused'
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _currentPhase == 'running' 
                      ? Colors.orange
                      : _currentPhase == 'paused'
                        ? Colors.blue
                        : Colors.green,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _currentPhase == 'running' 
                        ? 'Pozostały czas:'
                        : _currentPhase == 'paused'
                          ? 'Wstrzymano:'
                          : 'Ćwiczenie zakończone!',
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                        color: _currentPhase == 'running' 
                          ? Colors.orange
                          : _currentPhase == 'paused'
                            ? Colors.blue
                            : Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentPhase == 'finished'
                        ? '00:00'
                        : '${_totalRemainingSeconds ~/ 60}:${(_totalRemainingSeconds % 60).toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _currentPhase == 'running' 
                          ? Colors.orange
                          : _currentPhase == 'paused'
                            ? Colors.blue
                            : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Kontrolki
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (_currentPhase == 'ready')
                  ElevatedButton.icon(
                    onPressed: _startExercise,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Rozpocznij'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  )
                else if (_currentPhase == 'running') ...[
                  ElevatedButton.icon(
                    onPressed: _pauseExercise,
                    icon: const Icon(Icons.pause),
                    label: const Text('Wstrzymaj'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _resetExercise,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ]
                else if (_currentPhase == 'paused') ...[
                  ElevatedButton.icon(
                    onPressed: _resumeExercise,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Wznów'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _resetExercise,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ]
                else if (_currentPhase == 'finished')
                  ElevatedButton.icon(
                    onPressed: _resetExercise,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Rozpocznij nowe'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Ustawienia
            if (_currentPhase == 'ready' || _currentPhase == 'paused') ...[
              // Ustawienia czasu ćwiczenia
              const Text('Czas ćwiczenia (minuty):'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _totalDuration > 0.5 ? () {
                      setState(() {
                        _totalDuration -= 0.5;
                        // Jeśli jesteśmy w trakcie wstrzymania, zaktualizuj pozostały czas
                        if (_currentPhase == 'paused') {
                          _pausedRemainingSeconds = (_totalDuration * 60).round();
                        }
                      });
                      _saveSettings();
                    } : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text(
                    '${_totalDuration.toStringAsFixed(1)} min',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: _totalDuration < 30 ? () {
                      setState(() {
                        _totalDuration += 0.5;
                        // Jeśli jesteśmy w trakcie wstrzymania, zaktualizuj pozostały czas
                        if (_currentPhase == 'paused') {
                          _pausedRemainingSeconds = (_totalDuration * 60).round();
                        }
                      });
                      _saveSettings();
                    } : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Ustawienia interwału słów
              const Text('Interwał słów (sekundy):'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _wordInterval > 0.1 ? () {
                      setState(() {
                        _wordInterval -= 0.1;
                        _updateWordIntervalMs();
                      });
                      _saveSettings();
                    } : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text(
                    '${_wordInterval.toStringAsFixed(1)} s',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: _wordInterval < 60 ? () {
                      setState(() {
                        _wordInterval += 0.1;
                        _updateWordIntervalMs();
                      });
                      _saveSettings();
                    } : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Dokładność: ${_wordIntervalMs} ms',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }
}
