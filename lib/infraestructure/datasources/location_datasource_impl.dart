import 'package:location/location.dart';
import 'package:ladamadelcanchoapp/domain/datasources/location_datasource.dart';
import '../../domain/entities/location_point.dart';
import 'dart:math';

class LocationDatasourceImpl implements LocationDatasource {
  final Location location = Location();
  LocationPoint? _lastPoint;

  @override
  Stream<LocationPoint> getLocationStream() {
    location.changeSettings(
      accuracy: LocationAccuracy.navigation,
      interval: 2000,
      distanceFilter: 0,
    );

    return location.onLocationChanged
      .where((locData) {
        if (_lastPoint == null) return true;

        final distance = _calculateDistanceMeters(
          _lastPoint!.latitude,
          _lastPoint!.longitude,
          locData.latitude!,
          locData.longitude!,
        );

        return distance >= 1; // ✅ Requiere al menos 1 metro de desplazamiento
      })
      .map((locData) {
        final point = LocationPoint(
          latitude: locData.latitude!,
          longitude: locData.longitude!,
          elevation: locData.altitude ?? 0,
          timestamp: DateTime.fromMillisecondsSinceEpoch(locData.time!.toInt()),
        );
        _lastPoint = point;
        return point;
      });
  }

  double _calculateDistanceMeters(
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
}
