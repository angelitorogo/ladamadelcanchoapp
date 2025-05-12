
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/domain/entities/track.dart';
import 'package:ladamadelcanchoapp/infraestructure/repositories/track_repository_impl.dart';
import 'package:ladamadelcanchoapp/presentation/providers/track/track_list_repository_provider.dart';



enum TrackListStatus { initial, loading, loaded, error }

class TrackListState {
  final TrackListStatus status;
  final List<Track> tracks;
  final int currentPage;
  final int totalPages;
  final String? errorMessage;

  const TrackListState({
    this.status = TrackListStatus.initial,
    this.tracks = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.errorMessage,
  });

  TrackListState copyWith({
    TrackListStatus? status,
    List<Track>? tracks,
    int? currentPage,
    int? totalPages,
    String? errorMessage,
  }) {
    return TrackListState(
      status: status ?? this.status,
      tracks: tracks ?? this.tracks,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      errorMessage: errorMessage,
    );
  }
}


class TrackListNotifier extends StateNotifier<TrackListState> {
  final TrackRepositoryImpl  trackListRepository;


  TrackListNotifier(this.trackListRepository) : super(const TrackListState());

  TrackListState reset() {
    return const TrackListState(); // Estado inicial
  }

  Future<void> loadTracks({int limit = 5, int page = 1, String? userId, bool append = false}) async {
    
    if (page > state.totalPages) return; // ❌ No más páginas

    state = state.copyWith(status: TrackListStatus.loading);


    try {
      final response = await trackListRepository.loadAllTracks(
        limit: limit,
        page: page,
        userId: userId,
      );

      

      final tracks = (response['tracks'] as List).map((trackJson) {
        return Track.fromJson(trackJson);
      }).toList();

      final metadata = response['metadata'];

      state = state.copyWith(
        status: TrackListStatus.loaded,
        tracks: append ? [...state.tracks, ...tracks] : tracks,
        currentPage: metadata['page'],
        totalPages: metadata['lastPage'],
      );

      //print('📃 ${state.tracks.length}');

    } catch (e) {
      state = state.copyWith(
        status: TrackListStatus.error,
        errorMessage: '❌ Error al cargar tracks: ${e.toString()}',
      );
    }
  }


}


final trackListProvider = StateNotifierProvider<TrackListNotifier, TrackListState>( (ref) {
  final trackListRepository = ref.watch(trackListRepositoryProvider);
  return TrackListNotifier(trackListRepository);
});