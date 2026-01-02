import 'package:flutter/material.dart';
import '../../../models/workshift.dart';
import '../../../services/workshift.service.dart';

class WorkshiftFormPage extends StatefulWidget {
  final Workshift? workshift;

  const WorkshiftFormPage({super.key, this.workshift});

  @override
  State<WorkshiftFormPage> createState() => _WorkshiftFormPageState();
}

class _WorkshiftFormPageState extends State<WorkshiftFormPage> {
  final _formKey = GlobalKey<FormState>();
  final WorkshiftService _service = WorkshiftService();

  late TextEditingController _nameCtrl;
  late TextEditingController _graceCtrl;

  // Time placeholders
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  TimeOfDay? _breakStart;
  TimeOfDay? _breakEnd;

  // Days: 0=Sun, 1=Mon... 6=Sat
  final Set<int> _selectedDays = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final w = widget.workshift;
    _nameCtrl = TextEditingController(text: w?.name ?? '');
    _graceCtrl = TextEditingController(text: w?.gracePeriod.toString() ?? '15');

    if (w != null) {
      _startTime = _parseTime(w.startTime);
      _endTime = _parseTime(w.endTime);
      _breakStart = _parseTime(w.breakStart);
      _breakEnd = _parseTime(w.breakEnd);
      _selectedDays.addAll(w.workDays);
    } else {
      // Defaults
      _startTime = const TimeOfDay(hour: 8, minute: 0);
      _endTime = const TimeOfDay(hour: 17, minute: 0);
      _selectedDays.addAll([1, 2, 3, 4, 5]); // Mon-Fri default
    }
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start and End times are required')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'name': _nameCtrl.text.trim(),
      'startTime': _formatTime(_startTime!),
      'endTime': _formatTime(_endTime!),
      'breakStart': _breakStart != null ? _formatTime(_breakStart!) : null,
      'breakEnd': _breakEnd != null ? _formatTime(_breakEnd!) : null,
      'gracePeriod': int.tryParse(_graceCtrl.text) ?? 0,
      'workDays': (_selectedDays.toList()..sort()),
    };

    try {
      if (widget.workshift == null) {
        await _service.createWorkshift(data);
      } else {
        await _service.updateWorkshift(widget.workshift!.id, data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickTime(
    TimeOfDay? initial,
    Function(TimeOfDay) onPicked,
  ) async {
    final t = await showTimePicker(
      context: context,
      initialTime: initial ?? TimeOfDay.now(),
    );
    if (t != null) {
      setState(() => onPicked(t));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.workshift == null ? 'New Workshift' : 'Edit Workshift',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Shift Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Times Row 1
              Row(
                children: [
                  Expanded(
                    child: _buildTimeTile(
                      'Start Time',
                      _startTime,
                      (t) => _startTime = t,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimeTile(
                      'End Time',
                      _endTime,
                      (t) => _endTime = t,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Times Row 2
              Row(
                children: [
                  Expanded(
                    child: _buildTimeTile(
                      'Break Start',
                      _breakStart,
                      (t) => _breakStart = t,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimeTile(
                      'Break End',
                      _breakEnd,
                      (t) => _breakEnd = t,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _graceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Grace Period (minutes)',
                  border: OutlineInputBorder(),
                  helperText: 'Allowed late time (e.g. 15 mins)',
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Work Days',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(7, (index) {
                  // 0=Sun, 1=Mon...
                  final labels = [
                    'Sun',
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                  ];
                  final isSelected = _selectedDays.contains(index);
                  return FilterChip(
                    label: Text(labels[index]),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedDays.add(index);
                        } else {
                          _selectedDays.remove(index);
                        }
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Workshift'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeTile(
    String label,
    TimeOfDay? time,
    Function(TimeOfDay) onSave,
  ) {
    return InkWell(
      onTap: () => _pickTime(time, onSave),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.access_time),
        ),
        child: Text(
          time?.format(context) ?? '--:--',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
