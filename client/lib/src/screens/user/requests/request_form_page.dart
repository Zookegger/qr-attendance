import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart'; 
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
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

  final List<String> _requestTypes = RequestType.values
      .map((e) => e.toTextString())
      .toList();

  @override
  void initState() {
    super.initState();
    _loadUser();
    if (widget.initialRequest != null) {
      _isEditing = true;
      final r = widget.initialRequest!;
      _selectedType = r.type.toTextString();
      _fromDate = r.fromDate;
      _toDate = r.toDate;
      _reasonController.text = r.reason ?? '';
      _isEditable = r.status == RequestStatus.PENDING;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      _currentUser = await _auth.getCachedUser() ?? await _auth.me();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Failed to load user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load user. Please log in again.'),
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  // ================= PERMISSION & FILE PICK =================
  Future<bool> _requestPermission() async {
    if (Platform.isIOS)
      return true; // iOS usually handles this via the picker UI nicely

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;

      // Android 13+ (SDK 33) uses granular permissions
      if (androidInfo.version.sdkInt >= 33) {
        final photos = await Permission.photos.request();
        // You might need Permission.videos or Permission.audio depending on what you allow
        return photos.isGranted;
      } else {
        // Android < 13 uses standard storage permission
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    }
    return false;
  }

  Future<void> _pickFiles() async {
    // 1. Check Permission
    final hasPermission = await _requestPermission();

    if (!hasPermission && mounted) {
      // Show dialog to open settings if permanently denied
      _showPermissionDialog();
      return;
    }

    // 2. Pick Files
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        setState(() {
          // Combine existing files with new ones, avoiding duplicates if needed
          _selectedFiles = [..._selectedFiles, ...result.files];
        });
      }
    } catch (e) {
      debugPrint("File picker error: $e");
    }
  }

  void _removeFile(PlatformFile file) {
    setState(() {
      _selectedFiles.removeWhere((f) => f == file);
    });
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'We need storage access to upload attachments. Please enable it in settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // ================= DATE PICKER =================
  Future<void> _pickDate({required bool isFromDate}) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1);
    final lastDate = DateTime(now.year + 2);

    final picked = await showDatePicker(
      context: context,
      initialDate: isFromDate
          ? (_fromDate ?? now)
          : (_toDate ?? _fromDate ?? now),
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.green),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          // Auto-adjust 'To' date if it's before 'From'
          if (_toDate != null && _toDate!.isBefore(picked)) {
            _toDate = null;
          }
        } else {
          _toDate = picked;
        }
      });
    }
  }

  // ================= SUBMIT LOGIC =================
  Future<void> submitRequest() async {
    if (_currentUser == null) return;

    if (_selectedType == null || _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a type and enter a reason'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_fromDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a start date'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Convert PlatformFile to File
      final files = _selectedFiles
          .where((f) => f.path != null)
          .map((f) => File(f.path!))
          .toList();

      final selectedEnum = RequestType.values.firstWhere(
        (e) => e.toTextString() == _selectedType,
        orElse: () => RequestType.OTHER,
      );

      if (_isEditing) {
        if (!_isEditable)
          throw Exception('Only pending requests can be edited');

        final request = Request(
          id: widget.initialRequest!.id,
          userId: _currentUser!.id,
          type: selectedEnum,
          fromDate: _fromDate,
          toDate: _toDate,
          reason: _reasonController.text.trim(),
          attachments: widget.initialRequest!.attachments,
          status: widget.initialRequest!.status,
        );

        await RequestService().updateRequest(request, files);
      } else {
        final request = Request(
          userId: _currentUser!.id,
          type: selectedEnum,
          fromDate: _fromDate,
          toDate: _toDate,
          reason: _reasonController.text.trim(),
        );

        await RequestService().createRequest(request, files);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Request updated' : 'Request created'),
          ),
        );
        Navigator.pop(context, true); // Return true to trigger refresh on list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ================= UI BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: Text(
          _isEditing ? 'Edit Request' : 'New Request',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Request Type'),
                    _buildDropdown(),

                    const SizedBox(height: 24),
                    _sectionLabel('Duration'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateInput(
                            label: 'From',
                            date: _fromDate,
                            onTap: () => _pickDate(isFromDate: true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDateInput(
                            label: 'To (Optional)',
                            date: _toDate,
                            onTap: () => _pickDate(isFromDate: false),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    _sectionLabel('Reason'),
                    _buildReasonInput(),

                    const SizedBox(height: 24),
                    _buildAttachmentsSection(),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        isExpanded: true,
        hint: const Text(
          'Select Type',
          style: TextStyle(color: Colors.black54),
        ),
        value: _selectedType,
        items: _requestTypes
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(item, style: const TextStyle(fontSize: 15)),
              ),
            )
            .toList(),
        onChanged: (value) => setState(() => _selectedType = value),
        buttonStyleData: ButtonStyleData(
          height: 50,
          padding: const EdgeInsets.only(left: 14, right: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.white,
          ),
          elevation: 0,
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          elevation: 4,
        ),
        dropdownSearchData: DropdownSearchData(
          searchController: _searchController,
          searchInnerWidgetHeight: 50,
          searchInnerWidget: Padding(
            padding: const EdgeInsets.all(8),
            child: TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                hintText: 'Search...',
                hintStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          searchMatchFn: (item, searchValue) {
            return item.value.toString().toLowerCase().contains(
              searchValue.toLowerCase(),
            );
          },
        ),
        onMenuStateChange: (isOpen) {
          if (!isOpen) _searchController.clear();
        },
      ),
    );
  }

  Widget _buildDateInput({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: Colors.green,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (date == null)
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 14,
                      ),
                    )
                  else
                    Text(
                      '${date.day}/${date.month}/${date.year}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonInput() {
    return TextFormField(
      controller: _reasonController,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: 'Why do you need this request?',
        hintStyle: const TextStyle(color: Colors.black38),
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.green),
        ),
      ),
    );
  }

  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionLabel('Attachments'),
            TextButton.icon(
              onPressed: _pickFiles,
              icon: const Icon(Icons.attach_file, size: 18),
              label: const Text('Add Files'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        if (_selectedFiles.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedFiles.map((file) {
              return Chip(
                label: Text(
                  file.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => _removeFile(file),
                backgroundColor: Colors.green.shade50,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }).toList(),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Text(
              'No files attached',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black38, fontSize: 13),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isLoading ? null : submitRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Submit Request',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
