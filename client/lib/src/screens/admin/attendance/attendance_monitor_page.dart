import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_attendance_frontend/src/services/attendance.service.dart';

class AttendanceMonitorPage extends StatefulWidget {
  const AttendanceMonitorPage({super.key});

  @override
  State<AttendanceMonitorPage> createState() => _AttendanceMonitorPageState();
}

class _AttendanceMonitorPageState extends State<AttendanceMonitorPage> {
  final AttendanceService _attendanceService = AttendanceService();
  DateTime _selectedDate = DateTime.now();
  
  // Future for Pull-to-Refresh
  late Future<List<Map<String, dynamic>>> _monitorFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _monitorFuture = _attendanceService.fetchDailyMonitor(_selectedDate);
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _refresh();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Present':
        return Colors.green;
      case 'Checked Out':
        return Colors.blue;
      case 'Absent':
        return Colors.red;
      case 'Late':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Monitor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Expected Attendees",
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _monitorFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const Center(child: Text("No records found"));
                }

                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final user = item['user'];
                    final schedule = item['schedule']; // can be null
                    final attendance = item['attendance']; // can be null
                    final computedStatus = item['computedStatus'] ?? 'Unknown';

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(user['name'][0].toUpperCase()),
                      ),
                      title: Text(user['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (schedule != null)
                             Text(
                              "Shift: ${schedule['startTime'] != null ? DateFormat('HH:mm').format(DateTime.parse('2000-01-01T' + schedule['startTime'])) : '?'} - "
                              "${schedule['endTime'] != null ? DateFormat('HH:mm').format(DateTime.parse('2000-01-01T' + schedule['endTime'])) : '?'}",
                            )
                          else
                            const Text("No Scheduled Shift"),
                          
                          if (attendance != null)
                            Text(
                              "In: ${attendance['checkInTime'] != null ? DateFormat('HH:mm').format(DateTime.parse(attendance['checkInTime'])) : '-'} | "
                              "Out: ${attendance['checkOutTime'] != null ? DateFormat('HH:mm').format(DateTime.parse(attendance['checkOutTime'])) : '-'}",
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(computedStatus).withOpacity(0.1),
                          border: Border.all(color: _getStatusColor(computedStatus)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          computedStatus,
                          style: TextStyle(
                            color: _getStatusColor(computedStatus),
                            fontWeight: FontWeight.bold,
                            fontSize: 12
                          ),
                        ),
                      ),
                      onTap: () => _showManualEntryDialog(item),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showManualEntryDialog(Map<String, dynamic> item) {
    final user = item['user'];
    final attendance = item['attendance'];
    
    // Initial values
    DateTime? checkIn = attendance != null && attendance['checkInTime'] != null
        ? DateTime.parse(attendance['checkInTime'])
        : null;
    DateTime? checkOut = attendance != null && attendance['checkOutTime'] != null
        ? DateTime.parse(attendance['checkOutTime'])
        : null;
        
    final notesController = TextEditingController(text: attendance?['notes'] ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text("Manage Attendance: ${user['name']}"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   const Text("Admin Override / Manual Entry"),
                   const SizedBox(height: 16),
                   ListTile(
                     title: const Text("Check In Time"),
                     subtitle: Text(checkIn != null 
                         ? DateFormat('HH:mm').format(checkIn!) 
                         : "Not set"),
                     trailing: const Icon(Icons.access_time),
                     onTap: () async {
                       final time = await showTimePicker(
                         context: context,
                         initialTime: TimeOfDay.fromDateTime(checkIn ?? DateTime.now()),
                       );
                       if (time != null) {
                         setStateDialog(() {
                           final now = _selectedDate;
                           checkIn = DateTime(now.year, now.month, now.day, time.hour, time.minute);
                         });
                       }
                     },
                   ),
                   ListTile(
                     title: const Text("Check Out Time"),
                     subtitle: Text(checkOut != null 
                         ? DateFormat('HH:mm').format(checkOut!) 
                         : "Not set"),
                     trailing: const Icon(Icons.access_time),
                     onTap: () async {
                       final time = await showTimePicker(
                         context: context,
                         initialTime: TimeOfDay.fromDateTime(checkOut ?? DateTime.now()),
                       );
                       if (time != null) {
                         setStateDialog(() {
                           final now = _selectedDate;
                           checkOut = DateTime(now.year, now.month, now.day, time.hour, time.minute);
                         });
                       }
                     },
                   ),
                   TextField(
                     controller: notesController,
                     decoration: const InputDecoration(labelText: 'Notes / Reason'),
                   )
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _attendanceService.manualEntry(
                        userId: user['id'].toString(),
                        date: _selectedDate,
                        checkInTime: checkIn,
                        checkOutTime: checkOut,
                        notes: notesController.text,
                    );
                    if (mounted) {
                        Navigator.pop(context);
                        _refresh();
                        ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text("Attendance updated")),
                        );
                    }
                  } catch (e) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text("Error: $e")),
                     );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
