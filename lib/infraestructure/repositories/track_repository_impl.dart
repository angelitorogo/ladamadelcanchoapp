
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/domain/datasources/track_datasource.dart';
import 'package:ladamadelcanchoapp/domain/entities/track.dart';
import 'package:ladamadelcanchoapp/domain/entities/user.dart';
import 'package:ladamadelcanchoapp/domain/repositories/track_repository.dart';

class TrackRepositoryImpl extends TrackRepository {

  final TrackDatasource datasource;

  TrackRepositoryImpl(this.datasource);

  @override
  Future<Map<String, dynamic>> uploadTrack(WidgetRef ref, String name, File gpxFile, String description, String type, String distance, String elevationGain, {List<File> images = const []}) {
    return datasource.uploadTrack(ref, name, gpxFile, description, type,  distance, elevationGain, images: images);
  }
  
  @override
  Future<Map<String, dynamic>> loadAllTracks(WidgetRef ref, {int limit = 10, int page = 0, String? loggedUser, String? userId, String? orderBy, String? direction}) {
    return datasource.loadAllTracks(ref, limit: limit, page:page, loggedUser: loggedUser,  userId: userId, orderBy: orderBy, direction: direction);
  }
  
  @override
  Future<Track?> existsTrack(String name, String? loggedUser) {
    return datasource.existsTrack(name, loggedUser);
  }

  @override
  Future<Track> loadTrack(String id) {
    return datasource.loadTrack(id);
  }

  @override
  Future<List<Track>> getNearestTracks(String trackId, String? loggedUser, {int limit = 5}) {
    return datasource.getNearestTracks(trackId, loggedUser, limit: limit);
  }


  @override
  Future<Response<dynamic>> deleteTrack(WidgetRef ref, String id) {
    return datasource.deleteTrack(ref, id);
  }


  @override
  Future<Response<dynamic>> updateTrack(WidgetRef ref, String id, String name, String description, {List<String> imagesOld = const[], List<File> images = const []}) {
    return datasource.updateTrack(ref, id, name, description, imagesOld: imagesOld, images: images);
  }
  
  @override
  Future<void> addFavorite(WidgetRef ref, String trackId, UserEntity userLogged) {
    return datasource.addFavorite(ref, trackId, userLogged);
  }
  
  @override
  Future<void> removeFavorite(WidgetRef ref, String trackId, UserEntity userLogged) {
    return datasource.removeFavorite(ref, trackId, userLogged);
  }

 

  

}