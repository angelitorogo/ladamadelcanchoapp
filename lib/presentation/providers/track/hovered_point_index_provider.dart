

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HoveredPointNotifier extends StateNotifier<LatLng?> {
  HoveredPointNotifier() : super(null);

  void setPoint(LatLng? point) => state = point;

  void clear() => state = null;
}

final hoveredPointLatLngProvider =
    StateNotifierProvider<HoveredPointNotifier, LatLng?>(
  (ref) => HoveredPointNotifier(),
);

