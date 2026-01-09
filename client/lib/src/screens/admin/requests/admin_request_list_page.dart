import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../blocs/request/request_bloc.dart';
import '../../../blocs/request/request_event.dart';
import '../../../blocs/request/request_state.dart';
import '../../../models/request.dart';
import '../../../models/user.dart';
import '../../../services/admin.service.dart';
import 'admin_request_detail_page.dart';

class AdminRequestListPage extends StatelessWidget {
  const AdminRequestListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RequestBloc()..add(const RequestsFetchAll()),
      child: const _AdminRequestListPageContent(),
    );
  }
}

class _AdminRequestListPageContent extends StatefulWidget {
  const _AdminRequestListPageContent();

  @override
  State<_AdminRequestListPageContent> createState() =>
      _AdminRequestListPageContentState();
}

class _AdminRequestListPageContentState
    extends State<_AdminRequestListPageContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, User> _userMap = {};
  bool _usersLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_filterRequests);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await AdminService().getUsers();
      if (mounted) {
        setState(() {
          _userMap = {for (var u in users) u.id: u};
          _usersLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
    }
  }

  void _filterRequests() {
    if (!mounted) return;

    String? statusFilter;
    switch (_tabController.index) {
      case 0:
        statusFilter = 'PENDING';
        break;
      case 1:
        statusFilter = 'APPROVED';
        break;
      case 2:
        statusFilter = 'REJECTED';
        break;
    }

    context.read<RequestBloc>().add(RequestFilterChanged(status: statusFilter));
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

    if (result == true && context.mounted) {
      context.read<RequestBloc>().add(const RequestsFetchAll());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_usersLoaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Request Management')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
      body: BlocConsumer<RequestBloc, RequestState>(
        listener: (context, state) {
          if (state is RequestError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is RequestLoading || state is RequestInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is RequestLoaded) {
            if (state.filteredRequests.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: state.filteredRequests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final req = state.filteredRequests[index] as Request;
                return _AdminRequestTile(
                  request: req,
                  user: _userMap[req.userId],
                  onTap: () => _showRequestDetail(req),
                );
              },
            );
          }

          return const Center(child: Text('Something went wrong'));
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
