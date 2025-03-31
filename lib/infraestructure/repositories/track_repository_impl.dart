

import 'dart:io';

import 'package:ladamadelcanchoapp/domain/datasources/track_datasource.dart';
import 'package:ladamadelcanchoapp/domain/repositories/track_repository.dart';

class TrackRepositoryImpl extends TrackRepository {

  final TrackDatasource datasource;

  TrackRepositoryImpl(this.datasource);

  @override
  Future<Map<String, dynamic>> uploadTrack(String name, File gpxFile) {
    return datasource.uploadTrack(name, gpxFile);
  }

 

  

}