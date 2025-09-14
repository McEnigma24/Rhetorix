import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  static FlutterTts? _flutterTts;
  
  static FlutterTts get flutterTts {
    _flutterTts ??= FlutterTts();
    return _flutterTts!;
  }
  
  static Future<void> initialize() async {
    await flutterTts.setLanguage("pl-PL");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }
  
  static Future<void> speak(String text) async {
    await flutterTts.speak(text);
  }
  
  static Future<void> stop() async {
    await flutterTts.stop();
  }
  
  static Future<bool> isSpeaking() async {
    // flutter_tts 3.8.5 doesn't have isSpeaking getter
    // Return false as fallback
    return false;
  }
}
