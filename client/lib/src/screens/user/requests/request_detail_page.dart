import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_attendance_frontend/src/models/request.dart';
import 'package:qr_attendance_frontend/src/services/request.service.dart';
import 'package:qr_attendance_frontend/src/services/config.service.dart';
import 'package:qr_attendance_frontend/src/screens/user/requests/request_form_page.dart';

class RequestDetailPage extends StatefulWidget {
  final Request request;
  const RequestDetailPage({super.key, required this.request});

  @override
  State<RequestDetailPage> createState() => _RequestDetailPageState();
}

class _RequestDetailPageState extends State<RequestDetailPage> {
  late Request _request;
  bool _isLoading = false;
  bool _hasEdited = false;

  @override
  void initState() {
    super.initState();
    _request = widget.request;
  }

  Future<void> _refresh() async {
    if (_request.id == null) return;
    try {
      final data = await RequestService().getRequest(_request.id!);

      if (mounted) {
        setState(() {
          _request = Request.fromJson(data);
        });
      }
    } catch (e) {
      debugPrint('Error refreshing request: $e');
    }
  }

  Future<void> _cancelRequest() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text('Are you sure you want to cancel this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true || _request.id == null) return;

    try {
      setState(() => _isLoading = true);
      await RequestService().cancelRequest(_request.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request cancelled successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate change
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to cancel: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editRequest() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RequestFormPage(initialRequest: _request),
      ),
    );

    if (result == true) {
      _hasEdited = true;
      // Reload if edited
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Request Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context, _hasEdited),
        ),
        actions: [
          if (_request.status == RequestStatus.PENDING)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: _isLoading ? null : _editRequest,
            ),
          if (_request.status == RequestStatus.PENDING)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _isLoading ? null : _cancelRequest,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const Divider(height: 32),
                    _buildDateSection(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Reason'),
                    const SizedBox(height: 8),
                    Text(
                      _request.reason ?? 'No reason provided.',
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                    if (_request.attachments != null &&
                        _request.attachments!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildSectionTitle('Attachments'),
                      const SizedBox(height: 8),
                      _buildAttachmentsList(),
                    ],
                    if (_request.status != RequestStatus.PENDING) ...[
                      const Divider(height: 32),
                      _buildReviewSection(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _request.type.toTextString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildStatusBadge(_request.status),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Created on ${_formatDateTime(_request.createdAt)}',
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(RequestStatus status) {
    Color color;
    Color bgColor;
    String text;
    IconData icon;

    switch (status) {
      case RequestStatus.APPROVED:
        color = Colors.green;
        bgColor = Colors.green.shade50;
        text = 'Approved';
        icon = Icons.check_circle;
        break;
      case RequestStatus.REJECTED:
        color = Colors.red;
        bgColor = Colors.red.shade50;
        text = 'Rejected';
        icon = Icons.cancel;
        break;
      case RequestStatus.PENDING:
        color = Colors.orange;
        bgColor = Colors.orange.shade50;
        text = 'Pending';
        icon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDateItem(
              'From',
              _request.fromDate,
              Icons.calendar_today,
            ),
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.grey.shade300,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Expanded(child: _buildDateItem('To', _request.toDate, Icons.event)),
        ],
      ),
    );
  }

  Widget _buildDateItem(String label, DateTime? date, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.blue.shade700),
            const SizedBox(width: 6),
            Text(
              date != null ? DateFormat('dd MMM yyyy').format(date) : '-',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildAttachmentsList() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _request.attachments!.map((file) {
        // Assume file is a path string, we extract the name
        final name = file.split('/').last.split('\\').last;
        return ActionChip(
          avatar: const Icon(Icons.attach_file, size: 16),
          label: Text(name),
          onPressed: () async {
            try {
              String url = file;
              if (!url.startsWith('http')) {
                final baseUrl = ConfigService().baseUrl;
                var normalized = file.replaceAll('\\', '/');

                // If the path contains 'uploads', we extract everything after it.
                // e.g. /home/server/uploads/requests/image.jpg -> requests/image.jpg
                // Server serves /uploads mapped to the uploads folder.

                if (normalized.contains('/uploads/')) {
                  final parts = normalized.split('/uploads/');
                  // Take the last part which is relative to uploads/
                  // e.g. requests/image.jpg
                  normalized = 'uploads/${parts.last}';
                } else if (normalized.startsWith('uploads/')) {
                  // already relative
                } else {
                  // Fallback: assume it's directly under uploads if no clear marker
                  if (normalized.startsWith('/'))
                    normalized = normalized.substring(1);
                  if (!normalized.startsWith('uploads/')) {
                    normalized = 'uploads/$normalized';
                  }
                }

                // Remove any leading slash just in case
                if (normalized.startsWith('/'))
                  normalized = normalized.substring(1);

                // Construct final URL: http://host:port/uploads/requests/xxx.jpg
                // Ensure baseUrl doesn't end with slash if normalized starts with one (handled above)
                // If baseUrl: http://host:port/api, and we want http://host:port/uploads...
                // Wait, ConfigService().baseUrl usually includes /api ?
                // Let's check ConfigService.

                // Usually baseUrl is http://ip:port/api
                // But the static folder is at http://ip:port/uploads
                // So we need to strip '/api' if present, or just use the host.

                String serverRoot = baseUrl;
                if (serverRoot.endsWith('/api')) {
                  serverRoot = serverRoot.substring(0, serverRoot.length - 4);
                } else if (serverRoot.endsWith('/api/')) {
                  serverRoot = serverRoot.substring(0, serverRoot.length - 5);
                }

                url = '$serverRoot/$normalized';
              }

              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not launch $url')),
                  );
                }
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error opening file: $e')),
                );
              }
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildReviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Review Details'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          decoration: BoxDecoration(
            color: _request.status == RequestStatus.APPROVED
                ? Colors.green.shade50
                : Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _request.status == RequestStatus.APPROVED
                  ? Colors.green.shade200
                  : Colors.red.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _request.status == RequestStatus.APPROVED
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    color: _request.status == RequestStatus.APPROVED
                        ? Colors.green
                        : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Reviewed by ${_request.reviewedBy ?? "Admin"}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (_request.reviewNote != null &&
                  _request.reviewNote!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _request.reviewNote!,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'Unknown';
    return DateFormat('dd MMM yyyy, HH:mm').format(dt);
  }
}
