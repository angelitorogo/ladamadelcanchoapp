import 'dart:async';
import 'dart:math';
import 'package:location/location.dart';
import '../../domain/entities/location_point.dart';
import '../../domain/datasources/location_datasource.dart';

// 🆕 Enum para representar los distintos modos de grabación (se mantiene por si se usa externamente)
enum TrackingMode {
  walking,
  cycling,
  driving,
}

class LocationDatasourceImpl implements LocationDatasource {
  final Location location = Location();
  LocationPoint? _lastPoint;

  final _discardedController = StreamController<LocationPoint>.broadcast();
  Stream<LocationPoint> get discardedPointsStream => _discardedController.stream;

  // 🆕 Se conserva aunque no se use directamente para filtrar, por compatibilidad
  TrackingMode _mode = TrackingMode.walking;

  void setTrackingMode(TrackingMode mode) {
    _mode = mode;
  }

  @override
  Stream<LocationPoint> getLocationStream() {
    final interval = getIntervalForMode(_mode);

    location.changeSettings(
      accuracy: LocationAccuracy.navigation,
      interval: interval,
      distanceFilter: 1,
    );

    return location.onLocationChanged.map((locData) {
      double correctedElevation = locData.altitude ?? 0;

      // Si hay un punto anterior, se evalúa la diferencia de elevación
      if (_lastPoint != null) {
        final elevationDiff = correctedElevation - _lastPoint!.elevation;

        // 🟡 Si la diferencia de elevación es exagerada, la corregimos
        if (elevationDiff.abs() > _getMaxAllowedElevationDiff(_mode)) {
          correctedElevation = _lastPoint!.elevation;

          // Opcional: almacenar el punto descartado para debug
          final discarded = LocationPoint(
            latitude: locData.latitude!,
            longitude: locData.longitude!,
            elevation: locData.altitude ?? 0,
            timestamp: DateTime.fromMillisecondsSinceEpoch(locData.time!.toInt()),
          );
          _discardedController.add(discarded);
        }
      }

      final point = LocationPoint(
        latitude: locData.latitude!,
        longitude: locData.longitude!,
        elevation: correctedElevation,
        timestamp: DateTime.fromMillisecondsSinceEpoch(locData.time!.toInt()),
      );

      _lastPoint = point;
      return point;
    });
  }

  // 🆕 Devuelve el máximo desnivel aceptable por modo, solo para corrección de altitud
  double _getMaxAllowedElevationDiff(TrackingMode mode) {
    switch (mode) {
      case TrackingMode.walking:
        return 10;
      case TrackingMode.cycling:
        return 20;
      case TrackingMode.driving:
        return 30;
    }
  }

  double calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371000; // Radio de la Tierra en metros
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);

  int getIntervalForMode(TrackingMode mode) {
    switch (mode) {
      case TrackingMode.walking:
        return 2000; // cada 2 segundos
      case TrackingMode.cycling:
        return 1500; // cada 1.5 segundos
      case TrackingMode.driving:
        return 1000; // cada 1 segundo
    }
  }

  void dispose() {
    _discardedController.close();
  }
}
