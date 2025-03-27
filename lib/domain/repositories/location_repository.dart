import '../entities/location_point.dart';

abstract class LocationRepository {
  Stream<LocationPoint> getLocationStream();
}