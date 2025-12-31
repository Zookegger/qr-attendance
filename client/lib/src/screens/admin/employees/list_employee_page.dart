import 'package:flutter/material.dart';
import 'package:qr_attendance_frontend/src/models/user.dart';
import 'package:qr_attendance_frontend/src/services/admin.service.dart';

class EmployeeListPage extends StatefulWidget {
  const EmployeeListPage({super.key});

  @override
  State<StatefulWidget> createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends State<EmployeeListPage> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _allUsers = [];
  List<User> _filteredUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final users = await AdminService().getUsers();

    setState(() {
      _allUsers = users;
      _filteredUsers = users;
      _isLoading = false;
    });
  }

  void _runSearch(String query) {
    final results = _allUsers.where((user) {
      final nameLower = user.name.toLowerCase();
      final queryLower = query.toLowerCase();
      return nameLower.contains(queryLower);
    }).toList();

    setState(() {
      _filteredUsers = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          onChanged: _runSearch, // 3. Listen to typing
          decoration: const InputDecoration(
            hintText: 'Search employees...',
            border: InputBorder.none,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                // The TILE is Stateless, but the LIST is Stateful
                return EmployeeTile(user: _filteredUsers[index]);
              },
            ),
      floatingActionButton: _buildAddButton(context),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return SizedBox(
      width: 65,
      height: 65,
      child: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/employee/form');
        },
        elevation: 1,
        clipBehavior: Clip.hardEdge,
        child: const Icon(Icons.add, fontWeight: FontWeight.bold, size: 24),
      ),
    );
  }
}

class EmployeeTile extends StatelessWidget {
  final User user;
  final VoidCallback? onTap;

  const EmployeeTile({super.key, required this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isInactive = user.status != UserStatus.ACTIVE;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer, // Subtle background
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isInactive
            ? BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              _buildAvatar(theme),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isInactive ? theme.disabledColor : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildRoleBadge(theme),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _buildSubtitle(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    final initials = user.name.isNotEmpty
        ? user.name
              .trim()
              .split(' ')
              .take(2)
              .map((e) => e[0])
              .join()
              .toUpperCase()
        : '?';

    Color bgColor;
    if (user.status == UserStatus.INACTIVE) {
      bgColor = theme.disabledColor;
    } else {
      // Use primary color for Admins, secondary/tertiary for others to distinguish
      bgColor = user.role == UserRole.ADMIN
          ? theme.colorScheme.primary
          : theme.colorScheme.secondaryContainer;
    }

    Color fgColor =
        user.role == UserRole.ADMIN || user.status == UserStatus.INACTIVE
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSecondaryContainer;

    return CircleAvatar(
      radius: 24,
      backgroundColor: bgColor,
      child: Text(
        initials,
        style: TextStyle(
          color: fgColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildRoleBadge(ThemeData theme) {
    if (user.role == UserRole.USER) return const SizedBox.shrink();

    Color color;
    switch (user.role) {
      case UserRole.ADMIN:
        color = Colors.redAccent;
        break;
      case UserRole.MANAGER:
        color = Colors.orangeAccent;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        user.role.name,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];

    if (user.position != null && user.position!.isNotEmpty) {
      parts.add(user.position!);
    }

    if (user.department != null && user.department!.isNotEmpty) {
      parts.add(user.department!);
    }

    if (parts.isEmpty) {
      return user.email;
    }

    return parts.join(' • ');
  }
}
