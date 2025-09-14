import 'package:shared_preferences/shared_preferences.dart';

class StreakService {
  static const String _streakKey = 'daily_streak';
  static const String _lastCompletedDateKey = 'last_completed_date';

  // Pobierz aktualny streak
  static Future<int> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_streakKey) ?? 0;
  }

  // Sprawdź czy dzisiaj zostało wykonane jakieś zadanie
  static Future<bool> hasCompletedTaskToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    final lastCompletedDate = prefs.getString(_lastCompletedDateKey);
    
    return lastCompletedDate == todayKey;
  }

  // Zaktualizuj streak po wykonaniu zadania
  static Future<void> updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    final lastCompletedDate = prefs.getString(_lastCompletedDateKey);
    
    // Jeśli to pierwsze zadanie dzisiaj
    if (lastCompletedDate != todayKey) {
      final yesterday = DateTime(today.year, today.month, today.day - 1);
      final yesterdayKey = '${yesterday.year}-${yesterday.month}-${yesterday.day}';
      
      int currentStreak = prefs.getInt(_streakKey) ?? 0;
      
      // Jeśli wczoraj też było wykonane zadanie, zwiększ streak
      if (lastCompletedDate == yesterdayKey) {
        currentStreak++;
      } else {
        // W przeciwnym razie zacznij nowy streak
        currentStreak = 1;
      }
      
      await prefs.setInt(_streakKey, currentStreak);
      await prefs.setString(_lastCompletedDateKey, todayKey);
    }
  }

  // Sprawdź czy streak powinien być zresetowany (jeśli wczoraj nie było żadnego zadania)
  static Future<void> checkAndResetStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final yesterdayKey = '${yesterday.year}-${yesterday.month}-${yesterday.day}';
    final lastCompletedDate = prefs.getString(_lastCompletedDateKey);
    
    // Jeśli ostatnie zadanie było wykonane przed wczoraj, zresetuj streak
    if (lastCompletedDate != null && lastCompletedDate != yesterdayKey) {
      await prefs.setInt(_streakKey, 0);
    }
  }

  // Pobierz datę ostatniego wykonanego zadania
  static Future<DateTime?> getLastCompletedDate() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCompletedDate = prefs.getString(_lastCompletedDateKey);
    
    if (lastCompletedDate != null) {
      final parts = lastCompletedDate.split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    }
    
    return null;
  }
}
