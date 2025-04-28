import 'dart:io';

import 'package:ladamadelcanchoapp/domain/entities/track.dart';

abstract class TrackRepository {
  Future<Map<String, dynamic>> uploadTrack(String name, File gpxFile, String description, String type, String distance, String elevationGain, {List<File> images = const []});

  Future<Map<String, dynamic>> loadAllTracks({ int limit = 10, int offset = 0, String? userId });

  Future<bool> existsTrack(String name);

  Future<Track> loadTrack(String id);
  
}