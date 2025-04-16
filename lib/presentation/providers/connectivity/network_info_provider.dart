import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

enum NetworkStatus {
  wifi,
  mobile,
  none,
}

class NetworkInfo {
  final NetworkStatus status;
  final bool hasInternet;

  NetworkInfo({required this.status, required this.hasInternet});
}

final networkInfoProvider =
    StateNotifierProvider<NetworkInfoNotifier, NetworkInfo>(
  (ref) => NetworkInfoNotifier(),
);

class NetworkInfoNotifier extends StateNotifier<NetworkInfo> {
  late final StreamSubscription _subscription;

  NetworkInfoNotifier()
      : super(NetworkInfo(status: NetworkStatus.none, hasInternet: false)) {
    _init();
  }

  void _init() {
    _subscription = Connectivity().onConnectivityChanged.listen((result) async {
      final status = _mapResultToStatus(result);
      final hasInternet = await _checkInternetAccess();
      state = NetworkInfo(status: status, hasInternet: hasInternet);
    });

    // También comprobamos al arrancar
    Connectivity().checkConnectivity().then((result) async {
      final status = _mapResultToStatus(result);
      final hasInternet = await _checkInternetAccess();
      state = NetworkInfo(status: status, hasInternet: hasInternet);
    });
  }

  NetworkStatus _mapResultToStatus(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return NetworkStatus.wifi;
      case ConnectivityResult.mobile:
        return NetworkStatus.mobile;
      default:
        return NetworkStatus.none;
    }
  }

  Future<bool> _checkInternetAccess() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

