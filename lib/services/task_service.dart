import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/daily_task.dart';
import 'streak_service.dart';

class TaskService {
  static const String _tasksKey = 'daily_tasks';
  
  static Future<List<DailyTask>> getTodayTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    
    print('📋 getTodayTasks() - szukam zadań dla $todayKey');
    final tasksJson = prefs.getString('${_tasksKey}_$todayKey');
    if (tasksJson != null) {
      print('📋 Znaleziono zapisane zadania: $tasksJson');
      final List<dynamic> tasksList = json.decode(tasksJson);
      final tasks = tasksList.map((json) => DailyTask.fromJson(json)).toList();
      for (var task in tasks) {
        print('  - ${task.title}: ${task.isCompleted ? "✅" : "❌"}');
      }
      return tasks;
    }
    
    // Tworzenie domyślnych zadań na dzisiaj TYLKO jeśli nie ma zapisanych zadań
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
    
    // Zapisz domyślne zadania tylko raz
    await saveTasks(defaultTasks);
    return defaultTasks;
  }
  
  static Future<void> saveTasks(List<DailyTask> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    
    print('💾 saveTasks() - zapisuję zadania dla $todayKey');
    for (var task in tasks) {
      print('  - ${task.title}: ${task.isCompleted ? "✅" : "❌"}');
    }
    
    final tasksJson = json.encode(tasks.map((task) => task.toJson()).toList());
    await prefs.setString('${_tasksKey}_$todayKey', tasksJson);
    print('💾 Zadania zapisane: $tasksJson');
  }
  
  static Future<void> updateTask(DailyTask task) async {
    print('🔄 updateTask() - aktualizuję zadanie: ${task.title} (${task.isCompleted ? "✅" : "❌"})');
    final tasks = await getTodayTasks();
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      print('🔄 Znaleziono zadanie na pozycji $index, aktualizuję...');
      tasks[index] = task;
      await saveTasks(tasks);
      
      // Aktualizuj streak jeśli zadanie zostało ukończone
      if (task.isCompleted) {
        await StreakService.updateStreak();
      }
    } else {
      print('❌ Nie znaleziono zadania: ${task.id}');
    }
  }
}
