import 'package:flutter/material.dart';

class CalendarEvent {
  final String id;
  final String title;
  final Color color;
  final DateTime date;
  final String category;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.color,
    required this.date,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'color': color.value,
      'date': date.toIso8601String(),
      'category': category,
    };
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'],
      title: json['title'],
      color: Color(json['color']),
      date: DateTime.parse(json['date']),
      category: json['category'],
    );
  }
}
