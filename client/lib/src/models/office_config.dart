class OfficeConfig {
  final int? id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius;
  final String? wifiSsid;

  OfficeConfig({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.wifiSsid,
  });

  factory OfficeConfig.fromJson(Map<String, dynamic> json) {
    return OfficeConfig(
      id: json['id'],
      name: json['name'] ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radius: (json['radius'] as num).toDouble(),
      wifiSsid: json['wifiSsid'],
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
    };
  }
}
