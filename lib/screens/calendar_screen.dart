import 'package:flutter/material.dart';
import '../widgets/calendar_widget.dart';
import '../services/calendar_service.dart';
import '../models/calendar_event.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _generateSampleData();
  }

  Future<void> _generateSampleData() async {
    await CalendarService.generateSampleData();
    setState(() {});
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  void _goToToday() {
    setState(() {
      _currentMonth = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kalendarz',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.today, color: Colors.white),
            onPressed: _goToToday,
            tooltip: 'Dzisiaj',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
            // Nawigacja między miesiącami
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.teal),
                  onPressed: _previousMonth,
                ),
                Text(
                  '${_currentMonth.year}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, color: Colors.teal),
                  onPressed: _nextMonth,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Kalendarz
            Expanded(
              child: SingleChildScrollView(
                child: CalendarWidget(
                  currentMonth: _currentMonth,
                  onDateSelected: (date) {
                    _showDateDetails(date);
                  },
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  void _showDateDetails(DateTime date) {
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<List<CalendarEvent>>(
        future: CalendarService.getEventsForDate(date),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(
              content: Center(child: CircularProgressIndicator()),
            );
          }

          final events = snapshot.data ?? [];
          
          return AlertDialog(
            title: Text('${date.day}.${date.month}.${date.year}'),
            content: events.isEmpty
                ? const Text('Brak wydarzeń w tym dniu')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: events.map((event) => ListTile(
                      leading: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: event.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(event.title),
                      subtitle: Text(event.category),
                    )).toList(),
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Zamknij'),
              ),
            ],
          );
        },
      ),
    );
  }
}
