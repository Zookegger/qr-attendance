import 'package:flutter/material.dart';
import '../../../models/user.dart';
import '../../../services/admin.service.dart';

class EmployeeDetailsPage extends StatefulWidget {
  final User user;

  const EmployeeDetailsPage({super.key, required this.user});

  @override
  State<EmployeeDetailsPage> createState() => _EmployeeDetailsPageState();
}

class _EmployeeDetailsPageState extends State<EmployeeDetailsPage> {
  late User _user;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  // --- ACTIONS ---

  void _onEditPressed() {
    // Navigate to a Form Page (Reused for Create and Edit)
    Navigator.pushNamed(context, '/employee/form', arguments: _user).then((
      updatedUser,
    ) {
      if (updatedUser != null && updatedUser is User) {
        setState(() => _user = updatedUser);
      }
    });
  }

  Future<void> _onUnbindDevice() async {
    final confirm = await _showConfirmDialog(
      title: 'Unbind Device?',
      content:
          'The user will be logged out of their current device immediately.',
      isDangerous: true,
    );
    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
      await AdminService().unbindDevice(_user.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device unbound successfully')),
      );
      // Update local state to reflect change (optional, or re-fetch)
      // setState(() => _user = _user.copyWith(deviceUuid: null));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onDeleteUser() async {
    final confirm = await _showConfirmDialog(
      title: 'Delete User?',
      content: 'This action cannot be undone.',
      isDangerous: true,
    );
    if (!confirm) return;

    try {
      // await AdminService().deleteUser(_user.id); // Add this to your service
      if (!mounted) return;
      Navigator.pop(context, true); // Return 'true' to indicate deletion
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // --- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _onEditPressed,
            tooltip: 'Edit User',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(),
                const Divider(height: 32),
                _buildSectionTitle('Contact Info'),
                _buildInfoTile(Icons.email, 'Email', _user.email),
                _buildInfoTile(
                  Icons.phone,
                  'Phone',
                  _user.phoneNumber ?? 'N/A',
                ),
                _buildInfoTile(
                  Icons.location_on,
                  'Address',
                  _user.address ?? 'N/A',
                ),
                const Divider(height: 32),
                _buildSectionTitle('Work Info'),
                _buildInfoTile(
                  Icons.badge,
                  'Position',
                  _user.position ?? 'N/A',
                ),
                _buildInfoTile(
                  Icons.apartment,
                  'Department',
                  _user.department ?? 'N/A',
                ),
                _buildInfoTile(Icons.cake, 'DOB', _user.dateOfBirth ?? 'N/A'),
                const Divider(height: 32),
                _buildDeviceSection(),
                const SizedBox(height: 40),
                OutlinedButton.icon(
                  onPressed: _onDeleteUser,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Delete User'),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              _user.name.substring(0, 1).toUpperCase(),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _user.name,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _user.role == UserRole.ADMIN
                  ? Colors.red.withOpacity(0.1)
                  : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _user.role.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _user.role == UserRole.ADMIN ? Colors.red : Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSection() {
    final hasDevice = _user.deviceUuid != null && _user.deviceUuid!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Device Binding'),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            hasDevice ? Icons.phonelink_lock : Icons.phonelink_off,
            color: hasDevice ? Colors.green : Colors.grey,
          ),
          title: Text(hasDevice ? 'Device Bound' : 'No Device Bound'),
          subtitle: hasDevice
              ? Text(
                  'Model: ${_user.deviceModel ?? "Unknown"}\nUUID: ${_user.deviceUuid}',
                )
              : const Text('User can login from any new device.'),
          trailing: hasDevice
              ? IconButton(
                  icon: const Icon(Icons.link_off, color: Colors.orange),
                  onPressed: _onUnbindDevice,
                  tooltip: 'Unbind Device',
                )
              : null,
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      subtitle: Text(value, style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String content,
    required bool isDangerous,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  isDangerous ? 'Confirm' : 'OK',
                  style: TextStyle(color: isDangerous ? Colors.red : null),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}
