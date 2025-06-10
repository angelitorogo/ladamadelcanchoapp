import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/presentation/providers/auth/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ladamadelcanchoapp/domain/entities/pending_track.dart';

final pendingTracksProvider =
    StateNotifierProvider<PendingTracksNotifier, List<PendingTrack>>(
  (ref) => PendingTracksNotifier(ref),
);

class PendingTracksNotifier extends StateNotifier<List<PendingTrack>> {
  final Ref ref;

  PendingTracksNotifier(this.ref) : super([]) {
    loadTracks();
  }

  /// Cargar los tracks desde SharedPreferences
  Future<void> loadTracks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('offline_snapshots') ?? [];

    // 🔐 Obtener el ID del usuario logado
    final currentUserId = ref.read(authProvider).user?.id;

    final tracks = jsonList
      .map((json) => jsonDecode(json))
      .where((map) => (map['userId']?.toString() ?? '') == currentUserId)
      .map((map) => PendingTrack.fromMap(map))
      .toList();

    state = tracks;
  }

  /// Eliminar un track por índice y actualizar SharedPreferences
  Future<void> removeTrack(int index) async {
    final prefs = await SharedPreferences.getInstance();

    final updatedList = [...state];
    if (index >= 0 && index < updatedList.length) {
      updatedList.removeAt(index);
    }

    final jsonList = updatedList.map((track) => jsonEncode(track.toMap())).toList();
    await prefs.setStringList('offline_snapshots', jsonList);

    state = updatedList;
  }

  /// Añadir un nuevo track (por si lo quieres en el futuro)
  Future<void> addTrack(PendingTrack track) async {
    final prefs = await SharedPreferences.getInstance();

    final updatedList = [...state, track];
    final jsonList = updatedList.map((t) => jsonEncode(t.toMap())).toList();
    await prefs.setStringList('offline_snapshots', jsonList);

    state = updatedList;
  }

  
  List<PendingTrack> reset() {
    return const []; // Estado inicial
  }

  Future<void> resetState() async {
    state = reset();
  }


}
