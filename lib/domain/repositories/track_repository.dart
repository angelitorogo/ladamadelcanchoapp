import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/domain/entities/track.dart';

abstract class TrackRepository {
  Future<Map<String, dynamic>> uploadTrack(WidgetRef ref, String name, File gpxFile, String description, String type, String distance, String elevationGain, {List<File> images = const []});

  Future<Map<String, dynamic>> loadAllTracks({ int limit = 10, int page = 0, String? userId, String? orderBy, String? direction });

  Future<bool> existsTrack(String name);

  Future<Track> loadTrack(String id);
  
}