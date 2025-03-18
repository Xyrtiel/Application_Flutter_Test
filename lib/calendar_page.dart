import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
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
  Map<DateTime, List<CalendarEvent>> _events = {};
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadTrelloEvents();
    tz_data.initializeTimeZones();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('app_icon'); // Replace 'app_icon' with your app's icon
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _scheduleNotification(CalendarEvent event) async {
    if (event.reminderTime != null) {
      final reminderDateTime = event.startDate.subtract(Duration(minutes: event.reminderTime!));
      if (reminderDateTime.isAfter(DateTime.now())) {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          event.hashCode,
          'Reminder: ${event.title}',
          event.description,
          tz.TZDateTime.from(reminderDateTime, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails('your channel id', 'your channel name',
                channelDescription: 'your channel description'),
          ),
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  Future<void> _loadTrelloEvents() async {
    try {
      List<dynamic> lists = await widget.trelloService.getLists(widget.boardId);
      Map<DateTime, List<CalendarEvent>> newEvents = {};
      for (var list in lists) {
        List<dynamic> cards = await widget.trelloService.getCards(list['id']);
        for (var card in cards) {
          DateTime? startDate;
          DateTime? endDate;
          int? reminderTime;
          String description = "";

          if (card['start'] != null) {
            startDate = DateTime.parse(card['start']);
          }
          if (card['due'] != null) {
            endDate = DateTime.parse(card['due']);
          }
          if (card['reminder'] != null) {
            reminderTime = card['reminder'];
          }
          if (card['desc'] != null) {
            description = card['desc'];
          }

          if (startDate != null && endDate != null) {
            DateTime formattedStartDate = DateTime(startDate.year, startDate.month, startDate.day);
            DateTime formattedEndDate = DateTime(endDate.year, endDate.month, endDate.day);
            CalendarEvent newEvent = CalendarEvent(
              title: card['name'],
              startDate: formattedStartDate,
              endDate: formattedEndDate,
              reminderTime: reminderTime,
              description: description,
            );
            for (DateTime day = formattedStartDate; day.isBefore(formattedEndDate.add(const Duration(days: 1))); day = day.add(const Duration(days: 1))) {
              if (newEvents[day] == null) {
                newEvents[day] = [];
              }
              newEvents[day]!.add(newEvent);
            }
            _scheduleNotification(newEvent);
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

  void _showAddEventDialog(DateTime day) {
    String title = '';
    DateTime startDate = day;
    DateTime endDate = day;
    int? reminderTime;
    String description = "";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  decoration: const InputDecoration(hintText: 'Title'),
                  onChanged: (value) => title = value,
                ),
                ListTile(
                  title: Text('Start Date: ${startDate.toLocal().toString().split(' ')[0]}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null && picked != startDate) {
                      setState(() {
                        startDate = picked;
                      });
                    }
                  },
                ),
                ListTile(
                  title: Text('End Date: ${endDate.toLocal().toString().split(' ')[0]}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: endDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null && picked != endDate) {
                      setState(() {
                        endDate = picked;
                      });
                    }
                  },
                ),
                TextField(
                  decoration: const InputDecoration(hintText: 'Reminder Time (minutes before)'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => reminderTime = int.tryParse(value),
                ),
                TextField(
                  decoration: const InputDecoration(hintText: 'Description'),
                  onChanged: (value) => description = value,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () async {
                if (title.isNotEmpty) {
                  CalendarEvent newEvent = CalendarEvent(
                    title: title,
                    startDate: startDate,
                    endDate: endDate,
                    reminderTime: reminderTime,
                    description: description,
                  );
                  await widget.trelloService.createCardWithDetails(widget.boardId, title, startDate, endDate, reminderTime, description);
                  _scheduleNotification(newEvent);
                  setState(() {
                    _loadTrelloEvents();
                  });
                  if (context.mounted) Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
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
            Expanded(
              child: ListView.builder(
                itemCount: _events[_selectedDay]?.length ?? 0,
                itemBuilder: (context, index) {
                  final event = _events[_selectedDay]![index];
                  return ListTile(
                    title: Text(event.title),
                    subtitle: Text(event.description),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(_selectedDay ?? DateTime.now()),
        child: const Icon(Icons.add),
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

class CalendarEvent {
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final int? reminderTime;
  final String description;

  CalendarEvent({
    required this.title,
    required this.startDate,
    required this.endDate,
    this.reminderTime,
    required this.description,
  });
}
