import 'dart:io';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CreateRequestPage extends StatefulWidget {
  const CreateRequestPage({super.key});

  @override
  State<CreateRequestPage> createState() => _CreateRequestPageState();
}

class _CreateRequestPageState extends State<CreateRequestPage> {
  DateTime? _fromDate;
  DateTime? _toDate;

  Future<void> _pickDate({required bool isFromDate}) async {
    final initialDate = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
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

  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  String? _selectedType;
  final TextEditingController _reasonController = TextEditingController();

  final TextEditingController _searchController = TextEditingController();

  final List<String> _requestTypes = [
    'Đơn nghỉ phép',
    'Đơn nghỉ ốm',
    'Đơn nghỉ không lương',
    'Đơn đi trễ / về sớm',
    'Đơn làm thêm giờ (OT)',
    'Đơn công tác',
    'Đơn đổi ca làm',
    'Đơn xin làm việc từ xa',
    'Đơn xin cấp thiết bị',
    'Đơn xin cấp tài khoản hệ thống',
    'Đơn xin tạm ứng lương',
    'Đơn xin thanh toán / hoàn ứng',
    'Đơn xin xác nhận công',
    'Đơn xin điều chỉnh chấm công',
    'Đơn giải trình',
    'Khác...',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: const Text('Tạo đơn', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 1. Chọn loại đơn
            const Text(
              '1. Chọn loại đơn',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton2<String>(
                  isExpanded: true,
                  hint: const Text('Chọn loại đơn'),
                  value: _selectedType,
                  items: _requestTypes
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(
                            item,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedType = value);
                  },

                  // 👇 GIỚI HẠN CHIỀU CAO + SCROLL
                  dropdownStyleData: DropdownStyleData(
                    maxHeight: 280,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),

                  // 👇 SEARCH
                  dropdownSearchData: DropdownSearchData(
                    searchController: _searchController,
                    searchInnerWidgetHeight: 50,
                    searchInnerWidget: Padding(
                      padding: const EdgeInsets.all(8),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm loại đơn...',
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
              ),
            ),

            const SizedBox(height: 24),

            /// 2. Thời gian
            const Text(
              '2. Thời gian',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                _buildDateBox(
                  label: 'Từ ngày',
                  date: _fromDate,
                  onTap: () => _pickDate(isFromDate: true),
                ),
                const SizedBox(width: 12),
                _buildDateBox(
                  label: 'Đến ngày',
                  date: _toDate,
                  onTap: () => _pickDate(isFromDate: false),
                ),
              ],
            ),

            const SizedBox(height: 24),

            /// 3. Lý do
            const Text(
              '3. Lý do',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _reasonController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Nhập lý do nghỉ...',
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// Upload hình
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Hình ảnh minh chứng (Nếu có)',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
                InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.camera_alt_outlined, size: 18),
                        SizedBox(width: 6),
                        Text('Tải ảnh lên'),
                      ],
                    ),
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
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: submit form + upload image sau
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Gửi đơn",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// Tạo đơn mới
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                  });
                },
                child: const Text("Tạo đơn mới"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildDateBox({
  required String label,
  required DateTime? date,
  required VoidCallback onTap,
}) {
  return Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          date == null
              ? label
              : '$label: ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}',
          style: TextStyle(color: date == null ? Colors.grey : Colors.black),
        ),
      ),
    ),
  );
}
