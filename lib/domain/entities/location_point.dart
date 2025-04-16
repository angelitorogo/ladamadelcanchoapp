

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
  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'elevation': elevation,
      'timestamp': timestamp.toIso8601String(),
    };
  }
  
}
