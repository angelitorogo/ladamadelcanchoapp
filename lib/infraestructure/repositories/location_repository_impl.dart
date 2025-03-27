

import 'package:ladamadelcanchoapp/domain/datasources/location_datasource.dart';
import 'package:ladamadelcanchoapp/domain/entities/location_point.dart';
import 'package:ladamadelcanchoapp/domain/repositories/location_repository.dart';

class LocationRepositoryImpl extends LocationRepository {

  final LocationDatasource datasource;

  LocationRepositoryImpl(this.datasource);

  @override
  Stream<LocationPoint> getLocationStream() {
    return datasource.getLocationStream();
  }

  

}