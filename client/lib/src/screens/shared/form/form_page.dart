import 'package:flutter/material.dart';

import 'package:qr_attendance_frontend/src/models/request.dart';
import 'package:qr_attendance_frontend/src/models/user.dart';
import 'package:qr_attendance_frontend/src/services/RequestService.dart';
import 'package:qr_attendance_frontend/src/services/auth.service.dart';

class HomeFormPage extends StatefulWidget {
  const HomeFormPage({super.key});

  @override
  State<HomeFormPage> createState() => _HomeFormPageState();
}

class _HomeFormPageState extends State<HomeFormPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  List<Request> _allRequests = [];
  List<Request> _filteredRequests = [];

  String _filterType = 'All';

  final AuthenticationService _auth = AuthenticationService();

  final List<String> _types = [
    'All',
    'Leave request',
    'Sick leave',
    'Unpaid leave',
    'Late arrival / early leave',
    'Overtime request (OT)',
    'Business trip',
    'Other...',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_applyFilters);
    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ================= LOAD DATA =================
  Future<void> _loadRequests() async {
    try {
      final User user = await _auth.getCachedUser() ?? await _auth.me();

      final data = await RequestService().getMyRequests(user.id as int);

      setState(() {
        _allRequests = data;
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      debugPrint('Load history error: $e');
      setState(() => _isLoading = false);
    }
  }

  // ================= FILTER =================
  void _applyFilters() {
    List<Request> list = [..._allRequests];

    // Filter theo TAB
    switch (_tabController.index) {
      case 1: // Đã nộp
        list = list.where((r) => r.status == 'pending').toList();
        break;
      case 2: // Đã duyệt
        list = list.where((r) => r.status == 'approved').toList();
        break;
    }

    // Filter theo loại đơn
    if (_filterType != 'All') {
      list = list.where((r) => r.type == _filterType).toList();
    }

    setState(() => _filteredRequests = list);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: const Text('My Requests', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.green),
            tooltip: 'Create request',
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/forms/create',
              ).then((_) => _loadRequests()); // reload khi quay về
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.green,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Submitted'),
            Tab(text: 'Approved'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilter(),
                Expanded(child: _buildList()),
              ],
            ),
    );
  }

  // ================= FILTER BAR =================
  Widget _buildFilter() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Text('Type:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _filterType,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: _types
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                _filterType = value!;
                _applyFilters();
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================= LIST =================
  Widget _buildList() {
    if (_filteredRequests.isEmpty) {
      return const Center(
        child: Text(
          'No requests found',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredRequests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) => _buildRequestItem(_filteredRequests[index]),
      ),
    );
  }

  // ================= ITEM =================
  Widget _buildRequestItem(Request request) {
    return InkWell(
      onTap: () {
        // TODO: mở chi tiết đơn
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.type,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _buildStatus(request.status),
              ],
            ),
            const SizedBox(height: 8),
            if (request.fromDate != null)
              Text(
                _formatDateRange(request),
                style: const TextStyle(color: Colors.black54),
              ),
            const SizedBox(height: 6),
            Text(
              request.reason ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ================= STATUS =================
  Widget _buildStatus(String? status) {
    Color color;
    String text;

    switch (status) {
      case 'approved':
        color = Colors.green;
        text = 'Approved';
        break;
      case 'rejected':
        color = Colors.red;
        text = 'Rejected';
        break;
      default:
        color = Colors.orange;
        text = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatDateRange(Request r) {
    if (r.fromDate == null) return '';
    final from = '${r.fromDate!.day}/${r.fromDate!.month}/${r.fromDate!.year}';
    if (r.toDate == null) return from;
    final to = '${r.toDate!.day}/${r.toDate!.month}/${r.toDate!.year}';
    return '$from → $to';
  }
}
