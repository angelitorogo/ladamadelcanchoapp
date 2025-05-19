import 'package:flutter_riverpod/flutter_riverpod.dart';

class SideMenuState {
  final bool isPrincipalExpanded;
  final bool isTracksExpanded;
  final bool isOrderExpanded;

  const SideMenuState({
    this.isPrincipalExpanded = true,
    this.isTracksExpanded = false,
    this.isOrderExpanded = false,
  });

  SideMenuState copyWith({
    bool? isPrincipalExpanded,
    bool? isTracksExpanded,
    bool? isOrderExpanded,
  }) {
    return SideMenuState(
      isPrincipalExpanded: isPrincipalExpanded ?? this.isPrincipalExpanded,
      isTracksExpanded: isTracksExpanded ?? this.isTracksExpanded,
      isOrderExpanded: isOrderExpanded ?? this.isOrderExpanded,
    );
  }
}

class SideMenuStateNotifier extends StateNotifier<SideMenuState> {
  SideMenuStateNotifier() : super(const SideMenuState());

  void setPrincipalExpanded(bool expanded) {
    state = state.copyWith(isPrincipalExpanded: expanded);
  }

  void setTracksExpanded(bool expanded) {
    state = state.copyWith(isTracksExpanded: expanded);
  }

  void setOrderExpanded(bool expanded) {
    state = state.copyWith(isOrderExpanded: expanded);
  }
}

final sideMenuStateProvider =
    StateNotifierProvider<SideMenuStateNotifier, SideMenuState>(
        (ref) => SideMenuStateNotifier());
