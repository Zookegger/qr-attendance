import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/user.dart';
import '../../../models/schedule.dart';
import '../../../models/workshift.dart';
import '../../../services/schedule.service.dart';
import '../../../services/workshift.service.dart';

class ManageEmployeeSchedulePage extends StatefulWidget {
  final User user;

  const ManageEmployeeSchedulePage({super.key, required this.user});

  @override
  State<ManageEmployeeSchedulePage> createState() => _ManageEmployeeSchedulePageState();
}

class _ManageEmployeeSchedulePageState extends State<ManageEmployeeSchedulePage> {
  final ScheduleService _scheduleService = ScheduleService();
  final WorkshiftService _shiftService = WorkshiftService();

  List<Schedule> _schedules = [];
  List<Workshift> _availableShifts = [];
  bool _isLoading = true;
  DateTime _currentWeekStart = DateTime.now();

  @override
  void initState() {
    super.initState();
    _currentWeekStart = _getMonday(DateTime.now());
    _loadData();
  }

  DateTime _getMonday(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _scheduleService.getUserSchedules(userId: widget.user.id),
        _shiftService.listWorkshifts(),
      ]);

      if (mounted) {
        setState(() {
          _schedules = results[0] as List<Schedule>;
          _availableShifts = results[1] as List<Workshift>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _deleteSchedule(int id) async {
    try {
      await _scheduleService.deleteSchedule(id);
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  void _showAssignDialog() {
    showDialog(
      context: context,
      builder: (_) => _AssignScheduleDialog(
        user: widget.user,
        shifts: _availableShifts,
        onSuccess: _loadData,
      ),
    );
  }

  List<Schedule> _getSchedulesForDay(DateTime day) {
    return _schedules
        .where((sch) {
          final isAfterStart = !sch.startDate.isAfter(day);
          final isBeforeEnd =
              sch.endDate == null || !sch.endDate!.isBefore(day);
          return isAfterStart && isBeforeEnd;
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final weekEnd = _currentWeekStart.add(const Duration(days: 6));
    final weekLabel =
        '${DateFormat('MMM dd').format(_currentWeekStart)} - ${DateFormat('MMM dd, yyyy').format(weekEnd)}';

    return Scaffold(
      appBar: AppBar(title: Text('${widget.user.name}\'s Schedule')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAssignDialog,
        label: const Text('Assign Shift'),
        icon: const Icon(Icons.calendar_month),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _schedules.isEmpty
              ? const Center(child: Text('No schedules assigned.'))
              : Column(
                  children: [
                    // Week navigation
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () {
                              setState(() {
                                _currentWeekStart = _currentWeekStart
                                    .subtract(const Duration(days: 7));
                              });
                            },
                          ),
                          Column(
                            children: [
                              Text(
                                weekLabel,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              if (DateFormat('yyyy-MM-dd')
                                      .format(_currentWeekStart) !=
                                  DateFormat('yyyy-MM-dd')
                                      .format(_getMonday(DateTime.now())))
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _currentWeekStart =
                                          _getMonday(DateTime.now());
                                    });
                                  },
                                  child: const Text('Today'),
                                ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () {
                              setState(() {
                                _currentWeekStart = _currentWeekStart
                                    .add(const Duration(days: 7));
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    // Weekly schedule grid
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: 7,
                        itemBuilder: (context, dayIndex) {
                          final day =
                              _currentWeekStart.add(Duration(days: dayIndex));
                          final dayOfWeek = DateFormat('EEEE').format(day);
                          final dayDate = DateFormat('MMM dd').format(day);
                          final schedulesForDay = _getSchedulesForDay(day);
                          final isToday =
                              DateFormat('yyyy-MM-dd').format(day) ==
                                  DateFormat('yyyy-MM-dd')
                                      .format(DateTime.now());

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: isToday
                                ? Colors.blue.shade50
                                : Colors.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isToday
                                        ? Colors.blue
                                        : Colors.grey.shade200,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dayOfWeek,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isToday
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      Text(
                                        dayDate,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isToday
                                              ? Colors.white70
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (schedulesForDay.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      'No shifts assigned',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  )
                                else
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: schedulesForDay.length,
                                    itemBuilder: (context, index) {
                                      final sch = schedulesForDay[index];
                                      final shiftName = sch.shift?.name ??
                                          'Unknown Shift #${sch.shiftId}';

                                      return Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    shiftName,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  if (sch.shift != null)
                                                    Text(
                                                      '${sch.shift!.startTime} - ${sch.shift!.endTime}',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors
                                                            .grey.shade600,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                                size: 18,
                                              ),
                                              onPressed: () =>
                                                  _deleteSchedule(sch.id),
                                              constraints: const BoxConstraints(
                                                minWidth: 0,
                                                minHeight: 0,
                                              ),
                                              padding: EdgeInsets.zero,
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _AssignScheduleDialog extends StatefulWidget {
  final User user;
  final List<Workshift> shifts;
  final VoidCallback onSuccess;

  const _AssignScheduleDialog({
    required this.user,
    required this.shifts,
    required this.onSuccess,
  });

  @override
  State<_AssignScheduleDialog> createState() => _AssignScheduleDialogState();
}

class _AssignScheduleDialogState extends State<_AssignScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  Workshift? _selectedShift;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assign Schedule'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Workshift>(
                decoration: const InputDecoration(labelText: 'Select Shift'),
                items: widget.shifts.map((s) {
                  return DropdownMenuItem(value: s, child: Text(s.name));
                }).toList(),
                onChanged: (v) => setState(() => _selectedShift = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (d != null) setState(() => _startDate = d);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _startDate != null
                        ? DateFormat('yyyy-MM-dd').format(_startDate!)
                        : 'Select Date',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (d != null) setState(() => _endDate = d);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'End Date (Optional)',
                    border: OutlineInputBorder(),
                    helperText: 'Leave empty for indefinite',
                  ),
                  child: Text(
                    _endDate != null
                        ? DateFormat('yyyy-MM-dd').format(_endDate!)
                        : 'Indefinite',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(),
                )
              : const Text('Assign'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Start Date is required')));
      return;
    }

    setState(() => _submitting = true);
    try {
      final payload = {
        'user_id': widget.user.id,
        'shift_id': _selectedShift!.id,
        'start_date': DateFormat('yyyy-MM-dd').format(_startDate!),
        'end_date': _endDate != null
            ? DateFormat('yyyy-MM-dd').format(_endDate!)
            : null,
      };

      await ScheduleService().assignSchedule(payload);
      widget.onSuccess();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
