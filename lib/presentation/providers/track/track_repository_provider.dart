

// Repositorio inmutable, proporciona a los demas providers la informacion de donde sale la info
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/infraestructure/datasources/track_datasource_impl.dart';
import 'package:ladamadelcanchoapp/infraestructure/repositories/track_repository_impl.dart';

final trackRepositoryProvider = Provider<TrackRepositoryImpl>( (ref) {
  return TrackRepositoryImpl(TrackDatasourceImpl());
});