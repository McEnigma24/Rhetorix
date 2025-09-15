import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

class WordService {
  static List<String>? _words;
  
  static Future<List<String>> _loadWords() async {
    if (_words != null) return _words!;
    
    try {
      final String content = await rootBundle.loadString('assets/words.txt');
      _words = LineSplitter.split(content)
          .where((line) => line.trim().isNotEmpty)
          .toList();
      return _words!;
    } catch (e) {
      return ['Błąd ładowania słów'];
    }
  }
  
  static Future<String> getRandomWord() async {
    final words = await _loadWords();
    if (words.isEmpty) return 'Brak słów';
    
    final random = Random();
    final index = random.nextInt(words.length);
    return words[index];
  }
  
  static Future<List<String>> getAllWords() async {
    return await _loadWords();
  }
}
