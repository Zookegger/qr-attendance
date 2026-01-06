import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:qr_attendance_frontend/src/models/office_config.dart';
import 'package:qr_attendance_frontend/src/screens/admin/office/office_config_form_page.dart';

class OfficeDetailPage extends StatefulWidget {
  final OfficeConfig office;

  const OfficeDetailPage({super.key, required this.office});

  @override
  State<OfficeDetailPage> createState() => _OfficeDetailPageState();
}

class _OfficeDetailPageState extends State<OfficeDetailPage> {
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  void _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OfficeFormPage(office: widget.office),
      ),
    );

    // If result is true (saved), pop back to list to refresh
    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final office = widget.office;
    final center = LatLng(office.latitude, office.longitude);

    // Prepare Polygons
    final List<Polygon> polygons = [];
    if (office.geofence != null) {
      for (var poly in office.geofence!.included) {
        polygons.add(
          Polygon(
            points:
                poly
                    .map((p) => LatLng(p['latitude']!, p['longitude']!))
                    .toList(),
            color: const Color(0x6600FF00),
            borderColor: Colors.green,
            borderStrokeWidth: 2,
          ),
        );
      }
      for (var poly in office.geofence!.excluded) {
        polygons.add(
          Polygon(
            points:
                poly
                    .map((p) => LatLng(p['latitude']!, p['longitude']!))
                    .toList(),
            color: const Color(0x66FF0000),
            borderColor: Colors.red,
            borderStrokeWidth: 2,
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(office.name),
        actions: [
          IconButton(onPressed: _navigateToEdit, icon: const Icon(Icons.edit)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(initialCenter: center, initialZoom: 17),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.qr_attendance',
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: center,
                      radius: office.radius,
                      useRadiusInMeter: true,
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderColor: Colors.blue,
                      borderStrokeWidth: 1,
                    ),
                  ],
                ),
                PolygonLayer(polygons: polygons),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: center,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.blue,
                        size: 40,
                      ),
                      alignment: Alignment.topCenter,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(
                  leading: const Icon(Icons.business),
                  title: const Text("Office Name"),
                  subtitle: Text(office.name),
                ),
                ListTile(
                  leading: const Icon(Icons.wifi),
                  title: const Text("WiFi SSID"),
                  subtitle: Text(office.wifiSsid ?? "Not Configured"),
                ),
                ListTile(
                  leading: const Icon(Icons.radar),
                  title: const Text("Radius"),
                  subtitle: Text("${office.radius.toStringAsFixed(1)} meters"),
                ),
                ListTile(
                  leading: const Icon(Icons.map),
                  title: const Text("Coordinates"),
                  subtitle: Text(
                    "${office.latitude.toStringAsFixed(6)}, ${office.longitude.toStringAsFixed(6)}",
                  ),
                ),
                if (office.geofence != null)
                  ListTile(
                    leading: const Icon(Icons.layers),
                    title: const Text("Geofence Configurations"),
                    subtitle: Text(
                      "Included Zones: ${office.geofence!.included.length}\nExcluded Zones: ${office.geofence!.excluded.length}",
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
