import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/request.dart';
import '../../../models/user.dart';
import '../../../services/request.service.dart';
import '../../../services/config.service.dart';

class AdminRequestDetailPage extends StatefulWidget {
  final Request request;
  final User? user;

  const AdminRequestDetailPage({super.key, required this.request, this.user});

  @override
  State<AdminRequestDetailPage> createState() => _AdminRequestDetailPageState();
}

class _AdminRequestDetailPageState extends State<AdminRequestDetailPage> {
  late Request _request;
  bool _isLoading = false;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _request = widget.request;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitReview(RequestStatus status) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await RequestService().reviewRequest(
        _request.id!,
        status.name,
        reviewNote: _noteController.text.trim(),
      );

      // Refresh data
      final updatedData = await RequestService().getRequest(_request.id!);
      setState(() {
        _request = Request.fromJson(updatedData);
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request ${status.name.toLowerCase()} successfully'),
            backgroundColor: status == RequestStatus.APPROVED ? Colors.green : Colors.red,
          ),
        );
        Navigator.pop(context, true); // Return true to refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPending = _request.status == RequestStatus.PENDING;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Request Details', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const Divider(height: 32),
            _buildUserInfo(theme),
            const SizedBox(height: 24),
            Text('Duration', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildDateSection(),
            const SizedBox(height: 24),
            Text('Reason', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                _request.reason ?? 'No reason provided.',
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
            if (_request.attachments != null && _request.attachments!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Attachments', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildAttachmentsList(),
            ],
            const Divider(height: 32),
            if (isPending) _buildActionSection() else _buildReviewResult(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
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
    );
  }

  Widget _buildUserInfo(ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
          child: Text(
            (widget.user?.name ?? '?').substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.user?.name ?? 'Unknown User',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              widget.user?.email ?? 'ID: ${_request.userId}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      ],
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
            child: _buildDateItem('From', _request.fromDate, Icons.calendar_today),
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.grey.shade300,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Expanded(
            child: _buildDateItem('To', _request.toDate, Icons.event),
          ),
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
          style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
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

  Widget _buildAttachmentsList() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _request.attachments!.map((file) {
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

                if (normalized.contains('/uploads/')) {
                  final parts = normalized.split('/uploads/');
                  normalized = 'uploads/${parts.last}';
                } else if (normalized.startsWith('uploads/')) {
                  // already relative
                } else {
                   if (normalized.startsWith('/')) normalized = normalized.substring(1);
                   if (!normalized.startsWith('uploads/')) {
                    normalized = 'uploads/$normalized';
                  }
                }

                if (normalized.startsWith('/')) normalized = normalized.substring(1);

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
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not launch $url')),
                  );
                }
              }
            } catch (e) {
              if (mounted) {
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

  Widget _buildActionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Action',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _noteController,
          decoration: InputDecoration(
            labelText: 'Review Note (Optional)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: 'Add a reason for approval or rejection...',
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : () => _submitReview(RequestStatus.REJECTED),
                icon: const Icon(Icons.close),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _submitReview(RequestStatus.APPROVED),
                icon: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check),
                label: _isLoading ? const SizedBox.shrink() : const Text('Approve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewResult() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _request.status == RequestStatus.APPROVED ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _request.status == RequestStatus.APPROVED ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _request.status == RequestStatus.APPROVED ? Icons.check_circle : Icons.cancel,
                color: _request.status == RequestStatus.APPROVED ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 12),
              Text(
                'Request ${_request.status.name}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          if (_request.reviewNote != null && _request.reviewNote!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Review Note:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(_request.reviewNote!),
          ],
          const SizedBox(height: 8),
          Text(
            'Reviewed by: ${_request.reviewedBy ?? "Admin"}',
            style: TextStyle(color: Colors.grey[700], fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
