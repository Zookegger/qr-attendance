import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/request.dart';
import '../../../models/user.dart';
import '../../../services/admin.service.dart';
import '../../../services/request.service.dart';
import 'admin_request_detail_page.dart';  

class AdminRequestListPage extends StatefulWidget {
  const AdminRequestListPage({super.key});

  @override
  State<AdminRequestListPage> createState() => _AdminRequestListPageState();
}

class _AdminRequestListPageState extends State<AdminRequestListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Data State
  bool _isLoading = true;
  List<Request> _allRequests = [];
  List<Request> _filteredRequests = [];
  Map<String, User> _userMap = {}; // Cache users to display names

  final RequestService _requestService = RequestService();
  final AdminService _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_filterRequests);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch all users to map IDs to Names
      final users = await _adminService.getUsers();
      _userMap = {for (var u in users) u.id: u};

      // 2. Fetch all requests (passing null to userId implies fetching all if backend supports it)
      // Note: Ensure your backend listRequests returns all records for admins
      final requests = await _requestService.listRequests(); 
      
      // Sort: Pending first, then by date descending
      requests.sort((a, b) {
        if (a.status == RequestStatus.PENDING && b.status != RequestStatus.PENDING) return -1;
        if (a.status != RequestStatus.PENDING && b.status == RequestStatus.PENDING) return 1;
        return (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now());
      });

      if (mounted) {
        setState(() {
          _allRequests = requests;
          _isLoading = false;
        });
        _filterRequests();
      }
    } catch (e) {
      debugPrint('Error loading admin requests: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterRequests() {
    if (!mounted) return;
    List<Request> list = [];

    switch (_tabController.index) {
      case 0: // Pending
        list = _allRequests.where((r) => r.status == RequestStatus.PENDING).toList();
        break;
      case 1: // Approved
        list = _allRequests.where((r) => r.status == RequestStatus.APPROVED).toList();
        break;
      case 2: // Rejected
        list = _allRequests.where((r) => r.status == RequestStatus.REJECTED).toList();
        break;
    }

    setState(() {
      _filteredRequests = list;
    });
  }

  void _showRequestDetail(Request request) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminRequestDetailPage(
          request: request,
          user: _userMap[request.userId],
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Request Management'),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredRequests.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _filteredRequests.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final req = _filteredRequests[index];
                    return _AdminRequestTile(
                      request: req,
                      user: _userMap[req.userId],
                      onTap: () => _showRequestDetail(req),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No requests found',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _AdminRequestTile extends StatelessWidget {
  final Request request;
  final User? user;
  final VoidCallback onTap;

  const _AdminRequestTile({
    required this.request,
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = _formatDateRange(request);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAvatar(theme),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Unknown User',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? 'ID: ${request.userId}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(request.status),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.label_outline, size: 16, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    request.type.toTextString(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(dateStr, style: const TextStyle(color: Colors.black87)),
                ],
              ),
              if (request.reason != null && request.reason!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  request.reason!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    final name = user?.name ?? '?';
    final initials = name.trim().split(' ').take(2).map((e) => e[0]).join().toUpperCase();
    
    return CircleAvatar(
      radius: 20,
      backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
      child: Text(
        initials,
        style: TextStyle(
          color: theme.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(RequestStatus status) {
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
      default:
        color = Colors.orange;
        text = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatDateRange(Request r) {
    if (r.fromDate == null) return 'No Date';
    final f = DateFormat('dd/MM/yyyy');
    if (r.toDate == null || r.toDate == r.fromDate) {
      return f.format(r.fromDate!);
    }
    return '${f.format(r.fromDate!)} - ${f.format(r.toDate!)}';
  }
}
