// Esta función NO usa context
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

Future<String?> checkPermissionsSilently() async {
  final locationStatus = await Permission.location.request();
  if (!locationStatus.isGranted) return 'Debes otorgar permiso de ubicación';

  final backgroundStatus = await Permission.locationAlways.request();
  if (backgroundStatus.isPermanentlyDenied) {
    openAppSettings();
    return 'Debes activar ubicación en segundo plano';
  }

  if (await Permission.notification.isDenied) {
    final notifStatus = await Permission.notification.request();
    await Future.delayed(const Duration(milliseconds: 300));
    if (notifStatus.isDenied) {
      return 'Debes permitir notificaciones para grabar correctamente';
    }
  }

  return null; // ✅ Todo OK
}

// Esta función maneja el context después
Future<bool> requestPermissionsWithUI(BuildContext context) async {
  final errorMessage = await checkPermissionsSilently();
  if (errorMessage != null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
    return false;
  }
  return true;
}