import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/calendar_event.dart';

class CalendarService {
  static const String _eventsKey = 'calendar_events';
  
  // Kategorie wydarzeń z kolorami
  static const Map<String, Color> eventCategories = {
    'Skojarzenia': Colors.blue,
    'Czytanie z korkiem': Colors.green,
    'Opowiadanie historii': Colors.orange,
    'Migreny': Colors.red,
    'Praca nad biznesem': Colors.purple,
  };

  static Future<List<CalendarEvent>> getEventsForMonth(DateTime month) async {
    final prefs = await SharedPreferences.getInstance();
    final monthKey = '${month.year}-${month.month}';
    
    final eventsJson = prefs.getString('${_eventsKey}_$monthKey');
    if (eventsJson != null) {
      final List<dynamic> eventsList = json.decode(eventsJson);
      return eventsList.map((json) => CalendarEvent.fromJson(json)).toList();
    }
    
    return [];
  }

  static Future<void> saveEventsForMonth(DateTime month, List<CalendarEvent> events) async {
    final prefs = await SharedPreferences.getInstance();
    final monthKey = '${month.year}-${month.month}';
    
    final eventsJson = json.encode(events.map((event) => event.toJson()).toList());
    await prefs.setString('${_eventsKey}_$monthKey', eventsJson);
  }

  static Future<void> addEvent(CalendarEvent event) async {
    final month = DateTime(event.date.year, event.date.month);
    final events = await getEventsForMonth(month);
    events.add(event);
    await saveEventsForMonth(month, events);
  }

  static Future<void> removeEvent(String eventId, DateTime date) async {
    final month = DateTime(date.year, date.month);
    final events = await getEventsForMonth(month);
    events.removeWhere((event) => event.id == eventId);
    await saveEventsForMonth(month, events);
  }

  static Future<List<CalendarEvent>> getEventsForDate(DateTime date) async {
    final month = DateTime(date.year, date.month);
    final events = await getEventsForMonth(month);
    return events.where((event) => 
      event.date.year == date.year &&
      event.date.month == date.month &&
      event.date.day == date.day
    ).toList();
  }

  static Future<Map<String, int>> getEventCountsForMonth(DateTime month) async {
    final events = await getEventsForMonth(month);
    final counts = <String, int>{};
    
    for (final event in events) {
      counts[event.category] = (counts[event.category] ?? 0) + 1;
    }
    
    return counts;
  }

  // Generowanie przykładowych danych dla testów
  static Future<void> generateSampleData() async {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    
    // Sprawdź czy już są dane
    final existingEvents = await getEventsForMonth(currentMonth);
    if (existingEvents.isNotEmpty) return;
    
    final sampleEvents = <CalendarEvent>[];
    
    // Generuj wydarzenia dla obecnego miesiąca
    for (int day = 1; day <= 31; day++) {
      try {
        final date = DateTime(currentMonth.year, currentMonth.month, day);
        if (date.month != currentMonth.month) break;
        
        // Losowo dodaj wydarzenia
        if (day % 3 == 0) {
          sampleEvents.add(CalendarEvent(
            id: 'sample_${day}_1',
            title: 'Skojarzenia',
            color: eventCategories['Skojarzenia']!,
            date: date,
            category: 'Skojarzenia',
          ));
        }
        
        if (day % 4 == 0) {
          sampleEvents.add(CalendarEvent(
            id: 'sample_${day}_2',
            title: 'Czytanie z korkiem',
            color: eventCategories['Czytanie z korkiem']!,
            date: date,
            category: 'Czytanie z korkiem',
          ));
        }
        
        if (day % 5 == 0) {
          sampleEvents.add(CalendarEvent(
            id: 'sample_${day}_3',
            title: 'Opowiadanie historii',
            color: eventCategories['Opowiadanie historii']!,
            date: date,
            category: 'Opowiadanie historii',
          ));
        }
      } catch (e) {
        // Ignoruj nieprawidłowe daty (np. 31 lutego)
        continue;
      }
    }
    
    await saveEventsForMonth(currentMonth, sampleEvents);
  }
}
