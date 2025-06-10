
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/domain/entities/track.dart';
import 'package:ladamadelcanchoapp/infraestructure/repositories/track_repository_impl.dart';
import 'package:ladamadelcanchoapp/presentation/providers/auth/auth_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/track/track_list_repository_provider.dart';



enum TrackListStatus { initial, loading, loaded, error }

class TrackListState {
  final TrackListStatus status;
  final List<Track> tracks;
  final int currentPage;
  final int totalPages;
  final String orderBy;
  final String direction;
  final String? errorMessage;
  final bool? changeSetting;
  final int totalTracks;

  const TrackListState({
    this.status = TrackListStatus.initial,
    this.tracks = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.orderBy = 'created_at',
    this.direction = 'desc',
    this.errorMessage,
    this.changeSetting = false,
    this.totalTracks = 0,
  });

  TrackListState copyWith({
    TrackListStatus? status,
    List<Track>? tracks,
    int? currentPage,
    int? totalPages,
    String? orderBy,
    String? direction,
    String? errorMessage,
    bool? changeSetting,
    int? totalTracks
  }) {
    return TrackListState(
      status: status ?? this.status,
      tracks: tracks ?? this.tracks,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      orderBy: orderBy ?? this.orderBy,
      direction: direction ?? this.direction,
      errorMessage: errorMessage ?? this.errorMessage,
      changeSetting: changeSetting ?? this.changeSetting,
      totalTracks: totalTracks ?? this.totalTracks
    );
  }
}


class TrackListNotifier extends StateNotifier<TrackListState> {
  final TrackRepositoryImpl  trackListRepository;


  TrackListNotifier(this.trackListRepository) : super(const TrackListState());

  
  TrackListState reset() {
    //print('✅ Reset state');
    return const TrackListState(); // Estado inicial
  }

  Future<void> resetState() async {
    state = reset();
  }

  Future<void> resetStatusInitial() async {
    state = state.copyWith(status: TrackListStatus.initial, changeSetting: false);
  }

  Future<void> loadTracks(WidgetRef ref, {int limit = 10, int page = 1, String? loggedUser, String? userId, bool append = false}) async {
    
    
    if (state.totalPages != 0 && page > state.totalPages) return;// ❌ No más páginas

    state = state.copyWith(status: TrackListStatus.loading);

    final String? loggedUser = ref.read(authProvider).user?.id;
    //print('LOGGEDUSER: $loggedUser');

    try {
      final response = await trackListRepository.loadAllTracks(
        ref,
        limit: limit,
        page: page, 
        loggedUser: loggedUser,
        userId: userId,
        orderBy: state.orderBy,
        direction: state.direction,
      );
      

      final tracks = (response['tracks'] as List).map((trackJson) {
        return Track.fromJson(trackJson);
      }).toList();

      final metadata = Metadata.fromJson(response['metadata']);

      

      state = state.copyWith(
        status: TrackListStatus.loaded,
        changeSetting: false,
        tracks: append ? [...state.tracks, ...tracks] : tracks,
        currentPage: metadata.page,
        totalPages: metadata.lastPage,
        totalTracks: metadata.totalTracks
      );

      //print('📃 ${state.tracks.length}');

    } catch (e) {
      state = state.copyWith(
        status: TrackListStatus.error,
        errorMessage: '❌ Error al cargar tracks: ${e.toString()}',
      );
    }
  }

  Future<void> changeOrdersAndDirection(WidgetRef ref, String orderBy, String direction, String? userId) async {

    reset();

    state = state.copyWith(
      orderBy: orderBy,
      direction: direction,
    );

    state = state.copyWith(
      changeSetting: true,
    );

    //loadTracks(ref, userId: userId);
    await ref.read(trackListProvider.notifier).loadTracks(
      ref,
      page: 1,
      append: false,
      userId: userId,
      loggedUser: ref.read(authProvider).user?.id
    );

  }

  void updateFavoriteStatus(String trackId, bool isFavorite) {
    final updatedTracks = state.tracks.map((track) {
      if (track.id == trackId) {
        return track.copyWith(isFavorite: isFavorite);
      }
      return track;
    }).toList();

    state = state.copyWith(tracks: updatedTracks);
  }


  


}


final trackListProvider = StateNotifierProvider<TrackListNotifier, TrackListState>( (ref) {
  final trackListRepository = ref.watch(trackListRepositoryProvider);
  return TrackListNotifier(trackListRepository);
});