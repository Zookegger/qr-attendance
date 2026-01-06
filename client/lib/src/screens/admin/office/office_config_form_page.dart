import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:qr_attendance_frontend/src/models/office_config.dart';
import 'package:qr_attendance_frontend/src/services/office_config.service.dart';
import 'package:qr_attendance_frontend/src/utils/api_client.dart';

enum GeofenceTool { none, drawSafe, drawDanger }

class DrawLayer {
  final String id;
  final bool isExcluded;
  final List<LatLng> points;

  DrawLayer({required this.id, required this.isExcluded, required this.points});

  Color get color => isExcluded
      ? const Color(0x66FF0000) // Red with opacity
      : const Color(0x6600FF00); // Green with opacity

  Color get borderColor => isExcluded ? Colors.red : Colors.green;
}

class OfficeFormPage extends StatefulWidget {
  final OfficeConfig? office;

  const OfficeFormPage({super.key, this.office});

  @override
  State<OfficeFormPage> createState() => _OfficeFormPageState();
}

class _OfficeFormPageState extends State<OfficeFormPage> {
  final _formKey = GlobalKey<FormState>();
  final OfficeConfigService _officeService = OfficeConfigService();

  late TextEditingController _nameController;
  late TextEditingController _wifiController;

  // Location & Map State
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;

  // UI State
  bool _isGeofenceMode = false;
  double _radius = 100.0; // in meters

  // Geofence Drawing State
  final List<DrawLayer> _layers = [];
  GeofenceTool _currentTool = GeofenceTool.none;
  final List<LatLng> _currentDrawingPoints = [];

  bool _isLoadingLocation = false;
  bool _isSaving = false;
  final Map<String, String?> _fieldErrors = {};

  // 1. Remove just the last dot while drawing (The "Oops" button)
  void _undoLastPoint() {
    if (_currentDrawingPoints.isNotEmpty) {
      setState(() {
        _currentDrawingPoints.removeLast();
      });
    }
  }

  // 2. Wipe everything (The "Start Over" button)
  void _clearAllLayers() {
    setState(() {
      _layers.clear();
      _currentDrawingPoints.clear();
      _currentTool = GeofenceTool.none;
    });
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.office?.name ?? '');
    _wifiController = TextEditingController(
      text: widget.office?.wifiSsid ?? '',
    );

    if (widget.office != null) {
      _selectedLocation = LatLng(
        widget.office!.latitude,
        widget.office!.longitude,
      );

      // Initialize Geofence or Radius mode
      if (widget.office!.geofence != null &&
          (widget.office!.geofence!.included.isNotEmpty ||
              widget.office!.geofence!.excluded.isNotEmpty)) {
        _isGeofenceMode = true;
        int idCounter = 0;

        // Parse included
        for (var poly in widget.office!.geofence!.included) {
          final points = poly
              .map((m) => LatLng(m['latitude']!, m['longitude']!))
              .toList();
          _layers.add(
            DrawLayer(
              id: 'inc_${idCounter++}',
              isExcluded: false,
              points: points,
            ),
          );
        }

        // Parse excluded
        for (var poly in widget.office!.geofence!.excluded) {
          final points = poly
              .map((m) => LatLng(m['latitude']!, m['longitude']!))
              .toList();
          _layers.add(
            DrawLayer(
              id: 'exc_${idCounter++}',
              isExcluded: true,
              points: points,
            ),
          );
        }
      } else {
        _isGeofenceMode = false;
        _radius = widget.office!.radius > 0 ? widget.office!.radius : 100.0;
      }
    } else {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _wifiController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled.')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _mapController.move(_selectedLocation!, 17);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _onSave() async {
    setState(() => _fieldErrors.clear());
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_isGeofenceMode && _currentDrawingPoints.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please finish or clear your current drawing first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Optional: Warn if Geofence mode is active but empty
    if (_isGeofenceMode && _layers.isEmpty) {
      // Technically this might default to radius 0 which means nobody can check in, unless there's a implicit rule.
      // Or users just want to define location and add fence later.
    }

    setState(() => _isSaving = true);

    try {
      Map<String, dynamic>? geofence;
      if (_isGeofenceMode) {
        geofence = {
          'included': _layers
              .where((l) => !l.isExcluded)
              .map(
                (l) => l.points
                    .map(
                      (p) => {'latitude': p.latitude, 'longitude': p.longitude},
                    )
                    .toList(),
              )
              .toList(),
          'excluded': _layers
              .where((l) => l.isExcluded)
              .map(
                (l) => l.points
                    .map(
                      (p) => {'latitude': p.latitude, 'longitude': p.longitude},
                    )
                    .toList(),
              )
              .toList(),
        };
      }

      final data = {
        'name': _nameController.text.trim(),
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'wifiSsid': _wifiController.text.trim().isEmpty
            ? null
            : _wifiController.text.trim(),
        'geofence': geofence,
        'radius': _isGeofenceMode ? null : _radius,
      };

      if (widget.office != null &&
          widget.office!.id != 0 &&
          widget.office!.id != null) {
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
      _handleError(e);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _handleError(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final data = e.response!.data;
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${ApiClient().parseErrorMessage(e)}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  // --- Actions ---

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (_currentTool == GeofenceTool.none) {
      setState(() {
        _selectedLocation = point;
      });
      return;
    }

    if (_currentTool == GeofenceTool.drawSafe ||
        _currentTool == GeofenceTool.drawDanger) {
      setState(() {
        _currentDrawingPoints.add(point);
      });
    }
  }

  void _finishDrawing() {
    if (_currentDrawingPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Polygon must have at least 3 points')),
      );
      return;
    }
    setState(() {
      _layers.add(
        DrawLayer(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          isExcluded: _currentTool == GeofenceTool.drawDanger,
          points: List.from(_currentDrawingPoints),
        ),
      );
      _currentDrawingPoints.clear();
      _currentTool = GeofenceTool.none;
    });
  }

  void _cancelDrawing() {
    setState(() {
      _currentDrawingPoints.clear();
      _currentTool = GeofenceTool.none;
    });
  }

  void _deleteLastLayer() {
    if (_layers.isNotEmpty) {
      setState(() {
        _layers.removeLast();
      });
    }
  }

  // --- UI Builders ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.office == null ? 'Add Office' : 'Edit Office'),
        actions: [
          IconButton(onPressed: _onSave, icon: Icon(widget.office == null ? Icons.check : Icons.save)),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionHeader(theme, 'Basic Info'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Office Name',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v?.trim().isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _wifiController,
                    decoration: const InputDecoration(
                      labelText: 'WiFi SSID (Optional)',
                      prefixIcon: Icon(Icons.wifi),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildSectionHeader(theme, 'Geofence Method'),
                  
                  const SizedBox(height: 6),
                  
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('Radius Mode'),
                        icon: Icon(Icons.radar),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('Geofence Mode'),
                        icon: Icon(Icons.map),
                      ),
                    ],
                    selected: {_isGeofenceMode},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() {
                        _isGeofenceMode = newSelection.first;
                        // If switching to radius, maybe reset tools
                        if (!_isGeofenceMode) {
                          _currentTool = GeofenceTool.none;
                          _currentDrawingPoints.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // MAP CONTAINER
                  Container(
                    height: 450,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter:
                                _selectedLocation ??
                                const LatLng(21.0285, 105.8542),
                            initialZoom: 17,
                            onTap: _onMapTap,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName:
                                  'com.example.qr_attendance_frontend',
                            ),
                            // 1. Radius Circle
                            if (!_isGeofenceMode && _selectedLocation != null)
                              CircleLayer(
                                circles: [
                                  CircleMarker(
                                    point: _selectedLocation!,
                                    radius: _radius,
                                    useRadiusInMeter: true,
                                    color: Colors.blue.withValues(alpha: 0.15),
                                    borderColor: Colors.blue,
                                    borderStrokeWidth: 1,
                                  ),
                                ],
                              ),

                            // 2. Existing Layers
                            PolygonLayer(
                              polygons: _layers
                                  .map(
                                    (layer) => Polygon(
                                      points: layer.points,
                                      color: layer.color,
                                      borderColor: layer.borderColor,
                                      borderStrokeWidth: 2,
                                    ),
                                  )
                                  .toList(),
                            ),

                            // 3. Current Drawing
                            if (_currentDrawingPoints.isNotEmpty)
                              PolygonLayer(
                                polygons: [
                                  Polygon(
                                    points: _currentDrawingPoints,
                                    color:
                                        _currentTool == GeofenceTool.drawDanger
                                        ? Colors.red.withValues(alpha: 0.3)
                                        : Colors.green.withValues(alpha: 0.3),
                                    borderColor:
                                        _currentTool == GeofenceTool.drawDanger
                                        ? Colors.red
                                        : Colors.green,
                                    borderStrokeWidth: 2,
                                  ),
                                ],
                              ),
                            if (_currentDrawingPoints.isNotEmpty)
                              MarkerLayer(
                                markers: _currentDrawingPoints
                                    .map(
                                      (p) => Marker(
                                        point: p,
                                        width: 10,
                                        height: 10,
                                        child: Container(
                                          color: Colors.white,
                                          padding: const EdgeInsets.all(2),
                                          child: Container(color: Colors.black),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),

                            // 4. Center Pin
                            if (_selectedLocation != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _selectedLocation!,
                                    width: 40,
                                    height: 40,
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.blue,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),

                        // Toolbar Overlay
                        if (_isGeofenceMode)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: _buildGeofenceToolbar(),
                          ),

                        // Helper Text / Status
                        Positioned(
                          bottom: 10,
                          left: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            color: Colors.white.withValues(alpha: 0.8),
                            child: Text(
                              _getInstructionText(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),

                        if (_isLoadingLocation)
                          const Center(child: CircularProgressIndicator()),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (!_isGeofenceMode)
                    _buildRadiusControl(theme)
                  else
                    _buildGeofenceLegend(),

                  // Error msg
                  if (_fieldErrors.containsKey('latitude'))
                    Text(
                      _fieldErrors['latitude']!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                ],
              ),
            ),
          ),
          if (_isSaving) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildGeofenceToolbar() {
    return Card(
      elevation: 4,
      child: Column(
        children: [
          IconButton(
            icon: const Icon(Icons.pan_tool),
            color: _currentTool == GeofenceTool.none
                ? Colors.blue
                : Colors.grey,
            tooltip: 'Move Map / Set Center',
            onPressed: () {
              if (_currentDrawingPoints.isNotEmpty)
                return; // Must finish drawing first
              setState(() => _currentTool = GeofenceTool.none);
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_location_alt),
            color: _currentTool == GeofenceTool.drawSafe
                ? Colors.green
                : Colors.grey,
            tooltip: 'Draw Inclusion Zone',
            onPressed: () {
              if (_currentDrawingPoints.isNotEmpty) return;
              setState(() => _currentTool = GeofenceTool.drawSafe);
            },
          ),
          IconButton(
            icon: const Icon(Icons.wrong_location),
            color: _currentTool == GeofenceTool.drawDanger
                ? Colors.red
                : Colors.grey,
            tooltip: 'Draw Exclusion Zone',
            onPressed: () {
              if (_currentDrawingPoints.isNotEmpty) return;
              setState(() => _currentTool = GeofenceTool.drawDanger);
            },
          ),
          const Divider(height: 5),
          if (_currentDrawingPoints.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.undo),
              color: Colors.orange,
              tooltip: 'Undo last point',
              onPressed: _undoLastPoint,
            ),
            IconButton(
              icon: const Icon(Icons.check),
              color: Colors.green,
              tooltip: 'Finish Shape',
              onPressed: _finishDrawing,
            ),

            IconButton(
              icon: const Icon(Icons.close),
              color: Colors.red,
              tooltip: 'Cancel',
              onPressed: _cancelDrawing,
            ),
          ],
          if (_currentDrawingPoints.isEmpty && _layers.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Remove Last Zone',
              onPressed: _deleteLastLayer,
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever),
              color: Colors.red,
              tooltip: 'Clear All Zones',
              onPressed: _clearAllLayers,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRadiusControl(ThemeData theme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Detection Radius'),
            Text(
              '${_radius.toInt()} m',
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: _radius,
          min: 20,
          max: 2000,
          divisions: 198,
          onChanged: (v) => setState(() => _radius = v),
        ),
      ],
    );
  }

  Widget _buildGeofenceLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              color: const Color(0x6600FF00),
              margin: const EdgeInsets.only(right: 4),
            ),
            const Text('Safe Zone'),
          ],
        ),
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              color: const Color(0x66FF0000),
              margin: const EdgeInsets.only(right: 4),
            ),
            const Text('Danger Zone'),
          ],
        ),
      ],
    );
  }

  String _getInstructionText() {
    if (!_isGeofenceMode)
      return 'Set the office location and adjust the radius slider.';
    switch (_currentTool) {
      case GeofenceTool.none:
        return 'Pan map to location. Select a tool to draw zones.';
      case GeofenceTool.drawSafe:
        return 'Tap map to add points for SAFE zone. Click Check to finish.';
      case GeofenceTool.drawDanger:
        return 'Tap map to add points for DANGER zone. Click Check to finish.';
    }
  }
}
