import 'dart:io';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:qr_attendance_frontend/src/models/request.dart';
import 'package:qr_attendance_frontend/src/models/user.dart';
import 'package:qr_attendance_frontend/src/services/RequestService.dart';

class CreateRequestPage extends StatefulWidget {
  final User user;

  const CreateRequestPage({super.key, required this.user});

  @override
  State<CreateRequestPage> createState() => _CreateRequestPageState();
}

class _CreateRequestPageState extends State<CreateRequestPage> {
  DateTime? _fromDate;
  DateTime? _toDate;

  bool _isLoading = false;

  String? _selectedType;
  String? _imageUrl;

  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

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

  // ================= IMAGE PICK =================
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  // ================= IMAGE UPLOAD (MOCK) =================
  Future<String> uploadImage(File image) async {
    // TODO: Implement multer file formdata upload
    throw UnimplementedError("Upload is not implemented");
  }

  // ================= SUBMIT REQUEST =================
  Future<void> submitRequest() async {
    if (_selectedType == null || _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      if (_selectedImage != null) {
        _imageUrl = await uploadImage(_selectedImage!);
      }

      final request = Request(
        userId: widget.user.id,
        type: _selectedType!,
        fromDate: _fromDate,
        toDate: _toDate,
        reason: _reasonController.text.trim(),
        imageUrl: _imageUrl,
      );

      await RequestService().createRequest(request);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request created successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      debugPrint('Error: $e');
      debugPrint('USER ID: ${widget.user.id} (${widget.user.id.runtimeType})');
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
        title: const Text(
          'Create Request',
          style: TextStyle(color: Colors.black),
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
                'Evidence image (optional)',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            InkWell(
              onTap: _pickImage,
              child: Row(
                children: [
                  const Icon(Icons.camera_alt_outlined),
                  const SizedBox(width: 6),
                  const Text('Upload image'),
                ],
              ),
            ),
          ],
        ),
        if (_selectedImage != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _selectedImage!,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
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
