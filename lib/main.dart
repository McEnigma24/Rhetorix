import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicjalizacja notyfikacji
  await NotificationService.initialize();
  
  // Sprawdź i zaplanuj powiadomienia przy starcie aplikacji
  await _checkAndScheduleNotifications();
  
  runApp(const RhetorixApp());
}

// Sprawdź i zaplanuj powiadomienia przy starcie aplikacji
Future<void> _checkAndScheduleNotifications() async {
  try {
    print('DEBUG: [main] Sprawdzam ustawienia powiadomień...');
    
    final settings = await NotificationService.getNotificationSettings();
    final enabled = settings['enabled'] ?? false;
    final hour = settings['hour'] ?? 20;
    final minute = settings['minute'] ?? 0;
    
    print('DEBUG: [main] Ustawienia powiadomień: enabled=$enabled, hour=$hour, minute=$minute');
    
    if (enabled) {
      print('DEBUG: [main] Powiadomienia są włączone - planuję na $hour:$minute');
      await NotificationService.scheduleDailyReminder(hour, minute);
    } else {
      print('DEBUG: [main] Powiadomienia są wyłączone');
    }
    
    // Debug: Pokaż zaplanowane powiadomienia
    await NotificationService.debugShowScheduledNotifications();
    
  } catch (e) {
    print('DEBUG: [main] Błąd podczas sprawdzania powiadomień: $e');
  }
}

class RhetorixApp extends StatelessWidget {
  const RhetorixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rhetorix',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      routes: {
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
