

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/domain/datasources/track_datasource.dart';
import 'package:ladamadelcanchoapp/domain/entities/track.dart';

import 'package:ladamadelcanchoapp/domain/repositories/track_repository.dart';

class TrackRepositoryImpl extends TrackRepository {

  final TrackDatasource datasource;

  TrackRepositoryImpl(this.datasource);

  @override
  Future<Map<String, dynamic>> uploadTrack(WidgetRef ref, String name, File gpxFile, String description, String type, String distance, String elevationGain, {List<File> images = const []}) {
    return datasource.uploadTrack(ref, name, gpxFile, description, type,  distance, elevationGain, images: images);
  }
  
  @override
  Future<Map<String, dynamic>> loadAllTracks({int limit = 10, int page = 0, String? userId, String? orderBy, String? direction}) {
    return datasource.loadAllTracks(limit: limit, page:page, userId: userId, orderBy: orderBy, direction: direction);
  }
  
  @override
  Future<bool> existsTrack(String name) {
    return datasource.existsTrack(name);
  }

  @override
  Future<Track> loadTrack(String id) {
    return datasource.loadTrack(id);
  }

 

  

}