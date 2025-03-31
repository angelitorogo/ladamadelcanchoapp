import 'dart:io';

abstract class TrackDatasource {
  Future<Map<String, dynamic>> uploadTrack(String name, File gpxFile);
}