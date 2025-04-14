import 'package:ladamadelcanchoapp/domain/datasources/elevation_datasource.dart';
import 'package:ladamadelcanchoapp/domain/entities/location_point.dart';
import 'package:ladamadelcanchoapp/domain/repositories/elevation_repository.dart';
import 'package:ladamadelcanchoapp/infraestructure/models/corrected_elevation_response.dart';

class ElevationRepositoryImpl implements ElevationRepository {
  final ElevationDatasource datasource;

  ElevationRepositoryImpl(this.datasource);

  @override
  Future<List<LocationPoint>> getCorrectedElevations(List<LocationPoint> points) {
    return datasource.getElevations(points);
  }

  @override
  Future<CorrectedElevationResponse> getElevationForPoint(LocationPoint point) {
    return datasource.getElevationForPoint(point);
  }
}