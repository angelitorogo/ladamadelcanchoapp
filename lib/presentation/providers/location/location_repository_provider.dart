

// Repositorio inmutable, proporciona a los demas providers la informacion de donde sale la info
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/infraestructure/datasources/location_datasource_impl.dart';
import 'package:ladamadelcanchoapp/infraestructure/repositories/location_repository_impl.dart';

final locationRepositoryProvider = Provider<LocationRepositoryImpl>( (ref) {
  return LocationRepositoryImpl(LocationDatasourceImpl());
});