class OfficeConfig {
  final int? id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius;
  final String? wifiSsid;
  final List<Map<String, double>>? polygon;

  OfficeConfig({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.wifiSsid,
    this.polygon,
  });

  factory OfficeConfig.fromJson(Map<String, dynamic> json) {
    return OfficeConfig(
      id: json['id'],
      name: json['name'] ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radius: (json['radius'] as num).toDouble(),
      wifiSsid: json['wifiSsid'],
      polygon: json['polygon'] != null
          ? (json['polygon'] as List).map((e) {
              return {
                'latitude': (e['latitude'] as num).toDouble(),
                'longitude': (e['longitude'] as num).toDouble(),
              };
            }).toList()
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
      'polygon': polygon,
    };
  }
}
