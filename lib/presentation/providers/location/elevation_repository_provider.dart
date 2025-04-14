import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/domain/repositories/elevation_repository.dart';
import 'package:ladamadelcanchoapp/infraestructure/datasources/elevation_datasource_impl.dart';
import 'package:ladamadelcanchoapp/infraestructure/repositories/elevation_repository_impl.dart';

final elevationRepositoryProvider = Provider<ElevationRepository>((ref) {
  return ElevationRepositoryImpl(ElevationDatasourceImpl());
});