import 'package:dio/dio.dart';
import 'package:ladamadelcanchoapp/domain/datasources/nominatim_datasource.dart';
import 'package:ladamadelcanchoapp/domain/entities/location_point.dart';
import 'package:ladamadelcanchoapp/infraestructure/mappers/nominatim_mapper.dart';

class NominatimDatasourceImpl implements NominatimDatasource {

  final Dio _dio = Dio();

  @override
  Future<NominatimResponse> fecthNominatim(LocationPoint point) async {
    

    const url = 'https://nominatim.openstreetmap.org/reverse';

    final params = {
      'lat': point.latitude,
      'lon': point.longitude,
      'format': 'json',
    };

    try {
      final response = await _dio.get(url, queryParameters: params);

      if (response.statusCode == 200) {
        final finalResponse = NominatimResponse.fromJson(response.data);
        return finalResponse;
      } else {
        throw Exception('Error al obtener el municipio: ${response.statusCode}');
      }
    } catch (e) {
      //print('Error en fetchDailyForecast: $e, ${s.toString()}');
      rethrow;
    }

  }

}