import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qr_attendance_frontend/src/models/office_config.dart';

class OfficeFormPage extends StatefulWidget {
  final OfficeConfig? office;

  const OfficeFormPage({super.key, this.office});

  @override
  State<OfficeFormPage> createState() => _OfficeFormPageState();
}

class _OfficeFormPageState extends State<OfficeFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _radiusController;
  late TextEditingController _wifiController;
  
  LatLng? _selectedLocation;
  final MapController _mapController = MapController();
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.office?.name ?? '');
    _radiusController = TextEditingController(
        text: widget.office?.radius.toString() ?? '100');
    _wifiController = TextEditingController(text: widget.office?.wifiSsid ?? '');
    
    if (widget.office != null) {
      _selectedLocation = LatLng(widget.office!.latitude, widget.office!.longitude);
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Try to request service? Or just notify user
        // For now, just throw or let user know
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _mapController.move(_selectedLocation!, 15);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
      // Default to a fallback location if needed (e.g. Hanoi)
      if (_selectedLocation == null) {
         setState(() {
           _selectedLocation = const LatLng(21.0285, 105.8542); 
           _mapController.move(_selectedLocation!, 15);
         });
      }
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _radiusController.dispose();
    _wifiController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState!.validate() && _selectedLocation != null) {
      final data = {
        'name': _nameController.text,
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'radius': double.parse(_radiusController.text),
        'wifiSsid': _wifiController.text.isEmpty ? null : _wifiController.text,
      };
      Navigator.pop(context, data);
    } else if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location on the map')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.office == null ? 'Add Office' : 'Edit Office'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _onSave,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLocation ?? const LatLng(21.0285, 105.8542),
                    initialZoom: 15,
                    onTap: (_, point) {
                      setState(() {
                        _selectedLocation = point;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.qr_attendance_frontend',
                    ),
                    if (_selectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLocation!,
                            width: 80,
                            height: 80,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                     if (_selectedLocation != null)
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: _selectedLocation!,
                              color: Colors.blue.withOpacity(0.3),
                              borderStrokeWidth: 2,
                              borderColor: Colors.blue,
                              useRadiusInMeter: true,
                              radius: double.tryParse(_radiusController.text) ?? 100,
                            ),
                          ],
                        ),
                  ],
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    onPressed: _getCurrentLocation,
                    child: _isLoadingLocation 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Office Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _radiusController,
                      decoration: const InputDecoration(
                        labelText: 'Radius (meters)',
                        border: OutlineInputBorder(),
                        helperText: 'Distance allowed for check-in',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (val) => setState(() {}), // Update circle on map
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Required';
                        if (double.tryParse(value!) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _wifiController,
                      decoration: const InputDecoration(
                        labelText: 'WiFi SSID (Optional)',
                        border: OutlineInputBorder(),
                        helperText: 'Restrict check-in to specific WiFi',
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_selectedLocation != null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Text('Selected Location', style: Theme.of(context).textTheme.titleSmall),
                              Text('Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}'),
                              Text('Long: ${_selectedLocation!.longitude.toStringAsFixed(6)}'),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
