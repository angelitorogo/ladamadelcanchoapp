

class LocationPoint {
  final double latitude;
  final double longitude;
  final double elevation;
  final DateTime timestamp;

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.elevation,
    required this.timestamp,
  });

  // ✅ Método copyWith para clonar el objeto con cambios opcionales
  LocationPoint copyWith({
    double? latitude,
    double? longitude,
    double? elevation,
    DateTime? timestamp,
  }) {
    return LocationPoint(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      elevation: elevation ?? this.elevation,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  // ✅ Método para exportar a Map
  Map<String, dynamic> toMap() => {
    'latitude': latitude,
    'longitude': longitude,
    'elevation': elevation,
    'time': timestamp.toIso8601String(),
  };

  factory LocationPoint.fromMap(Map<String, dynamic> json) => LocationPoint(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    elevation: (json['elevation'] as num).toDouble(),
    timestamp: DateTime.parse(json['time']),
  );
  
}
