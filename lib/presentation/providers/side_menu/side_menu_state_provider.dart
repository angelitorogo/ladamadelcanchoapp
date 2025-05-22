import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/domain/entities/user.dart';

class SideMenuState {
  final bool isPrincipalExpanded;
  final bool isTracksExpanded;
  final bool isOrderExpanded;
  final UserEntity? userScreen;

  const SideMenuState({
    this.isPrincipalExpanded = true,
    this.isTracksExpanded = false,
    this.isOrderExpanded = false,
    this.userScreen,
  });

  SideMenuState copyWith({
    bool? isPrincipalExpanded,
    bool? isTracksExpanded,
    bool? isOrderExpanded,
    UserEntity? userScreen
  }) {
    return SideMenuState(
      isPrincipalExpanded: isPrincipalExpanded ?? this.isPrincipalExpanded,
      isTracksExpanded: isTracksExpanded ?? this.isTracksExpanded,
      isOrderExpanded: isOrderExpanded ?? this.isOrderExpanded,
      userScreen: userScreen ?? this.userScreen,
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

  void serUserScreen(UserEntity user) {
    state = state.copyWith(userScreen: user);
  }

  void resetUserScreen() {
    state = state.copyWith(userScreen: null);
  }
}

final sideMenuStateProvider =
    StateNotifierProvider<SideMenuStateNotifier, SideMenuState>(
        (ref) => SideMenuStateNotifier());
