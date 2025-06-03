import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/domain/entities/track.dart';

abstract class TrackDatasource {

  Future<Map<String, dynamic>> uploadTrack(WidgetRef ref, String name, File gpxFile, String description, String type, String distance, String elevationGain, {List<File> images = const []});

  Future<Map<String, dynamic>> loadAllTracks({ int limit = 10, int page = 0, String? userId, String? orderBy, String? direction });

  Future<Track?> existsTrack(String name);

  Future<Track> loadTrack(String id);

  Future<List<Track>> getNearestTracks(String trackId, {int limit = 5}); 

  Future<Response<dynamic>> deleteTrack(String id);
  
}