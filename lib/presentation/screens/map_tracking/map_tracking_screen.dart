import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ladamadelcanchoapp/presentation/providers/location/location_provider.dart';
import 'package:ladamadelcanchoapp/presentation/screens/tracks/preview-track-screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location/location.dart';

class MapTrackingScreen extends ConsumerStatefulWidget {
  static const name = 'map-tracking-screen';

  const MapTrackingScreen({super.key});

  @override
  ConsumerState<MapTrackingScreen> createState() => _MapTrackingScreenState();
}

class _MapTrackingScreenState extends ConsumerState<MapTrackingScreen> {
  GoogleMapController? mapController;
  LatLng? initialPosition;
  StreamSubscription<LocationData>? locationSubscription;
  MapType currentMapType = MapType.satellite;

  @override
  void initState() {
    super.initState();
    getInitialLocation();
  }

  Future<void> getInitialLocation() async {
    final location = Location();

    final permissionGranted = await Permission.location.request();
    if (!permissionGranted.isGranted) {
      return;
    }

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

    final currentLocation = await location.getLocation();
    if(mounted) {
      setState(() {
        initialPosition = LatLng(
          currentLocation.latitude!,
          currentLocation.longitude!,
        );
      });
    }
    

    locationSubscription = location.onLocationChanged.listen((newLocation) {
      if (!mounted || mapController == null) return;

      final newLatLng = LatLng(newLocation.latitude!, newLocation.longitude!);
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: newLatLng, zoom: 16),
        ),
      );
    });
  }

  void toggleMapType() {
    setState(() {
      currentMapType = currentMapType == MapType.satellite
          ? MapType.normal
          : MapType.satellite;
    });
  }

  /*
  Future<bool> checkLocationPermission() async {
    final locationStatus = await Permission.location.request();
    return locationStatus.isGranted;
  }
  */
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
    locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final locationNotifier = ref.read(locationProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Grabación Track')),
      body: initialPosition == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 15),
                  Text('Obtendiendo ubicación...')
                ],
              ),
            )
          : SizedBox(
              height: 400,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: GoogleMap(
                  mapType: currentMapType,
                  initialCameraPosition: CameraPosition(
                    target: initialPosition!,
                    zoom: 16,
                  ),
                  myLocationEnabled: true,
                  polylines: {
                    Polyline(
                      polylineId: const PolylineId('tracking_polyline'),
                      points: locationNotifier.polylinePoints,
                      width: 5,
                      color: Colors.blue,
                    ),
                  },
                  onMapCreated: (controller) => mapController = controller,
                ),
              ),
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'mapTypeButton',
            backgroundColor: Colors.grey[800],
            onPressed: toggleMapType,
            child: const Icon(Icons.layers),
          ),
          const SizedBox(height: 12),
          // Dentro del botón flotante trackingButton
          FloatingActionButton(
            heroTag: 'trackingButton',
            backgroundColor: !locationState.isTracking
                ? (initialPosition == null ? Colors.grey : Colors.green)
                : Colors.red,
            onPressed: initialPosition == null
                ? null // ⛔ deshabilitado si no hay posición inicial
                : () async {
                    if (!locationState.isTracking) {
                      
                      locationNotifier.startTracking();


                    } else {
                      final file = await locationNotifier.stopTrackingAndSaveGpx();

                      if (context.mounted) {
                        context.pushNamed(
                          TrackPreviewScreen.name,
                          extra: {
                            'trackFile': file,
                            'points': locationState.points,
                          },
                        );
                      }

                    }
                  },
            child: Icon(locationState.isTracking ? Icons.stop : Icons.play_arrow),
          )

        ],
      ),
    );
  }
}



