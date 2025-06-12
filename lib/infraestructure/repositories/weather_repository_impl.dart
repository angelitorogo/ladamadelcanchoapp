import 'package:ladamadelcanchoapp/domain/datasources/weather_datasource.dart';
import 'package:ladamadelcanchoapp/domain/entities/location_point.dart';
import 'package:ladamadelcanchoapp/domain/repositories/weather_repository.dart';
import 'package:ladamadelcanchoapp/infraestructure/mappers/weather_mapper.dart';

class WeatherRepositoryImpl extends WeatherRepository {

  final WeatherDatasource datasource;

  WeatherRepositoryImpl(this.datasource);

  @override
  Future<WeatherResponse> fetchDailyForecast(LocationPoint point) {
    return datasource.fetchDailyForecast(point);
  }

}