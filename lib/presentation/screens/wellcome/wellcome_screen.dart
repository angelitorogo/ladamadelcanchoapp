import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

class WellcomeScreen extends StatefulWidget {

  static const name = 'wellcome-screen';

  const WellcomeScreen({super.key});

  @override
  State<WellcomeScreen> createState() => _WellcomeScreenState();
}

class _WellcomeScreenState extends State<WellcomeScreen> {

  @override
  void initState() {
    super.initState();
    getPermissions();
  }

  Future<void> getPermissions() async {

    final locationGranted = await checkLocationPermission();
    if (!locationGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Debes otorgar permiso de ubicación")),
        );
      }
      return;
    }

    // 🟡 Pedimos permiso para mostrar notificaciones (Android 13+)
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
      // ✅ Esperar unos ms para que Android aplique los permisos correctamente
      await Future.delayed(const Duration(milliseconds: 500));
      // Verificamos otra vez luego de pedir
      if (await Permission.notification.isDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Debes permitir notificaciones para grabar correctamente")),
          );
        }
        return;
      }
    }

    if(context.mounted) {
      // ignore: use_build_context_synchronously
      GoRouter.of(context).go('/');
    }
    

    return;

  }

  Future<bool> checkLocationPermission() async {
    final locationStatus = await Permission.location.request();

    if (!locationStatus.isGranted) return false;

    // ✅ AÑADIDO: pedir permiso para ubicación en segundo plano
    final backgroundStatus = await Permission.locationAlways.request();

    if (backgroundStatus.isPermanentlyDenied) {
      openAppSettings(); // <<<<<<<<<<<<<<<<<<<<<< ABRE CONFIGURACIÓN
      return false;
    }

    return backgroundStatus.isGranted;
  }


  @override
  void dispose() {

    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/icono.png',
          width: 150, // opcional
          height: 150, // opcional
          fit: BoxFit.contain, // opcional: cover, fill, etc.
        ),
        Text("La Dama del Cancho", style: Theme.of(context).textTheme.titleLarge),
        const  SizedBox(height: 20),
        const CircularProgressIndicator(strokeWidth: 2,)
      ],
    );
  }
}