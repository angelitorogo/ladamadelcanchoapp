import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/presentation/providers/connectivity/network_info_provider.dart';

Future<bool> checkConnectivityBeforeRequest(WidgetRef ref, BuildContext context) async {
  final connection = ref.read(networkInfoProvider);
  if (!connection.hasInternet) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Sin conexión a internet'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return false;
  }

  return true;
}
