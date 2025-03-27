import '../entities/location_point.dart';

abstract class LocationDatasource {
  Stream<LocationPoint> getLocationStream();
}