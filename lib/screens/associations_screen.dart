import 'package:flutter/material.dart';
import 'dart:async';
import '../services/word_service.dart';
import '../services/tts_service.dart';
import '../services/task_service.dart';

class AssociationsScreen extends StatefulWidget {
  const AssociationsScreen({super.key});

  @override
  State<AssociationsScreen> createState() => _AssociationsScreenState();
}

class _AssociationsScreenState extends State<AssociationsScreen> {
  String _currentWord = 'Naciśnij "Generuj" aby rozpocząć';
  bool _isGenerating = false;
  bool _isAutoMode = false;
  Timer? _autoTimer;
  double _autoInterval = 10.0; // sekundy jako double
  int _remainingTime = 0;
  bool _autoCompleteOnFinish = true;
  
  // Timer z odliczaniem wstecznym
  bool _isCountdownMode = false;
  double _countdownDuration = 60.0; // sekundy
  int _countdownRemaining = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    TTSService.initialize();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _generateWord() async {
    if (_isGenerating) return;
    
    setState(() {
      _isGenerating = true;
    });

    try {
      final word = await WordService.getRandomWord();
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

  void _startAutoMode() {
    if (_isAutoMode) return;
    
    setState(() {
      _isAutoMode = true;
      _remainingTime = _autoInterval.round();
    });

    _autoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingTime--;
      });

      if (_remainingTime <= 0) {
        _generateWord();
        _remainingTime = _autoInterval.round();
      }
    });
  }

  void _stopAutoMode() {
    _autoTimer?.cancel();
    setState(() {
      _isAutoMode = false;
      _remainingTime = 0;
    });
  }

  void _startCountdown() {
    if (_isCountdownMode) return;
    
    setState(() {
      _isCountdownMode = true;
      _countdownRemaining = _countdownDuration.round();
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdownRemaining--;
      });

      if (_countdownRemaining <= 0) {
        _finishCountdown();
      }
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _isCountdownMode = false;
      _countdownRemaining = 0;
    });
  }

  Future<void> _finishCountdown() async {
    _countdownTimer?.cancel();
    setState(() {
      _isCountdownMode = false;
      _countdownRemaining = 0;
    });

    // Odtwórz alarm
    await TTSService.playAlarm();

    // Zaznacz zadanie jako wykonane
    if (_autoCompleteOnFinish) {
      final tasks = await TaskService.getTodayTasks();
      try {
        final associationsTask = tasks.firstWhere(
          (task) => task.id == 'associations',
        );
        final updatedTask = associationsTask.copyWith(isCompleted: true);
        await TaskService.updateTask(updatedTask);
      } catch (e) {
        // Jeśli nie znajdzie zadania, nie rób nic
        print('Nie znaleziono zadania skojarzeń: $e');
      }
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
      body: Padding(
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
            
            // Timer dla trybu automatycznego
            if (_isAutoMode) ...[
              Text(
                'Następne słowo za: $_remainingTime s',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
            ],
            
            // Timer z odliczaniem wstecznym
            if (_isCountdownMode) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Pozostały czas:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_countdownRemaining ~/ 60}:${(_countdownRemaining % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
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
                ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generateWord,
                  icon: _isGenerating 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                  label: Text(_isGenerating ? 'Generowanie...' : 'Generuj'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
                
                if (!_isAutoMode && !_isCountdownMode)
                  ElevatedButton.icon(
                    onPressed: _startAutoMode,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Auto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  )
                else if (_isAutoMode)
                  ElevatedButton.icon(
                    onPressed: _stopAutoMode,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop Auto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                
                if (!_isCountdownMode && !_isAutoMode)
                  ElevatedButton.icon(
                    onPressed: _startCountdown,
                    icon: const Icon(Icons.timer),
                    label: const Text('Timer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  )
                else if (_isCountdownMode)
                  ElevatedButton.icon(
                    onPressed: _stopCountdown,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop Timer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Ustawienia
            if (!_isAutoMode && !_isCountdownMode) ...[
              // Ustawienia interwału automatycznego
              const Text('Interwał automatyczny (sekundy):'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _autoInterval > 0.5 ? () {
                      setState(() {
                        _autoInterval -= 0.5;
                      });
                    } : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text(
                    '${_autoInterval.toStringAsFixed(1)} s',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: _autoInterval < 60 ? () {
                      setState(() {
                        _autoInterval += 0.5;
                      });
                    } : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Ustawienia timera z odliczaniem wstecznym
              const Text('Czas timera (sekundy):'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _countdownDuration > 10 ? () {
                      setState(() {
                        _countdownDuration -= 10;
                      });
                    } : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text(
                    '${_countdownDuration.toStringAsFixed(0)} s',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: _countdownDuration < 600 ? () {
                      setState(() {
                        _countdownDuration += 10;
                      });
                    } : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text('Zaznacz zadanie jako wykonane po zakończeniu'),
                value: _autoCompleteOnFinish,
                onChanged: (value) {
                  setState(() {
                    _autoCompleteOnFinish = value ?? true;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
