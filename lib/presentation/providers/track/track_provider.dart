

import 'dart:io';
import 'package:ladamadelcanchoapp/infraestructure/models/gpx_result.dart';
import 'package:ladamadelcanchoapp/infraestructure/repositories/auth_repository_impl.dart';
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

  Future<Map<String, dynamic>?> uploadTrack(String name, File file, WidgetRef ref, String description, String type, String distance, String elevationGain, File captureMap, { List<File> images = const [] } ) async {
    state = const TrackUploadState(status: TrackUploadStatus.loading);

    images.insert(0, captureMap);
  

    try {
      
      final originalFileName = '/storage/emulated/0/Download/GPX/tracks/${file.uri.pathSegments.last}';
      GpxResult result;
      File uploadFile;

      if(file.uri.pathSegments.last.replaceAll('.gpx', '') != name && description.isNotEmpty){

        result = await ref.read(locationProvider.notifier).stopTrackingAndSaveGpx(overrideName: name, overrideDescription: description);
        uploadFile = result.gpxFile;

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

        result = await ref.read(locationProvider.notifier).stopTrackingAndSaveGpx(overrideDescription: description);
        uploadFile = result.gpxFile;

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

        result = await ref.read(locationProvider.notifier).stopTrackingAndSaveGpx(overrideName: name);
        uploadFile = result.gpxFile;

        final oldFilePath = originalFileName;
        final oldFile = File(oldFilePath);

        if (await oldFile.exists()) {
          try {
            await oldFile.delete();
          } catch (e) {
            throw Exception(e);
          }
        }
        
      }  else {

        uploadFile = File(originalFileName);

      }


      repository2.fetchCsrfToken(); //cogerlo si se puede del authState
      
      //print('✅ Images2: $images');
      final response = await repository.uploadTrack(name, uploadFile, description, type, distance, elevationGain, images: images );
      state = const TrackUploadState(status: TrackUploadStatus.success);
      return response;
    } catch (e) {
      state = const TrackUploadState(
        status: TrackUploadStatus.error,
        message: 'Error al subir el track',
      );
      return null;
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



