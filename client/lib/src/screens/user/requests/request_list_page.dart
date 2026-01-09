import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qr_attendance_frontend/src/blocs/request/request_bloc.dart';
import 'package:qr_attendance_frontend/src/blocs/request/request_event.dart';
import 'package:qr_attendance_frontend/src/blocs/request/request_state.dart';
import 'package:qr_attendance_frontend/src/models/request.dart';
import 'package:qr_attendance_frontend/src/screens/user/requests/request_detail_page.dart';

class RequestListPage extends StatelessWidget {
  const RequestListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RequestBloc()..add(const RequestsFetchByUser(userId: '')),
      child: const _RequestListPageContent(),
    );
  }
}

class _RequestListPageContent extends StatefulWidget {
  const _RequestListPageContent();

  @override
  State<_RequestListPageContent> createState() => _RequestListPageContentState();
}

class _RequestListPageContentState extends State<_RequestListPageContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filterType = 'All';

  final List<String> _types = [
    'All',
    ...RequestType.values.map((e) => e.toTextString()),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ================= FILTER LOGIC =================
  void _applyFilters() {
    if (!mounted) return;

    String? statusFilter;
    switch (_tabController.index) {
      case 1:
        statusFilter = 'PENDING';
        break;
      case 2:
        statusFilter = 'APPROVED';
        break;
    }

    final typeFilter = _filterType == 'All' ? null : _filterType;
    
    context.read<RequestBloc>().add(RequestFilterChanged(
      status: statusFilter,
      type: typeFilter,
    ));
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
            return _buildList(state.filteredRequests);
          }
          
          return const Center(child: Text('Something went wrong'));
        },
      ),
      floatingActionButton: _buildNewRequestButton(context),
    );
  }

  Widget _buildNewRequestButton(BuildContext context) {
    return SizedBox(
      width: 65,
      height: 65,
      child: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/user/requests/form');
          if (result == true && context.mounted) {
            context.read<RequestBloc>().add(const RequestsFetchByUser(userId: ''));
          }
        },
        elevation: 1,
        clipBehavior: Clip.hardEdge,
        child: const Icon(Icons.add, fontWeight: FontWeight.bold, size: 24),
      ),
    );
  }

  // ================= LIST =================
  Widget _buildList(List<dynamic> filteredRequests) {
    if (filteredRequests.isEmpty) {
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
      onRefresh: () async {
        context.read<RequestBloc>().add(const RequestsFetchByUser(userId: ''));
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: filteredRequests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) => _buildRequestItem(filteredRequests[index] as Request),
      ),
    );
  }

  // ================= ITEM =================
  Widget _buildRequestItem(Request request) {
    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RequestDetailPage(request: request),
          ),
        );
        // Reload list if changes occurred
        if (result == true && context.mounted) {
          context.read<RequestBloc>().add(const RequestsFetchByUser(userId: ''));
        }
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
        color: color.withValues(alpha: 0.15),
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
