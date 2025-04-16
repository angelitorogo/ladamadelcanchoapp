// pending_tracks_provider.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final pendingTracksProvider = StateNotifierProvider<PendingTracksNotifier, List<Map<String, dynamic>>>(
  (ref) => PendingTracksNotifier(),
);

class PendingTracksNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  PendingTracksNotifier() : super([]) {
    loadTracks();
  }

  Future<List<Map<String, dynamic>>> loadTracks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('offline_snapshots') ?? [];
    final tracks = jsonList.map((json) => jsonDecode(json) as Map<String, dynamic>).toList();
    state = tracks;
    return state;
  }

  Future<List<Map<String, dynamic>>> removeTrack(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final updatedList = [...state];
    updatedList.removeAt(index);
    final jsonList = updatedList.map((track) => jsonEncode(track)).toList();
    await prefs.setStringList('offline_snapshots', jsonList);
    state = updatedList;
    return state;
  }
}
