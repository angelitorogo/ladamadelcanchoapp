import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ladamadelcanchoapp/domain/entities/location_point.dart';
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
  bool hasCenteredInitially = false;

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

      // 🔁 Solo centrar una vez al principio
      if (!hasCenteredInitially) {
        final newLatLng = LatLng(newLocation.latitude!, newLocation.longitude!);
        mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: newLatLng, zoom: 16),
          ),
        );
        hasCenteredInitially = true; // ✅ Ya centrado
      }
    });

  }

  void toggleMapType() {
    setState(() {
      currentMapType = currentMapType == MapType.satellite
          ? MapType.normal
          : MapType.satellite;
    });
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
          : Column(
            children: [
              SizedBox(
                height: 400,
                child: Padding(
                  padding: const EdgeInsets.all(20),
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

              // 📊 Estadísticas en tiempo real
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        const Text('Distancia', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${(locationState.distance / 1000).toStringAsFixed(2)} km'),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Desnivel +', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${locationState.elevationGain.toStringAsFixed(0)} m'),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Velocidad', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${_calculateSpeed(locationState).toStringAsFixed(1)} km/h'),
                      ],
                    ),
                  ],
                ),
              ),


              // 📍 Lista de puntos
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Builder(
                    builder: (context) {
                      final reversedPoints = locationState.points.reversed.toList();

                      return ListView.builder(

                        itemCount: reversedPoints.length,
                        itemBuilder: (context, index) {
                          final point = reversedPoints[index];

                          double distance = 0;
                          double elevationDiff = 0;

                          if (index < reversedPoints.length - 1) {
                            final prev = reversedPoints[index + 1];
                            distance = _calculateDistance(point, prev);
                            elevationDiff = point.elevation - prev.elevation;
                          }

                          Color? textColor;
                          if (elevationDiff.abs() > 15) {
                            textColor = Colors.red;
                          } else if (distance > 25) {
                            textColor = Colors.orange;
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Text(
                              '${locationState.points.length - index}. '
                              'ele: ${point.elevation.toStringAsFixed(0)} m, '
                              'dist: ${distance.toStringAsFixed(1)} m, '
                              'desnivel: ${elevationDiff.toStringAsFixed(1)} m',
                              style: TextStyle(fontSize: 14, color: textColor),
                            ),
                          );
                        },
                      );
                    },
                                      )





                ),
              ),



            ],
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

          if (locationState.isTracking)
            FloatingActionButton(
              heroTag: 'pauseResumeButton',
              backgroundColor: locationState.isPaused ? Colors.orange : Colors.blue,
              onPressed: () {
                if (locationState.isPaused) {
                  locationNotifier.resumeTracking();
                } else {
                  locationNotifier.pauseTracking();
                }
              },
              child: Icon(locationState.isPaused ? Icons.play_arrow : Icons.pause),
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

  double _calculateDistance(LocationPoint a, LocationPoint b) {
    const R = 6371000; // Radio de la Tierra en metros
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLon = _degToRad(b.longitude - a.longitude);
    final lat1 = _degToRad(a.latitude);
    final lat2 = _degToRad(b.latitude);

    final aCalc = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(aCalc), sqrt(1 - aCalc));
    return R * c;
  }

  double _degToRad(double deg) => deg * pi / 180;

  double _calculateSpeed(LocationState state) {
    if (state.points.length < 2) return 0;

    final start = state.points.first.timestamp;
    final end = state.points.last.timestamp;
    final seconds = end.difference(start).inSeconds;

    if (seconds == 0) return 0;

    final hours = seconds / 3600;
    final distanceKm = state.distance / 1000;

    return distanceKm / hours;
  }


}



