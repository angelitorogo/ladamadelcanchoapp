import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/domain/entities/track.dart';
import 'package:ladamadelcanchoapp/domain/entities/user.dart';

abstract class TrackDatasource {

  Future<Map<String, dynamic>> uploadTrack(WidgetRef ref, String name, File gpxFile, String description, String type, String distance, String elevationGain, {List<File> images = const []});

  Future<Map<String, dynamic>> loadAllTracks(WidgetRef ref, { int limit = 10, int page = 0, String? loggedUser, String? userId, String? orderBy, String? direction });

  Future<Track?> existsTrack(String name, String? loggedUser);

  Future<Track> loadTrack(String id);

  Future<List<Track>> getNearestTracks(String trackId, String? loggedUser, {int limit = 5}); 

  Future<Response<dynamic>> deleteTrack(WidgetRef ref, String id);

  Future<Response<dynamic>> updateTrack(WidgetRef ref, String id, String name, String description, {List<String> imagesOld = const[], List<File> images = const []});
 
  Future<void> addFavorite(WidgetRef ref, String trackId, UserEntity userLogged); 

  Future<void> removeFavorite(WidgetRef ref, String trackId, UserEntity userLogged); 

}