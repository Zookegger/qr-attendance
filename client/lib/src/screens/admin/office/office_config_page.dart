import 'package:flutter/material.dart';
import 'package:qr_attendance_frontend/src/models/office_config.dart';
import 'package:qr_attendance_frontend/src/services/office_config.service.dart';

class OfficeConfigPage extends StatefulWidget {
  const OfficeConfigPage({super.key});

  @override
  State<OfficeConfigPage> createState() => _OfficeConfigPageState();
}

class _OfficeConfigPageState extends State<OfficeConfigPage> {
  final OfficeConfigService _officeService = OfficeConfigService();
  List<OfficeConfig> _offices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOffices();
  }

  Future<void> _loadOffices() async {
    try {
      final offices = await _officeService.getOfficeConfigs();
      setState(() {
        _offices = offices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading offices: $e')),
        );
      }
    }
  }

  void _showOfficeDialog([OfficeConfig? office]) {
    showDialog(
      context: context,
      builder: (context) => _OfficeConfigDialog(
        office: office,
        onSave: (data) async {
          try {
            if (office != null) {
              data['id'] = office.id;
            }
            await _officeService.updateOfficeConfig(data);
            if (mounted) {
              Navigator.pop(context);
              _loadOffices();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Office saved successfully')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error saving office: $e')),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Office Configuration'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _offices.length,
              itemBuilder: (context, index) {
                final office = _offices[index];
                return ListTile(
                  title: Text(office.name),
                  subtitle: Text(
                      'Lat: ${office.latitude}, Long: ${office.longitude}\nRadius: ${office.radius}m, WiFi: ${office.wifiSsid ?? "N/A"}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showOfficeDialog(office),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showOfficeDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _OfficeConfigDialog extends StatefulWidget {
  final OfficeConfig? office;
  final Function(Map<String, dynamic>) onSave;

  const _OfficeConfigDialog({this.office, required this.onSave});

  @override
  State<_OfficeConfigDialog> createState() => _OfficeConfigDialogState();
}

class _OfficeConfigDialogState extends State<_OfficeConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _latController;
  late TextEditingController _longController;
  late TextEditingController _radiusController;
  late TextEditingController _wifiController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.office?.name ?? '');
    _latController = TextEditingController(
        text: widget.office?.latitude.toString() ?? '');
    _longController = TextEditingController(
        text: widget.office?.longitude.toString() ?? '');
    _radiusController = TextEditingController(
        text: widget.office?.radius.toString() ?? '100');
    _wifiController = TextEditingController(text: widget.office?.wifiSsid ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _longController.dispose();
    _radiusController.dispose();
    _wifiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.office == null ? 'Add Office' : 'Edit Office'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _latController,
                decoration: const InputDecoration(labelText: 'Latitude'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (double.tryParse(value!) == null) return 'Invalid number';
                  return null;
                },
              ),
              TextFormField(
                controller: _longController,
                decoration: const InputDecoration(labelText: 'Longitude'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (double.tryParse(value!) == null) return 'Invalid number';
                  return null;
                },
              ),
              TextFormField(
                controller: _radiusController,
                decoration: const InputDecoration(labelText: 'Radius (meters)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (double.tryParse(value!) == null) return 'Invalid number';
                  return null;
                },
              ),
              TextFormField(
                controller: _wifiController,
                decoration: const InputDecoration(labelText: 'WiFi SSID (Optional)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave({
                'name': _nameController.text,
                'latitude': double.parse(_latController.text),
                'longitude': double.parse(_longController.text),
                'radius': double.parse(_radiusController.text),
                'wifiSsid': _wifiController.text.isEmpty ? null : _wifiController.text,
              });
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
