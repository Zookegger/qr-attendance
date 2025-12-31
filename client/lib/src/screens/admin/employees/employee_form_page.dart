import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../models/user.dart';
import '../../../services/admin.service.dart';

class EmployeeFormPage extends StatefulWidget {
  final User? user; // If null, we are in "Create" mode

  const EmployeeFormPage({super.key, this.user});

  @override
  State<EmployeeFormPage> createState() => _EmployeeFormPageState();
}

class _EmployeeFormPageState extends State<EmployeeFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(); // Only for create
  final _positionController = TextEditingController();
  final _departmentController = TextEditingController();
  final _phoneController = TextEditingController();

  // Field errors coming from backend validation (param -> message)
  final Map<String, String?> _fieldErrors = {};
  // Dropdown Values
  UserRole _selectedRole = UserRole.USER;
  UserStatus _selectedStatus = UserStatus.ACTIVE;
  Gender _selectedGender = Gender.UNKNOWN;

  bool get isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _populateFields(widget.user!);
    }
  }

  void _populateFields(User user) {
    _nameController.text = user.name;
    _emailController.text = user.email;
    _positionController.text = user.position ?? '';
    _departmentController.text = user.department ?? '';
    _phoneController.text = user.phoneNumber ?? '';
    _selectedRole = user.role;
    _selectedStatus = user.status;
    _selectedGender = user.gender ?? Gender.UNKNOWN;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // clear previous server-side errors
    _fieldErrors.clear();
    setState(() => _isLoading = true);

    try {
      final data = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRole.name.toUpperCase(),
        'position': _positionController.text.trim(),
        'department': _departmentController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'gender': _selectedGender.name.toUpperCase(),
      };

      if (isEditing) {
        // Update Logic
        data['status'] = _selectedStatus.name.toUpperCase();
        // Only send password if you want to allow resetting it here (optional)
        // if (_passwordController.text.isNotEmpty) data['password'] = ...
        
        await AdminService().updateUser(widget.user!.id, data);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully')),
        );
      } else {
        // Create Logic
        data['password'] = _passwordController.text; // Required for new users
        data['status'] = UserStatus.ACTIVE.name.toUpperCase(); // Default for new
        
        await AdminService().createUser(data);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User created successfully')),
        );
      }

      Navigator.pop(context, true); // Return 'true' to trigger refresh
    } catch (e) {
      if (e is DioException) {
        final resp = e.response!.data;
        // express-validator returns { errors: [ { msg, param, ... } ] }
        if (resp is Map && resp['errors'] is List) {
          final List errs = resp['errors'] as List;
          for (var item in errs) {
            if (item is Map && item['param'] != null && item['msg'] != null) {
              _fieldErrors[item['param'].toString()] = item['msg'].toString();
            }
          }
          if (mounted) setState(() {});
        } else if (resp is Map && resp['message'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${resp['message']}'), backgroundColor: Colors.red),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.message}'), backgroundColor: Colors.red),
          );
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Employee' : 'New Employee'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('Basic Info'),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person),
                  errorText: _fieldErrors['name'],
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  errorText: _fieldErrors['email'],
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              
              // Password Field (Only show when creating a new user)
              if (!isEditing) 
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    errorText: _fieldErrors['password'],
                  ),
                  obscureText: true,
                  validator: (v) => v == null || v.length < 6 ? 'Min 6 chars' : null,
                ),

              const SizedBox(height: 24),
              _buildSectionTitle('Role & Status'),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<UserRole>(
                      initialValue: _selectedRole,
                      decoration: InputDecoration(labelText: 'Role', errorText: _fieldErrors['role']),
                      items: UserRole.values.map((role) {
                        return DropdownMenuItem(value: role, child: Text(UserRole.toTextString(role)));
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedRole = v!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<UserStatus>(
                      initialValue: _selectedStatus,
                      decoration: const InputDecoration(labelText: 'Status'),
                      // Disable status change for new users (default active)
                      onChanged: isEditing ? (v) => setState(() => _selectedStatus = v!) : null,
                      items: UserStatus.values.map((status) {
                        return DropdownMenuItem(value: status, child: Text(UserStatus.toTextString(status)));
                      }).toList(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Job Details'),
              TextFormField(
                controller: _positionController,
                decoration: InputDecoration(labelText: 'Position', prefixIcon: const Icon(Icons.badge), errorText: _fieldErrors['position']),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _departmentController,
                decoration: InputDecoration(labelText: 'Department', prefixIcon: const Icon(Icons.apartment), errorText: _fieldErrors['department']),
              ),

              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading 
                    ? const CircularProgressIndicator() 
                    : Text(isEditing ? 'Save Changes' : 'Create User'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}