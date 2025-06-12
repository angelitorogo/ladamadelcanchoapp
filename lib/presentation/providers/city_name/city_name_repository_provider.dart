

// Repositorio inmutable, proporciona a los demas providers la informacion de donde sale la info
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/infraestructure/datasources/nominatim_datasource_impl.dart';
import 'package:ladamadelcanchoapp/infraestructure/repositories/nominatim_repository_impl.dart';

final cityNameRepositoryProvider = Provider<NominatimRepositoryImpl>( (ref) {
  return NominatimRepositoryImpl(NominatimDatasourceImpl());
});