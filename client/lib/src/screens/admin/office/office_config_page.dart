import 'package:flutter/material.dart';
import 'package:qr_attendance_frontend/src/models/office_config.dart';
import 'package:qr_attendance_frontend/src/services/office_config.service.dart';
import 'package:qr_attendance_frontend/src/screens/admin/office/office_form_page.dart';

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading offices: $e')));
      }
    }
  }

  Future<void> _navigateToOfficeForm([OfficeConfig? office]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OfficeFormPage(office: office)),
    );

    if (result == true) {
      _loadOffices();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Office Configuration')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _offices.isEmpty
              ? const Center(
                  child: Text(
                    "No configuration yet, create a new configuration",
                  ),
                )
              : ListView.builder(
                  itemCount: _offices.length,
                  itemBuilder: (context, index) {
                    final office = _offices[index];
                    return ListTile(
                      title: Text(office.name),
                      subtitle: Text(
                        'Lat: ${office.latitude}, Long: ${office.longitude}\nRadius: ${office.radius}m, WiFi: ${office.wifiSsid ?? "N/A"}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _navigateToOfficeForm(office),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToOfficeForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
