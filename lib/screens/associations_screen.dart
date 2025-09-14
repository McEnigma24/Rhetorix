import 'package:flutter/material.dart';
import 'dart:async';
import '../services/word_service.dart';
import '../services/tts_service.dart';

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
  int _autoInterval = 10; // sekundy
  int _remainingTime = 0;

  @override
  void initState() {
    super.initState();
    TTSService.initialize();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
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
      _remainingTime = _autoInterval;
    });

    _autoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingTime--;
      });

      if (_remainingTime <= 0) {
        _generateWord();
        _remainingTime = _autoInterval;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skojarzenia'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Główne słowo
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Center(
                  child: Text(
                    _currentWord,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.center,
                  ),
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
            
            // Kontrolki
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                
                if (!_isAutoMode)
                  ElevatedButton.icon(
                    onPressed: _startAutoMode,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Auto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _stopAutoMode,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Ustawienia interwału
            if (!_isAutoMode) ...[
              const Text('Interwał automatyczny (sekundy):'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _autoInterval > 5 ? () {
                      setState(() {
                        _autoInterval -= 5;
                      });
                    } : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text(
                    '$_autoInterval s',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: _autoInterval < 60 ? () {
                      setState(() {
                        _autoInterval += 5;
                      });
                    } : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
