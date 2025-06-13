import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/domain/entities/track.dart';
import 'package:ladamadelcanchoapp/infraestructure/repositories/track_repository_impl.dart';
import 'package:ladamadelcanchoapp/presentation/providers/auth/auth_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/track/track_list_repository_provider.dart';

enum TrackListStatus { initial, loading, loaded, error }

class TrackNearestListState {
  final TrackListStatus status;
  final List<Track> tracks;
  final String? errorMessage;

  const TrackNearestListState({
    this.status = TrackListStatus.initial,
    this.tracks = const [],
    this.errorMessage,
  });

  bool get isLoading => status == TrackListStatus.loading;
  bool get isError => status == TrackListStatus.error;

  TrackNearestListState copyWith({
    TrackListStatus? status,
    List<Track>? tracks,
    String? errorMessage,
  }) {
    return TrackNearestListState(
      status: status ?? this.status,
      tracks: tracks ?? this.tracks,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class TrackNearestListNotifier extends StateNotifier<TrackNearestListState> {
  final TrackRepositoryImpl trackListRepository;

  TrackNearestListNotifier(this.trackListRepository) : super(const TrackNearestListState());

  TrackNearestListState reset() {
    return const TrackNearestListState(); // Estado inicial
  }

  Future<void> loadNearestTracks(WidgetRef ref, String trackId, {int limit = 5}) async {
    state = state.copyWith(status: TrackListStatus.loading);

    final String? loggedUser = ref.read(authProvider).user?.id;

    try {
      final tracks = await trackListRepository.getNearestTracks(trackId, loggedUser, limit: limit);
      state = state.copyWith(tracks: tracks, status: TrackListStatus.loaded);
    } catch (e) {
      state = state.copyWith(
        tracks: [],
        status: TrackListStatus.error,
        errorMessage: e.toString(),
      );
      //print('Error cargando tracks cercanos: $e');
    }
  }
}

final trackNearestListProvider = StateNotifierProvider<TrackNearestListNotifier, TrackNearestListState>((ref) {
  final trackNearestListRepository = ref.watch(trackListRepositoryProvider);
  return TrackNearestListNotifier(trackNearestListRepository);
});
