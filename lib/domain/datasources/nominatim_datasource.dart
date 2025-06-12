
import 'package:ladamadelcanchoapp/domain/entities/location_point.dart';
import 'package:ladamadelcanchoapp/infraestructure/mappers/nominatim_mapper.dart';

abstract class NominatimDatasource{

  Future<NominatimResponse> fecthNominatim(LocationPoint point);

}
