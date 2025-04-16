import 'dart:io';
import 'package:flutter/material.dart';


Future<bool> checkInternetAccess() async {
  try {
    final result = await InternetAddress.lookup('google.com');
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}



/// Comprueba si hay acceso real a internet.
/// Si no lo hay, muestra un SnackBar con el mensaje personalizado o uno por defecto.
Future<bool> checkAndWarnIfNoInternet(BuildContext context, {String? message}) async {
  try {
    final result = await InternetAddress.lookup('google.com');
    final hasInternet = result.isNotEmpty && result[0].rawAddress.isNotEmpty;

    if (!hasInternet && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message ?? '❌ No hay conexión a internet'),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    return hasInternet;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message ?? '❌ No hay conexión a internet'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
    return false;
  }
}
