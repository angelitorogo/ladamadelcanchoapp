
import 'package:ladamadelcanchoapp/domain/entities/location_point.dart';
import 'package:ladamadelcanchoapp/infraestructure/mappers/nominatim_mapper.dart';

abstract class NominatimRepository{

  Future<NominatimResponse> fecthNominatim(LocationPoint point);

}