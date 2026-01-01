import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/request.dart';
import '../../../models/user.dart';
import '../../../services/admin.service.dart';
import '../../../services/request.service.dart';

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

  void _showReviewSheet(Request request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReviewRequestSheet(
        request: request,
        user: _userMap[request.userId],
        onReviewComplete: () {
          Navigator.pop(context);
          _loadData(); // Refresh list after action
        },
      ),
    );
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
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final req = _filteredRequests[index];
                    return _AdminRequestTile(
                      request: req,
                      user: _userMap[req.userId],
                      onTap: () => _showReviewSheet(req),
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
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
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
      backgroundColor: theme.primaryColor.withOpacity(0.1),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
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

class _ReviewRequestSheet extends StatefulWidget {
  final Request request;
  final User? user;
  final VoidCallback onReviewComplete;

  const _ReviewRequestSheet({
    required this.request,
    required this.user,
    required this.onReviewComplete,
  });

  @override
  State<_ReviewRequestSheet> createState() => _ReviewRequestSheetState();
}

class _ReviewRequestSheetState extends State<_ReviewRequestSheet> {
  final TextEditingController _noteController = TextEditingController();
  bool _isProcessing = false;

  Future<void> _submitReview(RequestStatus status) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await RequestService().reviewRequest(
        widget.request.id!,
        status.name,
        reviewNote: _noteController.text.trim(),
      );
      if (mounted) {
        widget.onReviewComplete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final req = widget.request;
    final isPending = req.status == RequestStatus.PENDING;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Review Request',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Employee', widget.user?.name ?? 'Unknown (${req.userId})'),
          _buildInfoRow('Type', req.type.toTextString()),
          _buildInfoRow(
              'Date', 
              '${DateFormat('dd/MM/yyyy').format(req.fromDate ?? DateTime.now())}' 
              '${req.toDate != null ? ' - ${DateFormat('dd/MM/yyyy').format(req.toDate!)}' : ''}'
          ),
          const SizedBox(height: 12),
          const Text('Reason:', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(req.reason ?? 'No reason provided'),
          ),
          
          if (req.attachments != null && req.attachments!.isNotEmpty) ...[
            const SizedBox(height: 16),
             const Text('Attachments:', style: TextStyle(color: Colors.grey)),
             const SizedBox(height: 4),
             Wrap(
               spacing: 8,
               children: req.attachments!.map((f) => Chip(
                 label: Text(f.split('/').last),
                 avatar: const Icon(Icons.attach_file, size: 16),
               )).toList(),
             ),
          ],

          const Divider(height: 32),
          
          if (isPending) ...[
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Review Note (Optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isProcessing ? null : () => _submitReview(RequestStatus.REJECTED),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : () => _submitReview(RequestStatus.APPROVED),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    child: _isProcessing 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Approve'),
                  ),
                ),
              ],
            ),
          ] else ...[
             Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(
                 color: req.status == RequestStatus.APPROVED 
                    ? Colors.green.withOpacity(0.1) 
                    : Colors.red.withOpacity(0.1),
                 borderRadius: BorderRadius.circular(8),
               ),
               child: Row(
                 children: [
                   Icon(
                     req.status == RequestStatus.APPROVED ? Icons.check_circle : Icons.cancel,
                     color: req.status == RequestStatus.APPROVED ? Colors.green : Colors.red,
                   ),
                   const SizedBox(width: 12),
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         'Request ${req.status.name}',
                         style: const TextStyle(fontWeight: FontWeight.bold),
                       ),
                       if (req.reviewNote != null)
                        Text(
                          'Note: ${req.reviewNote}',
                           style: const TextStyle(fontSize: 12),
                        ),
                     ],
                   )
                 ],
               ),
             )
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 80, 
            child: Text(label, style: const TextStyle(color: Colors.grey))
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))
          ),
        ],
      ),
    );
  }
}