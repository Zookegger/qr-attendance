import 'dart:io';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:qr_attendance_frontend/src/models/request.dart';
import 'package:qr_attendance_frontend/src/models/user.dart';
import 'package:qr_attendance_frontend/src/services/request.service.dart';
import 'package:qr_attendance_frontend/src/services/auth.service.dart';

class RequestFormPage extends StatefulWidget {
  final Request? initialRequest;
  const RequestFormPage({super.key, this.initialRequest});

  @override
  State<RequestFormPage> createState() => _RequestFormPageState();
}

class _RequestFormPageState extends State<RequestFormPage> {
  DateTime? _fromDate;
  DateTime? _toDate;

  bool _isLoading = false;
  bool _isEditing = false;
  bool _isEditable = true;

  String? _selectedType;

  User? _currentUser;
  final AuthenticationService _auth = AuthenticationService();

  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<PlatformFile> _selectedFiles = [];

  final List<String> _requestTypes = [
    'Leave request',
    'Sick leave',
    'Unpaid leave',
    'Late arrival / early leave',
    'Overtime request (OT)',
    'Business trip',
    'Shift change request',
    'Remote work request',
    'Equipment request',
    'System account request',
    'Salary advance request',
    'Payment / reimbursement request',
    'Attendance confirmation request',
    'Attendance adjustment request',
    'Explanation request',
    'Other...',
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
    if (widget.initialRequest != null) {
      _isEditing = true;
      final r = widget.initialRequest!;
      _selectedType = r.type;
      _fromDate = r.fromDate;
      _toDate = r.toDate;
      _reasonController.text = r.reason ?? '';
      // Only editable if status is pending
      _isEditable = r.status.toLowerCase() == 'pending';
    }
  }

  Future<void> _loadUser() async {
    try {
      _currentUser = await _auth.getCachedUser();
      _currentUser ??= await _auth.me();
      setState(() {});
    } catch (e) {
      debugPrint('Failed to load user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load user. Please log in again.')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  // ================= DATE PICKER =================
  Future<void> _pickDate({required bool isFromDate}) async {
    final now = DateTime.now();
    final lastSelectableDate = DateTime(now.year + 2, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: lastSelectableDate,
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          if (_toDate != null && _toDate!.isBefore(picked)) {
            _toDate = null;
          }
        } else {
          _toDate = picked;
        }
      });
    }
  }

  // ================= FILE PICK =================
  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result != null) {
      setState(() => _selectedFiles = result.files);
    }
  }



  // ================= SUBMIT REQUEST =================
  Future<void> submitRequest() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not loaded. Please try again.')),
      );
      return;
    }

    if (_selectedType == null || _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final files = _selectedFiles.where((f) => f.path != null).map((f) => File(f.path!)).toList();

      if (_isEditing) {
        if (!_isEditable) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Only pending requests can be edited')),
          );
          return;
        }

        final request = Request(
          id: widget.initialRequest!.id,
          userId: _currentUser!.id,
          type: _selectedType!,
          fromDate: _fromDate,
          toDate: _toDate,
          reason: _reasonController.text.trim(),
          attachments: widget.initialRequest!.attachments,
          status: widget.initialRequest!.status,
        );

        await RequestService().updateRequest(request, files);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request updated successfully')),
        );
      } else {
        final request = Request(
          userId: _currentUser!.id,
          type: _selectedType!,
          fromDate: _fromDate,
          toDate: _toDate,
          reason: _reasonController.text.trim(),
        );

        await RequestService().createRequest(request, files);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request created successfully')),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      debugPrint('Error: $e');
      debugPrint('USER ID: ${_currentUser?.id}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: Text(
          _isEditing ? 'Edit Request' : 'Create Request',
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1. Select request type',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            _buildDropdown(),

            const SizedBox(height: 24),
            const Text(
              '2. Date range',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                _buildDateBox(
                  label: 'From',
                  date: _fromDate,
                  onTap: () => _pickDate(isFromDate: true),
                ),
                const SizedBox(width: 12),
                _buildDateBox(
                  label: 'To',
                  date: _toDate,
                  onTap: () => _pickDate(isFromDate: false),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Text(
              '3. Reason',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            _buildReasonInput(),

            const SizedBox(height: 16),
            _buildImagePicker(),

            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  // ================= WIDGETS =================
  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          isExpanded: true,
          hint: const Text('Select request type'),
          value: _selectedType,
          items: _requestTypes
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (value) => setState(() => _selectedType = value),
          dropdownStyleData: DropdownStyleData(
            maxHeight: 280,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          ),
          dropdownSearchData: DropdownSearchData(
            searchController: _searchController,
            searchInnerWidgetHeight: 50,
            searchInnerWidget: Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search request type',
                ),
              ),
            ),
            searchMatchFn: (item, value) =>
                item.value.toString().toLowerCase().contains(value),
          ),
          onMenuStateChange: (isOpen) {
            if (!isOpen) _searchController.clear();
          },
        ),
      ),
    );
  }

  Widget _buildReasonInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _reasonController,
        maxLines: 5,
        decoration: const InputDecoration(
          hintText: 'Enter reason...',
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Attachments (optional)',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            InkWell(
              onTap: _pickFiles,
              child: Row(
                children: [
                  const Icon(Icons.attach_file_outlined),
                  const SizedBox(width: 6),
                  const Text('Upload files'),
                ],
              ),
            ),
          ],
        ),
        if (_selectedFiles.isNotEmpty) ...[
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _selectedFiles.map((file) => Text(file.name)).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : submitRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Submit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
      ),
    );
  }
}

// ================= DATE BOX =================
Widget _buildDateBox({
  required String label,
  required DateTime? date,
  required VoidCallback onTap,
}) {
  return Expanded(
    child: InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          date == null
              ? label
              : '$label: ${date.day}/${date.month}/${date.year}',
        ),
      ),
    ),
  );
}
