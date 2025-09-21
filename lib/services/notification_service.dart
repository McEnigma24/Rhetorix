import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Klucze dla SharedPreferences
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _notificationHourKey = 'notification_hour';
  static const String _notificationMinuteKey = 'notification_minute';

  // Inicjalizacja serwisu notyfikacji
  static Future<void> initialize() async {
    if (_initialized) return;

    print('DEBUG: [NotificationService] Inicjalizuję serwis notyfikacji...');

    // Inicjalizuj timezone
    print('DEBUG: [NotificationService] Inicjalizuję timezone...');
    tz.initializeTimeZones();
    
    // Ustaw lokalną strefę czasową
    try {
      final location = tz.getLocation('Europe/Warsaw'); // Domyślnie Polska
      tz.setLocalLocation(location);
      print('DEBUG: [NotificationService] Timezone ustawiony na: $location');
    } catch (e) {
      print('DEBUG: [NotificationService] Błąd ustawiania timezone: $e');
      // Fallback do systemowej strefy czasowej
      try {
        final systemLocation = tz.local;
        print('DEBUG: [NotificationService] Używam systemowej strefy czasowej: $systemLocation');
      } catch (e2) {
        print('DEBUG: [NotificationService] Błąd pobierania systemowej strefy czasowej: $e2');
      }
    }

    // Ustawienia dla Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Ustawienia dla iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Połącz ustawienia
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Inicjalizuj plugin
    print('DEBUG: [NotificationService] Inicjalizuję plugin z callback...');
    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    print('DEBUG: [NotificationService] Plugin zainicjalizowany pomyślnie');
    
    // Utwórz kanały notyfikacji z odpowiednimi ustawieniami
    await _createNotificationChannels();
    
    _initialized = true;
  }

  // Utwórz kanały notyfikacji z odpowiednimi ustawieniami
  static Future<void> _createNotificationChannels() async {
    try {
      print('DEBUG: [NotificationService] Tworzę kanały notyfikacji...');
      
      // Kanał dla notyfikacji o zadaniach Rhetorix
      const AndroidNotificationChannel rhetorixChannel = AndroidNotificationChannel(
        'rhetorix_channel',
        'Rhetorix',
        description: 'Powiadomienia o zadaniach Rhetorix',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
        enableLights: false,
      );
      
      // Utwórz kanały
      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(rhetorixChannel);
      
      print('DEBUG: [NotificationService] Kanały notyfikacji zostały utworzone pomyślnie');
      
    } catch (e) {
      print('Error creating notification channels: $e');
    }
  }

  // Obsługa kliknięcia w notyfikację
  static void _onNotificationTapped(NotificationResponse response) async {
    print('DEBUG: [NotificationService] ===== NOTYFIKACJA KLIKNIĘTA =====');
    print('DEBUG: [NotificationService] Notification tapped: ${response.payload}');
    print('DEBUG: [NotificationService] Notification ID: ${response.id}');
    print('DEBUG: [NotificationService] Notification action: ${response.actionId}');
    
    // Obsługa różnych typów notyfikacji
    switch (response.payload) {
      case 'rhetorix_daily_reminder':
        print('DEBUG: [NotificationService] Obsługuję notyfikację o zadaniach Rhetorix...');
        // Tutaj można dodać nawigację do głównego ekranu
        break;
        
      case 'rhetorix_test_notification':
        print('DEBUG: [NotificationService] Obsługuję testową notyfikację natychmiastową');
        break;
        
      case 'rhetorix_test_notification_10s':
        print('DEBUG: [NotificationService] Obsługuję testową notyfikację za 10 sekund');
        break;
        
      default:
        print('DEBUG: [NotificationService] Nieznany typ notyfikacji: ${response.payload}');
        break;
    }
    
    print('DEBUG: [NotificationService] ===== KONIEC OBSŁUGI NOTYFIKACJI =====');
  }

  // Ustaw codzienną notyfikację o zadaniach Rhetorix
  static Future<void> scheduleDailyReminder(int hour, int minute) async {
    if (!_initialized) await initialize();

    try {
      // Sprawdź uprawnienia przed planowaniem notyfikacji
      final status = await getDetailedPermissionStatus();
      final canSchedule = status['system_permissions'] ?? false;
      
      if (!canSchedule) {
        throw Exception('Brak uprawnień do planowania notyfikacji');
      }

      // Anuluj poprzednie notyfikacje
      await cancelDailyReminder();

      // Oblicz czas do następnej notyfikacji
      final scheduledTime = _nextInstanceOfTime(hour, minute);
      
      print('DEBUG: Planuję notyfikację Rhetorix na: $scheduledTime');

      // Użyj zonedSchedule dla działania w tle
      await _notifications.zonedSchedule(
        1, // ID notyfikacji
        'Czas na Rhetorix! 🔥',
        'Nie zapomnij o dzisiejszych zadaniach - utrzymaj swój streak!',
        scheduledTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'rhetorix_channel',
            'Rhetorix',
            channelDescription: 'Powiadomienia o zadaniach Rhetorix',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
            sound: null, // Użyj domyślnego dźwięku systemowego
            category: AndroidNotificationCategory.reminder,
            visibility: NotificationVisibility.public,
            channelShowBadge: true,
            showWhen: true,
            when: 0,
            autoCancel: true,
            ongoing: false,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'rhetorix_daily_reminder',
      );
      
      print('DEBUG: Notyfikacja Rhetorix została zaplanowana pomyślnie (zonedSchedule)');
    } catch (e) {
      print('Error scheduling Rhetorix notification: $e');
      rethrow;
    }
  }

  // Anuluj notyfikacje o zadaniach Rhetorix
  static Future<void> cancelDailyReminder() async {
    if (!_initialized) await initialize();
    await _notifications.cancel(1);
  }

  // Oblicz następny czas o podanej godzinie
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    print('DEBUG: Aktualny czas: $now');
    print('DEBUG: Planowany czas dzisiaj: $scheduledDate');
    
    // Jeśli czas już minął dzisiaj, ustaw na jutro
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
      print('DEBUG: Czas minął dzisiaj, ustawiam na jutro: $scheduledDate');
    } else {
      print('DEBUG: Czas jeszcze nie minął, ustawiam na dzisiaj: $scheduledDate');
    }
    
    return scheduledDate;
  }

  // Test: Wyślij notyfikację natychmiast
  static Future<void> sendTestNotification() async {
    print('DEBUG: [NotificationService] Rozpoczynam sendTestNotification...');
    
    if (!_initialized) {
      print('DEBUG: [NotificationService] Inicjalizuję serwis...');
      await initialize();
    }

    try {
      print('DEBUG: [NotificationService] Sprawdzam uprawnienia...');
      final status = await getDetailedPermissionStatus();
      final canShow = status['system_permissions'] ?? false;
      
      print('DEBUG: [NotificationService] Status uprawnień: $status');
      print('DEBUG: [NotificationService] canShow: $canShow');
      
      if (!canShow) {
        print('DEBUG: [NotificationService] BŁĄD: Brak uprawnień systemowych');
        throw Exception('Brak uprawnień do wyświetlania notyfikacji');
      }

      // Wyślij natychmiastową notyfikację testową
      await _notifications.show(
        999, // ID testowej notyfikacji
        'Test: Czas na Rhetorix! 🔥',
        'To jest testowa notyfikacja Rhetorix',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'rhetorix_channel',
            'Rhetorix',
            channelDescription: 'Powiadomienia o zadaniach Rhetorix',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
            sound: null,
            category: AndroidNotificationCategory.reminder,
            visibility: NotificationVisibility.public,
            autoCancel: true,
            ongoing: false,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: 'rhetorix_test_notification',
      );
      
      print('DEBUG: [NotificationService] Natychmiastowa notyfikacja wysłana pomyślnie');
    } catch (e) {
      print('DEBUG: [NotificationService] BŁĄD podczas sendTestNotification: $e');
      rethrow;
    }
  }

  // Test: Wyślij notyfikację za 10 sekund
  static Future<void> sendTestNotificationIn10Seconds() async {
    print('DEBUG: [NotificationService] Rozpoczynam sendTestNotificationIn10Seconds...');
    
    if (!_initialized) {
      print('DEBUG: [NotificationService] Inicjalizuję serwis...');
      await initialize();
    }

    try {
      // Anuluj poprzednie testowe notyfikacje
      print('DEBUG: [NotificationService] Anuluję poprzednie testowe notyfikacje...');
      await _notifications.cancel(998);
      
      print('DEBUG: [NotificationService] Sprawdzam uprawnienia systemowe...');
      final status = await getDetailedPermissionStatus();
      final canShow = status['system_permissions'] ?? false;
      
      if (!canShow) {
        print('DEBUG: [NotificationService] BŁĄD: Brak uprawnień systemowych');
        throw Exception('Brak uprawnień do wyświetlania notyfikacji');
      }

      // Sprawdź uprawnienia do dokładnych alarmów
      final canScheduleExact = await canScheduleExactAlarms();
      print('DEBUG: [NotificationService] canScheduleExact: $canScheduleExact');
      
      if (!canScheduleExact) {
        print('DEBUG: [NotificationService] BŁĄD: Brak uprawnień do dokładnych alarmów');
        throw Exception('Brak uprawnień do dokładnych alarmów (Android 12+)');
      }

      // Oblicz czas planowania (za 10 sekund)
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      final tz.TZDateTime scheduledTime = now.add(const Duration(seconds: 10));
      
      print('DEBUG: [NotificationService] Obliczam czas planowania...');
      print('DEBUG: [NotificationService] Aktualny czas: $now');
      print('DEBUG: [NotificationService] Planowany czas: $scheduledTime');
      print('DEBUG: [NotificationService] Różnica czasowa: ${scheduledTime.difference(now).inSeconds} sekund');
      
      // Użyj zonedSchedule dla działania w tle
      await _notifications.zonedSchedule(
        998, // ID testowej notyfikacji
        'Test: Czas na Rhetorix! (za 10s) 🔥',
        'To jest testowa notyfikacja Rhetorix za 10 sekund',
        scheduledTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'rhetorix_channel',
            'Rhetorix',
            channelDescription: 'Powiadomienia o zadaniach Rhetorix',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
            sound: null,
            channelShowBadge: true,
            showWhen: true,
            when: 0,
            category: AndroidNotificationCategory.reminder,
            visibility: NotificationVisibility.public,
            autoCancel: true,
            ongoing: false,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'rhetorix_test_notification_10s',
      );
      
      print('DEBUG: [NotificationService] Testowa notyfikacja za 10 sekund zaplanowana (zonedSchedule)');
      
    } catch (e) {
      print('DEBUG: [NotificationService] BŁĄD podczas sendTestNotificationIn10Seconds: $e');
      rethrow;
    }
  }

  // Sprawdź czy notyfikacje są włączone
  static Future<bool> areNotificationsEnabled() async {
    if (!_initialized) await initialize();
    
    final bool? result = await _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.areNotificationsEnabled();
    
    return result ?? false;
  }

  // Poproś o uprawnienia (iOS)
  static Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();
    
    final bool? result = await _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    
    return result ?? false;
  }

  // Poproś o uprawnienia (Android)
  static Future<bool> requestAndroidPermissions() async {
    if (!_initialized) await initialize();
    
    final bool? result = await _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    
    return result ?? false;
  }

  // Sprawdź status uprawnień z szczegółami
  static Future<Map<String, bool>> getDetailedPermissionStatus() async {
    if (!_initialized) await initialize();
    
    final Map<String, bool> status = {};
    
    try {
      // Sprawdź uprawnienia Android
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        status['android_permissions'] = await androidPlugin.areNotificationsEnabled() ?? false;
      } else {
        status['android_permissions'] = false;
      }
      
      // Sprawdź czy można wyświetlać notyfikacje
      status['can_show_notifications'] = await canShowNotifications();
      
      // Sprawdź czy aplikacja ma uprawnienia systemowe
      status['system_permissions'] = (status['android_permissions'] ?? false) && (status['can_show_notifications'] ?? false);
      
    } catch (e) {
      print('Error getting detailed permission status: $e');
      status['android_permissions'] = false;
      status['can_show_notifications'] = false;
      status['system_permissions'] = false;
    }
    
    return status;
  }

  // Sprawdź czy aplikacja może wyświetlać notyfikacje
  static Future<bool> canShowNotifications() async {
    if (!_initialized) await initialize();
    
    try {
      // Spróbuj wyświetlić testową notyfikację
      await _notifications.show(
        998, // ID testowej notyfikacji
        'Test',
        'Test',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test',
            channelDescription: 'Test',
            importance: Importance.min,
            priority: Priority.min,
          ),
        ),
      );
      
      // Jeśli się udało, anuluj ją
      await _notifications.cancel(998);
      return true;
    } catch (e) {
      print('Cannot show notifications: $e');
      return false;
    }
  }

  // Sprawdź uprawnienia do dokładnych alarmów (Android 12+)
  static Future<bool> canScheduleExactAlarms() async {
    try {
      final status = await Permission.scheduleExactAlarm.status;
      return status.isGranted;
    } catch (e) {
      print('Error checking exact alarm permissions: $e');
      return false;
    }
  }

  // Poproś o uprawnienia do dokładnych alarmów
  static Future<bool> requestExactAlarmPermission() async {
    try {
      final status = await Permission.scheduleExactAlarm.request();
      return status.isGranted;
    } catch (e) {
      print('Error requesting exact alarm permissions: $e');
      return false;
    }
  }

  // Sprawdź czy aplikacja może ignorować optymalizację baterii
  static Future<bool> canIgnoreBatteryOptimization() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      return status.isGranted;
    } catch (e) {
      print('Error checking battery optimization permission: $e');
      return false;
    }
  }

  // Poproś o uprawnienia do ignorowania optymalizacji baterii
  static Future<bool> requestIgnoreBatteryOptimization() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.request();
      return status.isGranted;
    } catch (e) {
      print('Error requesting battery optimization permission: $e');
      return false;
    }
  }

  // Sprawdź wszystkie uprawnienia i zwróć szczegółowy status
  static Future<Map<String, dynamic>> checkAllPermissions() async {
    if (!_initialized) await initialize();
    
    final Map<String, dynamic> status = {};
    
    try {
      // Sprawdź podstawowe uprawnienia do notyfikacji
      final basicStatus = await getDetailedPermissionStatus();
      status.addAll(basicStatus);
      
      // Sprawdź uprawnienia do dokładnych alarmów
      status['exact_alarm_permissions'] = await canScheduleExactAlarms();
      
      // Sprawdź uprawnienia do ignorowania optymalizacji baterii
      status['battery_optimization_permissions'] = await canIgnoreBatteryOptimization();
      
      // Sprawdź czy można planować notyfikacje
      status['can_schedule_notifications'] = (status['system_permissions'] ?? false) && 
                                            (status['exact_alarm_permissions'] ?? false) &&
                                            (status['battery_optimization_permissions'] ?? false);
      
      // Dodaj komunikaty o problemach
      final List<String> issues = [];
      
      if (!(status['android_permissions'] ?? false)) {
        issues.add('Brak uprawnień do notyfikacji w systemie Android');
      }
      
      if (!(status['can_show_notifications'] ?? false)) {
        issues.add('Aplikacja nie może wyświetlać notyfikacji');
      }
      
      if (!(status['exact_alarm_permissions'] ?? false)) {
        issues.add('Brak uprawnień do dokładnych alarmów (Android 12+)');
      }
      
      if (!(status['battery_optimization_permissions'] ?? false)) {
        issues.add('Aplikacja nie może ignorować optymalizacji baterii');
      }
      
      status['issues'] = issues;
      status['has_issues'] = issues.isNotEmpty;
      
    } catch (e) {
      print('Error checking all permissions: $e');
      status['has_issues'] = true;
      status['issues'] = ['Błąd podczas sprawdzania uprawnień: $e'];
    }
    
    return status;
  }

  // Automatyczne żądanie wszystkich potrzebnych uprawnień
  static Future<Map<String, bool>> requestAllPermissionsAutomatically() async {
    if (!_initialized) await initialize();
    
    final Map<String, bool> results = {};
    
    try {
      print('DEBUG: [NotificationService] Automatycznie żądam wszystkich uprawnień...');
      
      // 1. Podstawowe uprawnienia do notyfikacji
      print('DEBUG: [NotificationService] Żądam uprawnień do notyfikacji...');
      final notificationResult = await requestAndroidPermissions();
      results['notifications'] = notificationResult;
      
      // 2. Uprawnienia do dokładnych alarmów (Android 12+)
      print('DEBUG: [NotificationService] Żądam uprawnień do dokładnych alarmów...');
      final exactAlarmResult = await requestExactAlarmPermission();
      results['exact_alarms'] = exactAlarmResult;
      
      // 3. Uprawnienia do ignorowania optymalizacji baterii
      print('DEBUG: [NotificationService] Żądam uprawnień do ignorowania optymalizacji baterii...');
      final batteryResult = await requestIgnoreBatteryOptimization();
      results['battery_optimization'] = batteryResult;
      
      // 4. Sprawdź czy wszystkie uprawnienia zostały przyznane
      final allGranted = results.values.every((granted) => granted);
      results['all_granted'] = allGranted;
      
      print('DEBUG: [NotificationService] Wyniki automatycznego żądania uprawnień: $results');
      
    } catch (e) {
      print('Error requesting all permissions automatically: $e');
      results['error'] = true;
    }
    
    return results;
  }

  // Sprawdź zaplanowane notyfikacje
  static Future<List<tz.TZDateTime>> getPendingNotifications() async {
    if (!_initialized) await initialize();
    
    try {
      final pendingNotifications = await _notifications.pendingNotificationRequests();
      print('DEBUG: Liczba zaplanowanych notyfikacji: ${pendingNotifications.length}');
      
      for (final notification in pendingNotifications) {
        print('DEBUG: ID: ${notification.id}, Tytuł: ${notification.title}');
      }
      
      return [];
    } catch (e) {
      print('Error getting pending notifications: $e');
      return [];
    }
  }

  // === METODY DO ZARZĄDZANIA USTAMIENIAMI ===

  // Zapisz ustawienia notyfikacji
  static Future<void> saveNotificationSettings({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
    await prefs.setInt(_notificationHourKey, hour);
    await prefs.setInt(_notificationMinuteKey, minute);
    
    print('DEBUG: [NotificationService] Zapisano ustawienia: enabled=$enabled, hour=$hour, minute=$minute');
    
    // Jeśli notyfikacje są włączone, zaplanuj je
    if (enabled) {
      await scheduleDailyReminder(hour, minute);
    } else {
      await cancelDailyReminder();
    }
  }

  // Pobierz ustawienia notyfikacji
  static Future<Map<String, dynamic>> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    return {
      'enabled': prefs.getBool(_notificationsEnabledKey) ?? false,
      'hour': prefs.getInt(_notificationHourKey) ?? 20, // Domyślnie 20:00
      'minute': prefs.getInt(_notificationMinuteKey) ?? 0,
    };
  }

  // Sprawdź czy notyfikacje są włączone
  static Future<bool> isNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? false;
  }

  // Pobierz godzinę notyfikacji
  static Future<int> getNotificationHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_notificationHourKey) ?? 20;
  }

  // Pobierz minutę notyfikacji
  static Future<int> getNotificationMinute() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_notificationMinuteKey) ?? 0;
  }

  // Otwórz ustawienia aplikacji
  static Future<void> openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      print('Error opening app settings: $e');
    }
  }
}
