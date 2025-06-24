import 'package:dio/dio.dart';
import 'package:ladamadelcanchoapp/domain/datasources/nominatim_datasource.dart';
import 'package:ladamadelcanchoapp/domain/entities/location_point.dart';
import 'package:ladamadelcanchoapp/infraestructure/mappers/nominatim_mapper.dart';

class NominatimDatasourceImpl implements NominatimDatasource {

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://nominatim.openstreetmap.org',
      headers: {
        'User-Agent': 'ladamadelcanchoapp/1.0 (angel@tucorreo.com)'  // Usa tu email real si quieres cumplir con sus políticas
      },
    ),
  );

  @override
  Future<NominatimResponse> fecthNominatim(LocationPoint point) async {
    
    final params = {
      'lat': point.latitude,
      'lon': point.longitude,
      'format': 'json',
    };

    try {
      final response = await _dio.get('/reverse', queryParameters: params);

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