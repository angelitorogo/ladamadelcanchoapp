import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider que guarda el punto actual sobrevolado (hovered)
/// desde el gráfico de elevación, para ser mostrado dinámicamente
/// como un marcador blanco sobre el mapa.
final hoveredPointIndexProvider = StateProvider<int?>((ref) => null);


/*import 'package:flutter_riverpod/flutter_riverpod.dart';
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

*/