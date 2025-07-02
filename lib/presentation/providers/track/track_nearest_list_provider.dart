import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/domain/entities/track.dart';
import 'package:ladamadelcanchoapp/infraestructure/repositories/track_repository_impl.dart';
import 'package:ladamadelcanchoapp/presentation/providers/auth/auth_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/track/track_list_repository_provider.dart';

enum TrackNearestListStatus { initial, loading, loaded, error }

class TrackNearestListState {
  final TrackNearestListStatus status;
  final List<Track> tracks;
  final String? errorMessage;

  const TrackNearestListState({
    this.status = TrackNearestListStatus.initial,
    this.tracks = const [],
    this.errorMessage,
  });

  bool get isLoading => status == TrackNearestListStatus.loading;
  bool get isError => status == TrackNearestListStatus.error;

  TrackNearestListState copyWith({
    TrackNearestListStatus? status,
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

  Future<void> resetState() async {
    state = reset();
  }

  Future<void> loadNearestTracks(WidgetRef ref, String trackId, {int limit = 5}) async {
    state = state.copyWith(status: TrackNearestListStatus.loading);

    final String? loggedUser = ref.read(authProvider).user?.id;

    try {
      final tracks = await trackListRepository.getNearestTracks(trackId, loggedUser, limit: limit);
      state = state.copyWith(tracks: tracks, status: TrackNearestListStatus.loaded);
    } catch (e) {
      state = state.copyWith(
        tracks: [],
        status: TrackNearestListStatus.error,
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
