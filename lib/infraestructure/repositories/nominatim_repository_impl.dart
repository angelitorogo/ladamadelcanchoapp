import 'package:ladamadelcanchoapp/domain/datasources/nominatim_datasource.dart';
import 'package:ladamadelcanchoapp/domain/entities/location_point.dart';
import 'package:ladamadelcanchoapp/infraestructure/mappers/nominatim_mapper.dart';

class NominatimRepositoryImpl extends NominatimDatasource {

  final NominatimDatasource datasource;

  NominatimRepositoryImpl(this.datasource);


  @override
  Future<NominatimResponse> fecthNominatim(LocationPoint point) {
    return datasource.fecthNominatim(point);
  }

}