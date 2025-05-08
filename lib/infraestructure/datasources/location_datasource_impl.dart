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
    final distanceFilter = getMinDistanceForMode(_mode);

    location.changeSettings(
      accuracy: LocationAccuracy.navigation,
      interval: interval,
      distanceFilter: distanceFilter,
    );

    return location.onLocationChanged.map((locData) {
      final currentLat = locData.latitude!;
      final currentLon = locData.longitude!;
      double correctedElevation = locData.altitude ?? 0;

      final now = DateTime.fromMillisecondsSinceEpoch(locData.time!.toInt());

      // 🟡 Si hay un punto anterior, aplicar filtros
      if (_lastPoint != null) {
        final dist = calculateDistanceMeters(
          _lastPoint!.latitude,
          _lastPoint!.longitude,
          currentLat,
          currentLon,
        );

        final minDistance = getMinDistanceForMode(_mode);

        if (dist < minDistance) {
          // Opcional: emitir punto descartado para debug
          final discarded = LocationPoint(
            latitude: currentLat,
            longitude: currentLon,
            elevation: correctedElevation,
            timestamp: now,
          );
          _discardedController.add(discarded);
          return null; // ❌ No emitir el punto
        }

        final elevationDiff = correctedElevation - _lastPoint!.elevation;
        if (elevationDiff.abs() > _getMaxAllowedElevationDiff(_mode)) {
          correctedElevation = _lastPoint!.elevation;
          _discardedController.add(LocationPoint(
            latitude: currentLat,
            longitude: currentLon,
            elevation: locData.altitude ?? 0,
            timestamp: now,
          ));
        }
      }

      final point = LocationPoint(
        latitude: currentLat,
        longitude: currentLon,
        elevation: correctedElevation,
        timestamp: now,
      );

      _lastPoint = point;
      return point;
    }).where((point) => point != null).cast<LocationPoint>();

    
  }

  double getMinDistanceForMode(TrackingMode mode) {
    switch (mode) {
      case TrackingMode.walking:
        return 5.0;
      case TrackingMode.cycling:
        return 9.0;
      case TrackingMode.driving:
        return 15.0;
    }
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
