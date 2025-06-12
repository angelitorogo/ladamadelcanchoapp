

// Repositorio inmutable, proporciona a los demas providers la informacion de donde sale la info
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/infraestructure/datasources/weather_datasource_impl.dart';
import 'package:ladamadelcanchoapp/infraestructure/repositories/weather_repository_impl.dart';

final weatherRepositoryProvider = Provider<WeatherRepositoryImpl>( (ref) {
  return WeatherRepositoryImpl(WeatherDatasourceImpl());
});