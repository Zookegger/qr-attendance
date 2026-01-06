import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:qr_attendance_frontend/src/models/office_config.dart';
import 'package:qr_attendance_frontend/src/services/office_config.service.dart'; // Ensure this path is correct
import 'package:qr_attendance_frontend/src/utils/api_client.dart';

class OfficeFormPage extends StatefulWidget {
  final OfficeConfig? office;

  const OfficeFormPage({super.key, this.office});

  @override
  State<OfficeFormPage> createState() => _OfficeFormPageState();
}

class _OfficeFormPageState extends State<OfficeFormPage> {
  final _formKey = GlobalKey<FormState>();
  // Assuming AdminService handles office configs based on your previous files,
  // but keeping OfficeConfigService if you created it specifically.
  // If not, replace with AdminService().
  final OfficeConfigService _officeService = OfficeConfigService();

  late TextEditingController _nameController;
  late TextEditingController _radiusController;
  late TextEditingController _wifiController;

  LatLng? _selectedLocation;
  final MapController _mapController = MapController();

  // Polygon State
  final List<LatLng> _polygonPoints = [];
  bool _isDrawingPolygon = false;

  bool _isLoadingLocation = false;
  bool _isSaving = false;
  final Map<String, String?> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.office?.name ?? '');
    _radiusController = TextEditingController(
      text: widget.office?.radius.toString() ?? '100',
    );
    _wifiController = TextEditingController(
      text: widget.office?.wifiSsid ?? '',
    );

    if (widget.office != null) {
      _selectedLocation = LatLng(
        widget.office!.latitude,
        widget.office!.longitude,
      );

      // Hydrate polygon points if they exist
      if (widget.office!.polygon != null) {
        _polygonPoints.addAll(
          widget.office!.polygon!.map(
            (p) => LatLng(p['latitude']!, p['longitude']!),
          ),
        );
      }
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location services are disabled. Opening settings...',
              ),
            ),
          );

        // This opens the device's Location Settings page
        await Geolocator.openLocationSettings();

        // We throw here because we can't await the user's action in settings.
        // They need to come back and tap the button again.
        throw Exception(
          'Location services are disabled. Please enable them and try again.',
        );
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
      if (mounted) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _mapController.move(_selectedLocation!, 16);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not get location: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _radiusController.dispose();
    _wifiController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    // 1. Clear previous backend errors
    setState(() => _fieldErrors.clear());

    // 2. Client-side validation
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location on the map'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final data = {
        'name': _nameController.text.trim(),
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'radius': double.parse(_radiusController.text.trim()),
        'wifiSsid': _wifiController.text.trim().isEmpty
            ? null
            : _wifiController.text.trim(),
        'polygon': _polygonPoints
            .map((p) => {'latitude': p.latitude, 'longitude': p.longitude})
            .toList(),
      };

      if (widget.office != null && widget.office!.id != 0) {
        await _officeService.updateOffice(widget.office!.id!, data);
      } else {
        await _officeService.createOffice(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Office saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;

      // 3. Robust Error Handling from Backend
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;

        // Handle Array of Errors (Express Validator)
        if (data is Map && data['errors'] is List) {
          final List errors = data['errors'];
          bool hasFieldErrors = false;

          for (var error in errors) {
            // express-validator v6 uses 'param', v7 uses 'path'
            final field = error['path'] ?? error['param'];
            final msg = error['msg'];

            if (field != null && msg != null) {
              _fieldErrors[field.toString()] = msg.toString();
              hasFieldErrors = true;
            }
          }

          if (hasFieldErrors) {
            // Trigger a rebuild to show errorText in TextFormFields
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please check the form for errors.'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        }

        // Handle Generic Message
        if (data is Map && data['message'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'].toString()),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Fallback generic error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${ApiClient().parseErrorMessage(e)}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Using SingleChildScrollView for the whole body to avoid keyboard overflow
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(widget.office == null ? 'Add Office' : 'Edit Office'),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              // Auto-validate on user interaction for better UX
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Map Section ---
                  _buildMapSection(),
                  const SizedBox(height: 24),

                  // --- Form Fields ---
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Office Name',
                      hintText: 'e.g. Headquarters',
                      prefixIcon: const Icon(Icons.business),
                      border: const OutlineInputBorder(),
                      // Display backend error if present
                      errorText: _fieldErrors['name'],
                    ),
                    validator: (value) => value?.trim().isEmpty ?? true
                        ? 'Office name is required'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _radiusController,
                          decoration: InputDecoration(
                            labelText: 'Radius (m)',
                            prefixIcon: const Icon(Icons.radar),
                            border: const OutlineInputBorder(),
                            helperText: 'Check-in allowed distance',
                            errorText: _fieldErrors['radius'],
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (val) {
                            // Rebuild to update map circle size
                            setState(() {});
                          },
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Required';
                            final n = double.tryParse(value!);
                            if (n == null || n <= 0) return 'Invalid > 0';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _wifiController,
                          decoration: InputDecoration(
                            labelText: 'WiFi SSID (Opt)',
                            prefixIcon: const Icon(Icons.wifi),
                            border: const OutlineInputBorder(),
                            helperText: 'Restrict to specific WiFi',
                            errorText: _fieldErrors['wifiSsid'],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // --- Submit Button ---
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.save),
                      label: const Text(
                        'SAVE OFFICE CONFIGURATION',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // --- Loading Overlay ---
        if (_isSaving)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Location',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (_selectedLocation != null)
              Text(
                '${_selectedLocation!.latitude.toStringAsFixed(5)}, ${_selectedLocation!.longitude.toStringAsFixed(5)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  _fieldErrors.containsKey('latitude') ||
                      _selectedLocation == null
                  ? Colors.red.shade300
                  : Colors.grey.shade300,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter:
                      _selectedLocation ?? const LatLng(21.0285, 105.8542),
                  initialZoom: 16,
                  onTap: (_, point) {
                    setState(() {
                      if (_isDrawingPolygon) {
                        _polygonPoints.add(point);
                      } else {
                        _selectedLocation = point;
                        _fieldErrors.remove('latitude');
                        _fieldErrors.remove('longitude');
                      }
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.qr_attendance_frontend',
                  ),

                  // Polygon Layer
                  if (_polygonPoints.isNotEmpty)
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: _polygonPoints,
                          color: _isDrawingPolygon
                              ? Colors.orange.withValues(alpha: 0.3)
                              : Colors.green.withValues(alpha: 0.2),
                          borderColor: _isDrawingPolygon
                              ? Colors.orange
                              : Colors.green,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),

                  // Polygon Vertices (Visible only when drawing)
                  if (_isDrawingPolygon)
                    MarkerLayer(
                      markers: _polygonPoints
                          .map(
                            (point) => Marker(
                              point: point,
                              width: 12,
                              height: 12,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),

                  if (_selectedLocation != null) ...[
                    // Draw Radius Circle
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _selectedLocation!,
                          color: Colors.blue.withValues(alpha: 0.2),
                          borderStrokeWidth: 2,
                          borderColor: Colors.blue,
                          useRadiusInMeter: true,
                          radius:
                              double.tryParse(_radiusController.text) ?? 100,
                        ),
                      ],
                    ),
                    // Draw Pin
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocation!,
                          width: 50,
                          height: 50,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),

              // Map Controls Overlay
              Positioned(
                right: 12,
                bottom: 12,
                child: FloatingActionButton.small(
                  heroTag: 'getLocation',
                  onPressed: _getCurrentLocation,
                  backgroundColor: Colors.white,
                  child: _isLoadingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location, color: Colors.black87),
                ),
              ),

              // Hint Text Overlay
              if (_selectedLocation == null)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Tap map to select location',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),

              // Drawing Controls
              Positioned(
                top: 12,
                right: 12,
                child: Column(
                  children: [
                    // Mode Toggle
                    FloatingActionButton.small(
                      heroTag: 'toggleMode',
                      tooltip: _isDrawingPolygon
                          ? 'Finish Drawing'
                          : 'Draw Polygon',
                      backgroundColor: _isDrawingPolygon
                          ? Colors.orange
                          : Colors.white,
                      foregroundColor: _isDrawingPolygon
                          ? Colors.white
                          : Colors.black87,
                      onPressed: () {
                        setState(() => _isDrawingPolygon = !_isDrawingPolygon);
                      },
                      child: Icon(
                        _isDrawingPolygon ? Icons.check : Icons.polyline,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Undo Point
                    if (_isDrawingPolygon && _polygonPoints.isNotEmpty) ...[
                      FloatingActionButton.small(
                        heroTag: 'undoPoint',
                        tooltip: 'Undo Last Point',
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        onPressed: () {
                          setState(() {
                            _polygonPoints.removeLast();
                          });
                        },
                        child: const Icon(Icons.undo),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Clear Polygon
                    if (_polygonPoints.isNotEmpty)
                      FloatingActionButton.small(
                        heroTag: 'clearPolygon',
                        tooltip: 'Clear Polygon',
                        backgroundColor: Colors.red.shade100,
                        foregroundColor: Colors.red,
                        onPressed: () {
                          setState(() {
                            _polygonPoints.clear();
                          });
                        },
                        child: const Icon(Icons.delete),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Display backend error for location if exists
        if (_fieldErrors.containsKey('latitude') ||
            _fieldErrors.containsKey('longitude'))
          Padding(
            padding: const EdgeInsets.only(top: 6.0, left: 12.0),
            child: Text(
              _fieldErrors['latitude'] ??
                  _fieldErrors['longitude'] ??
                  'Invalid location',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
