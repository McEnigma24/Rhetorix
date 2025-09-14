import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/daily_task.dart';

class TaskService {
  static const String _tasksKey = 'daily_tasks';
  
  static Future<List<DailyTask>> getTodayTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    
    final tasksJson = prefs.getString('${_tasksKey}_$todayKey');
    if (tasksJson != null) {
      final List<dynamic> tasksList = json.decode(tasksJson);
      return tasksList.map((json) => DailyTask.fromJson(json)).toList();
    }
    
    // Tworzenie domyślnych zadań na dzisiaj
    final defaultTasks = [
      DailyTask(
        id: 'associations',
        title: 'Skojarzenia',
        description: 'Generuj słowa i mów skojarzenia',
        date: today,
      ),
      DailyTask(
        id: 'reading',
        title: 'Czytanie z korkiem',
        description: 'Przeczytaj 2 strony książki z korkiem w ustach',
        date: today,
      ),
      DailyTask(
        id: 'storytelling',
        title: 'Opowiadanie historii',
        description: 'Opowiadaj historię przez 5 minut bez przerywników',
        date: today,
      ),
    ];
    
    await saveTasks(defaultTasks);
    return defaultTasks;
  }
  
  static Future<void> saveTasks(List<DailyTask> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    
    final tasksJson = json.encode(tasks.map((task) => task.toJson()).toList());
    await prefs.setString('${_tasksKey}_$todayKey', tasksJson);
  }
  
  static Future<void> updateTask(DailyTask task) async {
    final tasks = await getTodayTasks();
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      tasks[index] = task;
      await saveTasks(tasks);
    }
  }
}
