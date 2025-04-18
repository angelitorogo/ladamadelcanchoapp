import 'dart:io';

abstract class TrackDatasource {

  Future<Map<String, dynamic>> uploadTrack(String name, File gpxFile, String description, String type, String distance, String elevationGain, {List<File> images = const []});

  Future<Map<String, dynamic>> loadAllTracks({ int limit = 10, int offset = 0, String? userId });
}