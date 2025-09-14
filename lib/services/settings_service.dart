import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _associationsDurationKey = 'associations_duration';
  static const String _associationsIntervalKey = 'associations_interval';
  static const String _storytellingDurationKey = 'storytelling_duration';
  
  // Domyślne wartości
  static const double _defaultAssociationsDuration = 5.0; // minuty
  static const double _defaultAssociationsInterval = 5.0; // sekundy
  static const double _defaultStorytellingDuration = 5.0; // minuty
  
  // Zapisywanie ustawień skojarzeń
  static Future<void> saveAssociationsSettings({
    required double duration,
    required double interval,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_associationsDurationKey, duration);
    await prefs.setDouble(_associationsIntervalKey, interval);
  }
  
  // Ładowanie ustawień skojarzeń
  static Future<Map<String, double>> getAssociationsSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'duration': prefs.getDouble(_associationsDurationKey) ?? _defaultAssociationsDuration,
      'interval': prefs.getDouble(_associationsIntervalKey) ?? _defaultAssociationsInterval,
    };
  }
  
  // Zapisywanie ustawień opowiadania
  static Future<void> saveStorytellingSettings({
    required double duration,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_storytellingDurationKey, duration);
  }
  
  // Ładowanie ustawień opowiadania
  static Future<double> getStorytellingSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_storytellingDurationKey) ?? _defaultStorytellingDuration;
  }
}
