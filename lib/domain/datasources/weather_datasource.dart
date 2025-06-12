import 'package:ladamadelcanchoapp/domain/entities/location_point.dart';
import 'package:ladamadelcanchoapp/infraestructure/mappers/weather_mapper.dart';

abstract class WeatherDatasource{

  Future<WeatherResponse> fetchDailyForecast(LocationPoint point);

}
