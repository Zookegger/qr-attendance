import 'package:flutter/material.dart';

import 'package:qr_attendance_frontend/src/models/request.dart';
import 'package:qr_attendance_frontend/src/models/user.dart';
import 'package:qr_attendance_frontend/src/services/request.service.dart';
import 'package:qr_attendance_frontend/src/services/auth.service.dart';

class RequestListPage extends StatefulWidget {
  const RequestListPage({super.key});

  @override
  State<RequestListPage> createState() => _RequestListPageState();
}

class _RequestListPageState extends State<RequestListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  List<Request> _allRequests = [];
  List<Request> _filteredRequests = [];

  String _filterType = 'All';

  final AuthenticationService _auth = AuthenticationService();

  final List<String> _types = [
    'All',
    ...RequestType.values.map((e) => e.toTextString()),
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
      final data = await RequestService().listRequests(userId: user.id);
      for (var r in data) {}
      if (mounted) {
        setState(() {
          _allRequests = data;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e, s) {
      debugPrint('Load history error: $e');
      debugPrint('Stacktrace: $s');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load requests: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  // ================= FILTER LOGIC =================
  void _applyFilters() {
    if (!mounted) return; // Safety check

    List<Request> list = [..._allRequests];

    // Filter by TAB
    switch (_tabController.index) {
      case 1: // Submitted
        list = list.where((r) => r.status == RequestStatus.PENDING).toList();
        break;
      case 2: // Approved
        list = list.where((r) => r.status == RequestStatus.APPROVED).toList();
        break;
    }

    // Filter by TYPE
    if (_filterType != 'All') {
      list = list.where((r) => r.type.toTextString() == _filterType).toList();
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
        title: const Text(
          'Request List',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        // --- ACTION BUTTON ADDED HERE ---
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.filter_list,
              color: _filterType == 'All' ? Colors.black : Colors.green,
            ),
            tooltip: 'Filter by type',
            onSelected: (String value) {
              setState(() {
                _filterType = value;
              });
              _applyFilters();
            },
            itemBuilder: (BuildContext context) {
              return _types.map((String choice) {
                final isSelected = _filterType == choice;
                return PopupMenuItem<String>(
                  value: choice,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        choice,
                        style: TextStyle(
                          color: isSelected ? Colors.green : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check, color: Colors.green, size: 18),
                    ],
                  ),
                );
              }).toList();
            },
          ),
          const SizedBox(width: 8),
        ],
        // --------------------------------
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
      // Cleaned up body: No more Column/Expanded needed
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildList(),
      floatingActionButton: _buildNewRequestButton(context),
    );
  }

  Widget _buildNewRequestButton(BuildContext context) {
    return SizedBox(
      width: 65,
      height: 65,
      child: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/user/requests/form');
        },
        elevation: 1,
        clipBehavior: Clip.hardEdge,
        child: const Icon(Icons.add, fontWeight: FontWeight.bold, size: 24),
      ),
    );
  }

  // ================= LIST =================
  Widget _buildList() {
    if (_filteredRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 48, color: Colors.black26),
            const SizedBox(height: 12),
            Text(
              _filterType == 'All'
                  ? 'No requests found'
                  : 'No ${_filterType.toLowerCase()}s found',
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredRequests.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, index) => _buildRequestItem(_filteredRequests[index]),
      ),
    );
  }

  // ================= ITEM =================
  Widget _buildRequestItem(Request request) {
    return InkWell(
      onTap: () {
        // TODO: Open detail
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
                    request.type.toTextString(),
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
            if (request.reason != null && request.reason!.isNotEmpty)
              Text(
                request.reason!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
          ],
        ),
      ),
    );
  }

  // ================= STATUS & HELPERS =================
  Widget _buildStatus(RequestStatus? status) {
    Color color;
    String text;

    switch (status) {
      case RequestStatus.APPROVED:
        color = Colors.green;
        text = 'Approved';
        break;
      case RequestStatus.REJECTED:
        color = Colors.red;
        text = 'Rejected';
        break;
      case RequestStatus.PENDING:
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
