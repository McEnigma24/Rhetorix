import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/calendar_event.dart';

class CalendarService {
  static const String _eventsKey = 'calendar_events';
  
  // Kategorie wydarzeń z kolorami - tylko 3 główne zadania
  static const Map<String, Color> eventCategories = {
    'Skojarzenia': Colors.blue,
    'Czytanie z korkiem': Colors.green,
    'Opowiadanie historii': Colors.orange,
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

  // Wyczyść wszystkie wydarzenia z kalendarza
  static Future<void> clearAllEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    for (final key in keys) {
      if (key.startsWith(_eventsKey)) {
        await prefs.remove(key);
      }
    }
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

}
