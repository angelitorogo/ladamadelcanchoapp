import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/infraestructure/datasources/track_datasource_impl.dart';
import 'package:ladamadelcanchoapp/infraestructure/repositories/track_repository_impl.dart';

final trackListRepositoryProvider = Provider( (ref) {
  return TrackRepositoryImpl(TrackDatasourceImpl());
});