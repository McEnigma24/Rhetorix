import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 20, minute: 0);
  bool _isLoading = true;
  Map<String, dynamic> _permissionStatus = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkPermissions();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await NotificationService.getNotificationSettings();
      setState(() {
        _notificationsEnabled = settings['enabled'];
        _notificationTime = TimeOfDay(
          hour: settings['hour'],
          minute: settings['minute'],
        );
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkPermissions() async {
    try {
      final status = await NotificationService.checkAllPermissions();
      setState(() {
        _permissionStatus = status;
      });
    } catch (e) {
      print('Error checking permissions: $e');
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.teal,
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              alwaysUse24HourFormat: NotificationService.is24HourFormat(),
            ),
            child: child!,
          ),
        );
      },
    );
    if (picked != null && picked != _notificationTime) {
      setState(() {
        _notificationTime = picked;
      });
      await _saveSettings();
    }
  }

  Future<void> _saveSettings() async {
    try {
      await NotificationService.saveNotificationSettings(
        enabled: _notificationsEnabled,
        hour: _notificationTime.hour,
        minute: _notificationTime.minute,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ustawienia zostały zapisane'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd podczas zapisywania: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });
    await _saveSettings();
  }

  Future<void> _requestPermissions() async {
    try {
      final results = await NotificationService.requestAllPermissionsAutomatically();
      final allGranted = results['all_granted'] ?? false;
      
      if (mounted) {
        if (allGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dziękujemy! Wszystkie uprawnienia zostały przyznane.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nie wszystkie uprawnienia zostały przyznane. Sprawdź ustawienia aplikacji.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
      
      // Odśwież status uprawnień
      await _checkPermissions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd podczas żądania uprawnień: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      await NotificationService.sendTestNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Testowa notyfikacja została wysłana'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd podczas wysyłania testowej notyfikacji: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendTestNotificationIn10Seconds() async {
    try {
      await NotificationService.sendTestNotificationIn10Seconds();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Testowa notyfikacja zaplanowana na 10 sekund'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd podczas planowania testowej notyfikacji: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _debugNotifications() async {
    try {
      await NotificationService.debugShowScheduledNotifications();
      
      final isScheduled = await NotificationService.isNotificationScheduled();
      final permissionStatus = await NotificationService.checkAllPermissions();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Debug - Status powiadomień'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Powiadomienie zaplanowane: ${isScheduled ? "TAK" : "NIE"}'),
                  const SizedBox(height: 8),
                  Text('Format 24h: ${NotificationService.is24HourFormat() ? "TAK" : "NIE"}'),
                  const SizedBox(height: 8),
                  Text('Uprawnienia systemowe: ${permissionStatus['system_permissions'] ?? false ? "TAK" : "NIE"}'),
                  const SizedBox(height: 8),
                  Text('Dokładne alarmy: ${permissionStatus['exact_alarm_permissions'] ?? false ? "TAK" : "NIE"}'),
                  const SizedBox(height: 8),
                  Text('Optymalizacja baterii: ${permissionStatus['battery_optimization_permissions'] ?? false ? "TAK" : "NIE"}'),
                  const SizedBox(height: 8),
                  Text('Można planować: ${permissionStatus['can_schedule_notifications'] ?? false ? "TAK" : "NIE"}'),
                  const SizedBox(height: 12),
                  const Text('Sprawdź logi w konsoli dla szczegółów.'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Zamknij'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd podczas debugowania: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ustawienia',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sekcja powiadomień
            _buildSectionHeader('Powiadomienia', Icons.notifications),
            const SizedBox(height: 16),
            
            // Włącz/wyłącz powiadomienia
            _buildSwitchTile(
              'Powiadomienia dzienne',
              'Otrzymuj przypomnienia o zadaniach Rhetorix',
              _notificationsEnabled,
              _toggleNotifications,
            ),
            
            const SizedBox(height: 16),
            
            // Czas powiadomień
            if (_notificationsEnabled) ...[
              _buildTimeTile(
                'Czas powiadomień',
                'Wybierz godzinę codziennych przypomnień',
                _notificationTime,
                _selectTime,
              ),
              const SizedBox(height: 16),
            ],
            
            // Status uprawnień
            _buildPermissionStatus(),
            
            const SizedBox(height: 24),
            
            // Sekcja testów
            _buildSectionHeader('Testy', Icons.science),
            const SizedBox(height: 16),
            
            // Przyciski testowe
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _sendTestNotification,
                    icon: const Icon(Icons.send),
                    label: const Text('Test natychmiast'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _sendTestNotificationIn10Seconds,
                    icon: const Icon(Icons.schedule),
                    label: const Text('Test za 10s'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Przycisk debugowania
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _debugNotifications,
                icon: const Icon(Icons.bug_report),
                label: const Text('Debug powiadomień'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Informacje o aplikacji
            _buildSectionHeader('Informacje', Icons.info),
            const SizedBox(height: 16),
            
            _buildInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Card(
      elevation: 2,
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.teal,
        secondary: const Icon(Icons.notifications_active, color: Colors.teal),
      ),
    );
  }

  Widget _buildTimeTile(String title, String subtitle, TimeOfDay time, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              NotificationService.formatTime(time),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: onTap,
        leading: const Icon(Icons.access_time, color: Colors.teal),
      ),
    );
  }

  Widget _buildPermissionStatus() {
    final canSchedule = _permissionStatus['can_schedule_notifications'] ?? false;
    final issues = _permissionStatus['issues'] as List<String>? ?? [];
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  canSchedule ? Icons.check_circle : Icons.warning,
                  color: canSchedule ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Status uprawnień',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: canSchedule ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (canSchedule)
              const Text(
                'Wszystkie uprawnienia są przyznane ✓',
                style: TextStyle(color: Colors.green),
              )
            else ...[
              const Text(
                'Wymagane uprawnienia:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              ...issues.map((issue) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: Text('• $issue', style: const TextStyle(fontSize: 12)),
              )).toList(),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _requestPermissions,
                  icon: const Icon(Icons.security),
                  label: const Text('Przyznaj uprawnienia'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rhetorix - Aplikacja do ćwiczeń retorycznych',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Powiadomienia pomagają Ci utrzymać codzienny streak i nie zapomnieć o ćwiczeniach.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                const SizedBox(width: 4),
                const Text(
                  'Utrzymaj swój streak!',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
