import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/auth.service.dart';
import '../../widgets/common_button.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  User? _user;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final user = await AuthenticationService().me();
      setState(() {
        _user = user;
      });
    } catch (e) {
      // Handle error - maybe show snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Information', icon: Icon(Icons.person)),
            Tab(text: 'Password', icon: Icon(Icons.lock)),
            Tab(text: 'Sessions', icon: Icon(Icons.devices)),
          ],
        ),
      ),
      body: _user == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                UserInformationTab(user: _user!),
                const PasswordChangeTab(),
                const SessionManagementTab(),
              ],
            ),
    );
  }
}

class UserInformationTab extends StatefulWidget {
  final User user;

  const UserInformationTab({super.key, required this.user});

  @override
  State<UserInformationTab> createState() => _UserInformationTabState();
}

class _UserInformationTabState extends State<UserInformationTab> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _positionController;
  late TextEditingController _departmentController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phoneNumber ?? '');
    _addressController = TextEditingController(text: widget.user.address ?? '');
    _positionController = TextEditingController(text: widget.user.position ?? '');
    _departmentController = TextEditingController(text: widget.user.department ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _positionController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Address',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          const Text(
            'Work Information',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _positionController,
            decoration: const InputDecoration(
              labelText: 'Position',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _departmentController,
            decoration: const InputDecoration(
              labelText: 'Department',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text('Role: ${widget.user.role}'),
          const SizedBox(height: 16),
          Text('Status: ${widget.user.status}'),
          const SizedBox(height: 24),
          CommonButton(
            label: 'Save Changes',
            onPressed: () {
              // TODO: Implement save functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile update not implemented yet')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class PasswordChangeTab extends StatefulWidget {
  const PasswordChangeTab({super.key});

  @override
  State<PasswordChangeTab> createState() => _PasswordChangeTabState();
}

class _PasswordChangeTabState extends State<PasswordChangeTab> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Change Password',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enter your current password and choose a new one.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _currentPasswordController,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your current password';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newPasswordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a new password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your new password';
                }
                if (value != _newPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            CommonButton(
              label: 'Change Password',
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // TODO: Implement password change functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password change not implemented yet')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SessionManagementTab extends StatefulWidget {
  const SessionManagementTab({super.key});

  @override
  State<SessionManagementTab> createState() => _SessionManagementTabState();
}

class _SessionManagementTabState extends State<SessionManagementTab> {
  List<Map<String, dynamic>> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    // TODO: Implement session loading from API
    // For now, show mock data
    setState(() {
      _sessions = [
        {
          'id': '1',
          'device': 'iPhone 13',
          'location': 'New York, NY',
          'lastActive': '2024-01-15 10:30 AM',
          'current': true,
        },
        {
          'id': '2',
          'device': 'Chrome Browser',
          'location': 'New York, NY',
          'lastActive': '2024-01-14 3:45 PM',
          'current': false,
        },
        {
          'id': '3',
          'device': 'Android Phone',
          'location': 'Remote',
          'lastActive': '2024-01-10 9:15 AM',
          'current': false,
        },
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Active Sessions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage your active sessions across different devices.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ..._sessions.map((session) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    session['current'] ? Icons.devices : Icons.device_unknown,
                    size: 32,
                    color: session['current'] ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session['device'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          session['location'],
                          style: const TextStyle(color: Colors.grey),
                        ),
                        Text(
                          'Last active: ${session['lastActive']}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        if (session['current'])
                          const Text(
                            'Current session',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!session['current'])
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.red),
                      onPressed: () {
                        // TODO: Implement session revocation
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Revoke session ${session['id']} not implemented yet')),
                        );
                      },
                    ),
                ],
              ),
            ),
          )),
          const SizedBox(height: 24),
          CommonButton(
            label: 'Revoke All Other Sessions',
            onPressed: () {
              // TODO: Implement revoke all sessions
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Revoke all sessions not implemented yet')),
              );
            },
          ),
        ],
      ),
    );
  }
}