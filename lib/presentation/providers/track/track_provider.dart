

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:ladamadelcanchoapp/domain/entities/location_point.dart';
import 'package:ladamadelcanchoapp/domain/entities/track.dart';
import 'package:ladamadelcanchoapp/domain/entities/user.dart';
import 'package:ladamadelcanchoapp/infraestructure/models/gpx_result.dart';
import 'package:ladamadelcanchoapp/infraestructure/repositories/auth_repository_impl.dart';
import 'package:ladamadelcanchoapp/presentation/providers/auth/auth_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/auth/auth_repository_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/location/location_provider.dart';

import 'track_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/infraestructure/repositories/track_repository_impl.dart';


enum TrackUploadStatus { idle, loading, success, error }

class TrackUploadState {
  final TrackUploadStatus status;
  final String? message;

  const TrackUploadState({
    this.status = TrackUploadStatus.idle,
    this.message,
  });

  TrackUploadState copyWith({
    TrackUploadStatus? status,
    String? message,
  }) {
    return TrackUploadState(
      status: status ?? this.status,
      message: message,
    );
  }
}

class TrackUploadNotifier extends StateNotifier<TrackUploadState> {
  final TrackRepositoryImpl repository;
  final AuthRepositoryImpl repository2;

  TrackUploadNotifier(this.repository, this.repository2) : super(const TrackUploadState());

  Future<Track?> existsTrackForName(String name, WidgetRef ref) async {

    final UserEntity? userLogged = ref.read(authProvider).user;

    try {

      final result = await repository.existsTrack(name, userLogged?.id);
      return result;

    } catch (e) {
      state = const TrackUploadState(
        status: TrackUploadStatus.error,
        message: 'Error al subir el track',
      );
      return null;
    }

  }

  Future<Track> loadTrackForId(String id) async {

    final result = await repository.loadTrack(id);
    return result;

  }

  void borrarArchivosEnCarpeta() async {
  // Solicitar permisos de almacenamiento

  // Ruta de la carpeta a borrar
  final carpetaTracks = Directory('/storage/emulated/0/Download/GPX/tracks/');
  final carpetaImages = Directory('/storage/emulated/0/Download/GPX/captures/');

  if (await carpetaTracks.exists()) {
    // Listar y borrar los archivos
    final archivos = carpetaTracks.listSync();
    for (var archivo in archivos) {
      if (archivo is File) {
     
        await archivo.delete();

      }
    }
  } 

  if (await carpetaImages.exists()) {
    // Listar y borrar los archivos
    final archivos = carpetaImages.listSync();
    for (var archivo in archivos) {
      if (archivo is File) {
     
        await archivo.delete();

      }
    }
  } 

}

  Future<Map<String, dynamic>?> uploadTrack(BuildContext context, String name, File file, WidgetRef ref, String description, String type, String distance, String elevationGain, File captureMap, { List<LocationPoint> points = const[], List<File> images = const []} ) async {
    state = const TrackUploadState(status: TrackUploadStatus.loading);

    images.insert(0, captureMap);
  

    try {
      
      final originalFileName = '/storage/emulated/0/Download/GPX/tracks/${file.uri.pathSegments.last}';
      GpxResult result;
      File uploadFile;

      if(file.uri.pathSegments.last.replaceAll('.gpx', '') != name && description.isNotEmpty){

        result = await ref.read(locationProvider.notifier).stopTrackingAndSaveGpx(context: context, ref: ref, overrideName: name, overrideDescription: description, cancel: false, points: points);
        uploadFile = result.gpxFile!;

        final oldFilePath = originalFileName;
        final oldFile = File(oldFilePath);

        if (await oldFile.exists()) {
          try {
            await oldFile.delete();
          } catch (e) {
            throw Exception(e);
          }
        }

      } else if(description.isNotEmpty) {

        result = await ref.read(locationProvider.notifier).stopTrackingAndSaveGpx(context: context, ref: ref, overrideDescription: description, cancel: false, points: points);
        uploadFile = result.gpxFile!;

        final oldFilePath = originalFileName;
        final oldFile = File(oldFilePath);

        if (await oldFile.exists()) {
          try {
            await oldFile.delete();
          } catch (e) {
            throw Exception(e);
          }
        }

      } else if (file.uri.pathSegments.last.replaceAll('.gpx', '') != name) {

        result = await ref.read(locationProvider.notifier).stopTrackingAndSaveGpx(context: context, ref: ref, overrideName: name, cancel: false, points: points);
        uploadFile = result.gpxFile!;

        final oldFilePath = originalFileName;
        final oldFile = File(oldFilePath);

        if (await oldFile.exists()) {
          try {
            await oldFile.delete();
          } catch (e) {
            throw Exception(e);
          }
        }
        
      } else if( name == 'offline') {

        result = await ref.read(locationProvider.notifier).stopTrackingAndSaveGpx(context: context, ref: ref, overrideName: name, cancel: false, points: points);  // <---
        uploadFile = result.gpxFile!;
    
       } else {

        uploadFile = File(originalFileName);

      }


      repository2.fetchCsrfToken(); //cogerlo si se puede del authState

      //SABER SI YA HAY UN TRACK CON ESE NAME Peticion a back track:name
      final track = await existsTrackForName(name, ref);

      if( track != null) {

        state = const TrackUploadState(
          status: TrackUploadStatus.error,
          message: 'Ya existe un track con ese nombre.',
        );
        return null;

      } else {

        final response = await repository.uploadTrack(ref, name, uploadFile, description, type, distance, elevationGain, images: images );
        state = const TrackUploadState(status: TrackUploadStatus.success);
        borrarArchivosEnCarpeta();
        return response;
        
      }
      
    } catch (e) {
      state = const TrackUploadState(
        status: TrackUploadStatus.error,
        message: 'Error al subir el track',
      );
      return null;
    }
  }


  Future<Response<dynamic>> deleteTrack(WidgetRef ref, String id) async {

    state = const TrackUploadState(status: TrackUploadStatus.loading);

    try {
      final result = await repository.deleteTrack(ref, id);
      state = const TrackUploadState(status: TrackUploadStatus.success);
      return result;
    } catch (e) {
      state = const TrackUploadState(
        status: TrackUploadStatus.error,
        message: 'Error al eliminar el track',
      );
      return Response(requestOptions: RequestOptions(), statusCode: 500, statusMessage: 'Error al eliminar el track: $e');
    }
  }

  Future<Response<dynamic>> updateTrack(WidgetRef ref, String id, String name, String description, { List<String> imagesOld = const[] ,List<File> images = const[] }) async {

    state = const TrackUploadState(status: TrackUploadStatus.loading);
    try {
      final result = await repository.updateTrack(ref, id, name, description, imagesOld: imagesOld, images: images);
      state = const TrackUploadState(status: TrackUploadStatus.success);
      return result;
    } catch (e) {
      state = const TrackUploadState(
        status: TrackUploadStatus.error,
        message: 'Error al actualizar el track',
      );
      return Response(requestOptions: RequestOptions(), statusCode: 500, statusMessage: 'Error al actualizar el track: $e');
    }

  } 


  Future<void> toggleFavorite(WidgetRef ref, String trackId, bool isCurrentlyFavorite, UserEntity userLogged) async {


    late UserEntity loggedUser;

    if(userLogged.id.isNotEmpty) {
      loggedUser = userLogged;
    } else {
      loggedUser = ref.read(authProvider).user!;
    }



    
    try {
      if (isCurrentlyFavorite) {
        await repository.removeFavorite(ref, trackId, loggedUser);
      } else {
        await repository.addFavorite(ref, trackId, loggedUser);
      }
    } catch (e) {
      debugPrint('Error al alternar favorito: $e');
    }
  }

  void reset() {
    state = const TrackUploadState();
  }
}



final trackUploadProvider = StateNotifierProvider<TrackUploadNotifier, TrackUploadState>((ref) {
  final repo = ref.read(trackRepositoryProvider);
  final repo2 = ref.read(authRepositoryProvider);
  return TrackUploadNotifier(repo, repo2);
});



