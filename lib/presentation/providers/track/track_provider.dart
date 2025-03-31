

import 'dart:io';
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

  TrackUploadNotifier(this.repository) : super(const TrackUploadState());

  Future<Map<String, dynamic>?> uploadTrack(String name, File file) async {
    state = const TrackUploadState(status: TrackUploadStatus.loading);

    try {
      final response = await repository.uploadTrack(name, file);
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
  return TrackUploadNotifier(repo);
});



