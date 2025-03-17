import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart'; // Import table_calendar
import 'trello_service.dart';

class CalendarPage extends StatefulWidget {
  final TrelloService trelloService;
  final String boardId;

  const CalendarPage({Key? key, required this.trelloService, required this.boardId}) : super(key: key);

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  Map<DateTime, List<String>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadTrelloEvents();
  }

  Future<void> _loadTrelloEvents() async {
    try {
      List<dynamic> lists = await widget.trelloService.getLists(widget.boardId);
      Map<DateTime, List<String>> newEvents = {};
      for (var list in lists) {
        List<dynamic> cards = await widget.trelloService.getCards(list['id']);
        for (var card in cards) {
          if (card['due'] != null) {
            DateTime dueDate = DateTime.parse(card['due']);
            DateTime formattedDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
            if (newEvents[formattedDate] == null) {
              newEvents[formattedDate] = [];
            }
            newEvents[formattedDate]!.add(card['name']);
          }
        }
      }
      setState(() {
        _events = newEvents;
      });
    } catch (e) {
      print("Error loading Trello events: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2010, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              }
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: (day) {
              return _events[day] ?? [];
            },
            calendarBuilders: CalendarBuilders(
              selectedBuilder: (context, date, _) {
                return Container(
                  margin: const EdgeInsets.all(4.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Text(
                    date.day.toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              },
              todayBuilder: (context, date, _) {
                return Container(
                  margin: const EdgeInsets.all(4.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Text(
                    date.day.toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              },
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: _buildEventsMarker(date, events),
                  );
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 20),
          if (_selectedDay != null)
            Text(
              'Selected Day: ${_selectedDay!.toLocal().toString().split(' ')[0]}',
              style: const TextStyle(fontSize: 18),
            ),
        ],
      ),
    );
  }

  Widget _buildEventsMarker(DateTime date, List events) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).primaryColor,
      ),
      width: 16.0,
      height: 16.0,
      child: Center(
        child: Text(
          '${events.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.0,
          ),
        ),
      ),
    );
  }
}
