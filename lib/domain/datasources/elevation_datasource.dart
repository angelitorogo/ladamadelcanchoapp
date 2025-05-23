import 'package:ladamadelcanchoapp/domain/entities/location_point.dart';
import 'package:ladamadelcanchoapp/infraestructure/models/corrected_elevation_response.dart';

abstract class ElevationDatasource {
  Future<List<LocationPoint>> getElevations(List<LocationPoint> points);

  Future<CorrectedElevationResponse> getElevationForPoint(LocationPoint point);
}
