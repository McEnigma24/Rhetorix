import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CalendarService {
  static const String _calendarDataKey = 'calendar_data';
  
  // Pobierz dane zadań dla konkretnego dnia
  static Future<Map<String, bool>> getDayTasks(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = _getDateKey(date);
    final data = prefs.getString('${_calendarDataKey}_$dateKey');
    
    if (data != null) {
      final Map<String, dynamic> jsonData = json.decode(data);
      return Map<String, bool>.from(jsonData);
    }
    
    return {
      'associations': false,
      'reading': false,
      'storytelling': false,
    };
  }
  
  // Zapisz dane zadań dla konkretnego dnia
  static Future<void> saveDayTasks(DateTime date, Map<String, bool> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = _getDateKey(date);
    final data = json.encode(tasks);
    await prefs.setString('${_calendarDataKey}_$dateKey', data);
  }
  
  // Oznacz zadanie jako wykonane w konkretnym dniu
  static Future<void> markTaskCompleted(DateTime date, String taskId) async {
    final tasks = await getDayTasks(date);
    tasks[taskId] = true;
    await saveDayTasks(date, tasks);
  }
  
  // Sprawdź czy w danym dniu były wykonane jakieś zadania
  static Future<bool> hasCompletedTasks(DateTime date) async {
    final tasks = await getDayTasks(date);
    return tasks.values.any((completed) => completed);
  }
  
  // Pobierz wszystkie dni z wykonanymi zadaniami w danym miesiącu
  static Future<List<int>> getCompletedDaysInMonth(DateTime month) async {
    final prefs = await SharedPreferences.getInstance();
    final monthKey = '${month.year}-${month.month}';
    final data = prefs.getString('${_calendarDataKey}_month_$monthKey');
    
    if (data != null) {
      final List<dynamic> jsonData = json.decode(data);
      return jsonData.cast<int>();
    }
    
    return [];
  }
  
  // Pobierz zadania dla konkretnego dnia w miesiącu
  static Future<Map<String, bool>> getDayTasksInMonth(DateTime month, int day) async {
    final date = DateTime(month.year, month.month, day);
    return await getDayTasks(date);
  }
  
  // Zapisz dzień z wykonanymi zadaniami w danym miesiącu
  static Future<void> saveCompletedDayInMonth(DateTime date) async {
    final month = DateTime(date.year, date.month);
    final monthKey = '${month.year}-${month.month}';
    final completedDays = await getCompletedDaysInMonth(month);
    
    if (!completedDays.contains(date.day)) {
      completedDays.add(date.day);
      completedDays.sort();
      
      final prefs = await SharedPreferences.getInstance();
      final data = json.encode(completedDays);
      await prefs.setString('${_calendarDataKey}_month_$monthKey', data);
    }
  }
  
  // Pobierz statystyki dla miesiąca
  static Future<Map<String, int>> getMonthStats(DateTime month) async {
    final completedDays = await getCompletedDaysInMonth(month);
    int totalCompletedDays = completedDays.length;
    
    // Policz ile zadań zostało wykonanych w tym miesiącu
    int totalTasks = 0;
    for (int day in completedDays) {
      final date = DateTime(month.year, month.month, day);
      final dayTasks = await getDayTasks(date);
      totalTasks += dayTasks.values.where((completed) => completed).length;
    }
    
    return {
      'completedDays': totalCompletedDays,
      'totalTasks': totalTasks,
    };
  }
  
  static String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
