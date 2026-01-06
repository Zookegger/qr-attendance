import 'dart:convert';

class GeoPoint {
  final double lat;
  final double lon;

  GeoPoint({required this.lat, required this.lon});

  factory GeoPoint.fromJson(Map<String, dynamic> json) {
    return GeoPoint(
      lat: (json['latitude'] as num).toDouble(),
      lon: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'latitude': lat, 'longitude': lon};
}

class GeofenceConfig {
  final List<List<GeoPoint>> included;
  final List<List<GeoPoint>> excluded;

  GeofenceConfig({this.included = const [], this.excluded = const []});

  factory GeofenceConfig.fromJson(Map<String, dynamic> json) {
    List<List<GeoPoint>> parsePolygons(dynamic list) {
      if (list == null) return [];
      return (list as List).map((poly) {
        return (poly as List).map((point) => GeoPoint.fromJson(point)).toList();
      }).toList();
    }

    return GeofenceConfig(
      included: parsePolygons(json['included']),
      excluded: parsePolygons(json['excluded']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'included': included, 'excluded': excluded};
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
          ? GeofenceConfig.fromJson(jsonDecode(json['geofence']))
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
