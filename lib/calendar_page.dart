import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  final List<Map<String, String>> allJobs;

  CalendarPage({required this.allJobs});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late Map<DateTime, List<Map<String, String>>> _jobsByDate;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _jobsByDate = _groupJobsByDeadline(widget.allJobs);
  }

  Map<DateTime, List<Map<String, String>>> _groupJobsByDeadline(List<Map<String, String>> jobs) {
    Map<DateTime, List<Map<String, String>>> jobsMap = {};

    for (var job in jobs) {
      try {
        DateTime deadline = DateTime.parse(job['deadline']!.replaceAll('/', '-'));
        DateTime normalized = DateTime(deadline.year, deadline.month, deadline.day);
        if (!jobsMap.containsKey(normalized)) {
          jobsMap[normalized] = [];
        }
        jobsMap[normalized]!.add(job);
      } catch (e) {
        print("Error parsing date: ${job['deadline']}");
      }
    }

    return jobsMap;
  }

  List<Map<String, String>> _getJobsForDay(DateTime day) {
    return _jobsByDate[DateTime(day.year, day.month, day.day)] ?? [];
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Applied':
        return Colors.blue;
      case 'Interviews':
        return Colors.orange;
      case 'Rejected':
        return Colors.red;
      case 'Accepted':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Calendar")),
      body: Column(
        children: [
        TableCalendar(
          firstDay: DateTime.utc(2023, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          eventLoader: _getJobsForDay,
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {
            CalendarFormat.month: '',
          },
          calendarStyle: CalendarStyle(
            selectedDecoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (isSameDay(date, _selectedDay)) return SizedBox.shrink();

              if (events.isNotEmpty) {
                return Positioned(
                  bottom: 1,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }
              return SizedBox.shrink();
            },
          ),
        ),

          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView.builder(
                itemCount: _getJobsForDay(_selectedDay!).length,
                itemBuilder: (context, index) {
                  final job = _getJobsForDay(_selectedDay!)[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job['title'] ?? '',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text('Company: ${job['company']}',
                              style: TextStyle(color: Colors.grey[700])),
                          SizedBox(height: 4),
                          Text('Date Applied: ${job['dateApplied']}',
                              style: TextStyle(color: Colors.grey[700])),
                          SizedBox(height: 4),
                          Text('Deadline: ${job['deadline']}',
                              style: TextStyle(color: Colors.grey[700])),
                          SizedBox(height: 12),
                          Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 4, horizontal: 12),
                            decoration: BoxDecoration(
                              color: _getStatusColor(job['status'] ?? ''),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              job['status'] ?? '',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
