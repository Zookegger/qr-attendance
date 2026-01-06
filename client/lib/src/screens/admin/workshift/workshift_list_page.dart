import 'package:flutter/material.dart';
import 'package:qr_attendance_frontend/src/screens/admin/workshift/workshift.form_page.dart';
import '../../../models/workshift.dart';
import '../../../services/workshift.service.dart';

class WorkshiftListPage extends StatefulWidget {
  const WorkshiftListPage({super.key});

  @override
  State<WorkshiftListPage> createState() => _WorkshiftListPageState();
}

class _WorkshiftListPageState extends State<WorkshiftListPage> {
  final WorkshiftService _service = WorkshiftService();
  List<Workshift> _shifts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_shifts.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final data = await _service.listWorkshifts();
      if (mounted) setState(() => _shifts = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading shifts: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Workshift?'),
        content: const Text(
          'This action cannot be undone. Schedules assigned to this shift might be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteWorkshift(id);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Workshift deleted successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _openForm([Workshift? shift]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WorkshiftFormPage(workshift: shift)),
    );
    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Workshifts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        label: const Text('New Shift'),
        icon: const Icon(Icons.add),
        elevation: 4,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _shifts.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: _shifts.length,
                    itemBuilder: (context, index) {
                      return _buildShiftCard(_shifts[index]);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No workshifts found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "New Shift" to create one.',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftCard(Workshift shift) {
    // Check if break time exists to conditionally render it
    // Assuming breakStart/End might be empty strings or null depending on your backend
    final hasBreak = shift.breakStart.isNotEmpty && shift.breakEnd.isNotEmpty;
    final breakText = hasBreak
        ? '${shift.breakStart} - ${shift.breakEnd}'
        : 'No Break';

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _openForm(shift),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      shift.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildActionMenu(shift),
                ],
              ),
              const Divider(height: 24, color: Colors.black12),
              
              // Work Time
              _buildInfoRow(
                Icons.access_time_filled_rounded,
                '${shift.startTime} - ${shift.endTime}',
                Colors.blueAccent,
                fontWeight: FontWeight.w600,
              ),
              
              const SizedBox(height: 12),
              
              // Break Time (New)
              _buildInfoRow(
                Icons.coffee_rounded, // Coffee icon for break
                breakText,
                hasBreak ? Colors.orangeAccent : Colors.grey,
              ),

              const SizedBox(height: 12),
              
              // Days
              _buildInfoRow(
                Icons.calendar_month_rounded,
                Workshift.formatDays(shift.workDays),
                Colors.purpleAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String text,
    Color iconColor, {
    FontWeight? fontWeight,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: Colors.black87,
              fontWeight: fontWeight ?? FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionMenu(Workshift shift) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: Colors.grey[400]),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'edit') _openForm(shift);
        if (value == 'delete') _delete(shift.id);
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_rounded, size: 20, color: Colors.black54),
              SizedBox(width: 12),
              Text('Edit'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: Colors.redAccent,
              ),
              SizedBox(width: 12),
              Text('Delete', style: TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
      ],
    );
  }
}