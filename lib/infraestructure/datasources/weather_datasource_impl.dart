import 'package:dio/dio.dart';
import 'package:ladamadelcanchoapp/domain/datasources/weather_datasource.dart';
import 'package:ladamadelcanchoapp/domain/entities/location_point.dart';
import 'package:ladamadelcanchoapp/infraestructure/mappers/weather_mapper.dart';


class WeatherDatasourceImpl implements WeatherDatasource {

  final Dio _dio = Dio();

  @override
  Future<WeatherResponse> fetchDailyForecast(LocationPoint point) async {

    const url = 'https://api.open-meteo.com/v1/forecast';

    final params = {
      'latitude': point.latitude,
      'longitude': point.longitude,
      'daily': 'temperature_2m_max,temperature_2m_min,precipitation_sum,weathercode',
      'timezone': 'auto',
    };

    try {
      final response = await _dio.get(url, queryParameters: params);

      if (response.statusCode == 200) {
        final finalResponse = WeatherResponse.fromJson(response.data);
        return finalResponse;
      } else {
        throw Exception('Error al obtener el tiempo: ${response.statusCode}');
      }
    } catch (e) {
      //print('Error en fetchDailyForecast: $e, ${s.toString()}');
      rethrow;
    }
  }

  
}