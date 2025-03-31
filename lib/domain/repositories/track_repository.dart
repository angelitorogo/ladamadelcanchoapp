import 'dart:io';

abstract class TrackRepository {
  Future<Map<String, dynamic>> uploadTrack(String name, File gpxFile);
}