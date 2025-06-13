


import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/domain/entities/track.dart';

class TrackNotifier extends StateNotifier<Track?> {
  TrackNotifier() : super(null);

  void loadTrack(Track track) {
    state = track;
  }

  void updateTrack(Track updatedTrack) {

    final track = updatedTrack.copyWith(isFavorite: !!updatedTrack.isFavorite!);

    state = track;
  }

  void toggleFavoriteLocal() {
    if (state == null) return;
    state = state!.copyWith(isFavorite: !state!.isFavorite!); // ← aquí sí lo inviertes
  }

    void clearTrack() {
      state = null;
    }
  }

final trackProvider = StateNotifierProvider<TrackNotifier, Track?>(
  (ref) => TrackNotifier(),
);
