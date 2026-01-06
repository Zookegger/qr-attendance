class GeofenceConfig {
  final List<List<Map<String, double>>> included;
  final List<List<Map<String, double>>> excluded;

  GeofenceConfig({this.included = const [], this.excluded = const []});

  factory GeofenceConfig.fromJson(Map<String, dynamic> json) {
    List<List<Map<String, double>>> parsePolygons(dynamic list) {
      if (list == null) return [];
      return (list as List).map((poly) {
        return (poly as List).map((point) {
          return {
            'latitude': (point['latitude'] as num).toDouble(),
            'longitude': (point['longitude'] as num).toDouble(),
          };
        }).toList();
      }).toList();
    }

    return GeofenceConfig(
      included: parsePolygons(json['included']),
      excluded: parsePolygons(json['excluded']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'included': included,
      'excluded': excluded,
    };
  }
}

class OfficeConfig {
  final int? id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius;
  final String? wifiSsid;
  final GeofenceConfig? geofence;

  OfficeConfig({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.wifiSsid,
    this.geofence,
  });

  factory OfficeConfig.fromJson(Map<String, dynamic> json) {
    return OfficeConfig(
      id: json['id'],
      name: json['name'] ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radius: (json['radius'] as num).toDouble(),
      wifiSsid: json['wifiSsid'],
      geofence: json['geofence'] != null
          ? GeofenceConfig.fromJson(json['geofence'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'wifiSsid': wifiSsid,
      'geofence': geofence?.toJson(),
    };
  }
}
