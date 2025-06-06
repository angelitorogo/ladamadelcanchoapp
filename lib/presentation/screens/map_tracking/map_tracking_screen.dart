import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ladamadelcanchoapp/domain/entities/location_point.dart';
import 'package:ladamadelcanchoapp/infraestructure/datasources/elevation_datasource_impl.dart';
import 'package:ladamadelcanchoapp/infraestructure/datasources/location_datasource_impl.dart';
import 'package:ladamadelcanchoapp/infraestructure/repositories/elevation_repository_impl.dart';
import 'package:ladamadelcanchoapp/presentation/providers/auth/auth_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/location/location_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/pendings/pending_tracks_provider.dart';
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
  LocationPoint? initialPosition;
  StreamSubscription<LocationData>? locationSubscription;
  MapType currentMapType = MapType.satellite;
  bool hasCenteredInitially = false;
  bool followUser = false;
  LocationData? _lastPosition;
  TrackingMode selectedMode = TrackingMode.walking; // 🚶 Modo por defecto
  

  @override
  void initState() {
    super.initState();

    if( !ref.read(authProvider).isAuthenticated) {
      return;
    }

    getInitialLocation();
  }

  Future<void> getInitialLocation() async {
    final location = Location();

    
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

    if(currentLocation.isMock!) {
      print("⚠️ Ubicación simulada detectada");
    }

     // 🟡 Corregimos la altitud ANTES de usar el punto
    final elevationRepository = ElevationRepositoryImpl(ElevationDatasourceImpl());
    LocationPoint pointToCorrect;

    try {
      pointToCorrect = LocationPoint(latitude: currentLocation.latitude!, longitude: currentLocation.longitude!, elevation: currentLocation.altitude!, timestamp: DateTime(currentLocation.time!.toInt()));
    } catch (e) {
      return;
    }  
    
    final response = await elevationRepository.getElevationForPoint(pointToCorrect);




    if(mounted && !response.corrected) {
      setState(() {
        initialPosition = LocationPoint(
          latitude: currentLocation.latitude!,
          longitude: currentLocation.longitude!,
          elevation: currentLocation.altitude!,
          timestamp: DateTime(currentLocation.time!.toInt()
        ));
      });
    } else {
      setState(() {
        initialPosition = LocationPoint(
          latitude: response.point.latitude,
          longitude: response.point.longitude,
          elevation: response.point.elevation,
          timestamp: response.point.timestamp
        );
      });
    }
    

    locationSubscription = location.onLocationChanged.listen((newLocation) {
      if (!mounted || mapController == null) return;

      final currentLatLng = LatLng(newLocation.latitude!, newLocation.longitude!);

      if (followUser) {
        final previousLatLng = _lastPosition != null
            ? LatLng(_lastPosition!.latitude!, _lastPosition!.longitude!)
            : currentLatLng;

        final bearing = _calculateBearing(previousLatLng, currentLatLng);

        mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: currentLatLng,
              zoom: 16,
              bearing: bearing,
            ),
          ),
        );
      }

      _lastPosition = newLocation;
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

  



  void toggleMapType() {
    setState(() {
      currentMapType = currentMapType == MapType.satellite
          ? MapType.normal
          : MapType.satellite;
    });
  }

  void toggleTrackingMode() {
    setState(() {
      switch (selectedMode) {
        case TrackingMode.walking:
          selectedMode = TrackingMode.cycling; // 🚴
          break;
        case TrackingMode.cycling:
          selectedMode = TrackingMode.driving; // 🚗
          break;
        case TrackingMode.driving:
          selectedMode = TrackingMode.walking; // 🔁
          break;
      }

      ref.read(locationProvider.notifier).setTrackingMode(selectedMode);
    });

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

    final String typeMode = switch (selectedMode) {
    TrackingMode.walking => 'Senderismo',
    TrackingMode.cycling => 'Ciclismo',
    TrackingMode.driving => 'Conduciendo',

  };

    return Scaffold(
      appBar: AppBar(title: Text(typeMode)),
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
                      target: LatLng(initialPosition!.latitude, initialPosition!.longitude),
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
              // 📊 Estadísticas en tiempo real
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Puntos', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('${locationState.points.length}'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Distancia', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('${(locationState.distance / 1000).toStringAsFixed(2)} km'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Desnivel +', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('${locationState.elevationGain.toStringAsFixed(1)} m'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Altitud', style: TextStyle(fontWeight: FontWeight.bold)),
                          locationState.points.isNotEmpty 
                          ? Text('${locationState.points.last.elevation.toStringAsFixed(0)} m')
                          : Text('${initialPosition!.elevation.toStringAsFixed(1)} m')
                        ],
                      ),
                    ),
                  ],
                ),
              ),



              // 📍 Lista de puntos
              /*
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Builder(
                    builder: (context) {
                      final discardedPoints = locationState.points.reversed.toList();

                      return ListView.builder(

                        itemCount: discardedPoints.length,
                        itemBuilder: (context, index) {
                          final point = discardedPoints[index];

                          double distance = 0;
                          double elevationDiff = 0;

                          if (index < discardedPoints.length - 1) {
                            final prev = discardedPoints[index + 1];
                            distance = _calculateDistance(point, prev);
                            elevationDiff = point.elevation - prev.elevation;
                          }

                          Color? textColor;
                          if (elevationDiff.abs() >= 15 && elevationDiff.abs() < 30  && distance >= 15 && distance < 30) {
                            textColor = Colors.orange;
                          } else if (elevationDiff.abs() >= 30  && distance >= 30) {
                            textColor = Colors.red;
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Text(
                              '${locationState.points.length - index}. '
                              'ele: ${point.elevation.toStringAsFixed(2)} m, '
                              'dist: ${distance.toStringAsFixed(2)} m, '
                              'desnivel: ${elevationDiff.toStringAsFixed(2)} m',
                              style: TextStyle(fontSize: 14, color: textColor),
                            ),
                          );
                        },
                      );
                    },
                                      )





                ),
              ),
              */


            ],
          ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 0, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            /// 🔹 Zona izquierda: tipo de mapa + seguir orientación
            Row(
              children: [
                FloatingActionButton(
                  heroTag: 'mapTypeButton',
                  backgroundColor: Colors.grey[800],
                  onPressed: toggleMapType,
                  child: const Icon(Icons.layers),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  heroTag: 'followButton',
                  backgroundColor: followUser ? Colors.blueAccent : Colors.grey,
                  onPressed: () {
                    setState(() {
                      followUser = !followUser;
                    });
                  },
                  tooltip: followUser
                      ? 'Orientado al movimiento (pulsar para liberar mapa)'
                      : 'Modo libre (pulsar para seguir orientación)',
                  child: Icon(
                    followUser ? Icons.navigation : Icons.explore_off, // 👈 icono más claro
                  ),
                ),

                const SizedBox(width: 12),

                if (!locationState.isTracking)
                  FloatingActionButton(
                    heroTag: 'modeToggleButton',
                    backgroundColor: Colors.deepPurple,
                    onPressed: toggleTrackingMode,
                    tooltip: 'Cambiar modo: ${selectedMode.name.toUpperCase()}',
                    child: Icon(
                      selectedMode == TrackingMode.walking
                          ? Icons.directions_walk
                          : selectedMode == TrackingMode.cycling
                              ? Icons.directions_bike
                              : Icons.directions_car,
                    ),
                  ),
                const SizedBox(width: 12),

              ],
            ),

            /// 🔹 Zona derecha: pausar / parar / grabar
            Row(
              children: [
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
                const SizedBox(width: 12),
                FloatingActionButton(
                  heroTag: 'trackingButton',
                  backgroundColor: !locationState.isTracking
                      ? (initialPosition == null ? Colors.grey : Colors.green)
                      : Colors.red,
                  onPressed: initialPosition == null
                      ? null
                      : () async {
                          if (!locationState.isTracking) {
                            locationNotifier.startTracking(mode: selectedMode); // ✅ PASAMOS MODO SELECCIONADO
                          } else {
                            if(locationState.points.isNotEmpty) {
                              final result = await locationNotifier.stopTrackingAndSaveGpx(context: context, ref: ref, cancel: false);

                              if (context.mounted && result.cancel!) {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    title: const Column(
                                      children: [
                                        Icon(Icons.cloud_off, color: Colors.orange),
                                        SizedBox(width: 10),
                                        Text('Sin conexión'),
                                      ],
                                    ),
                                    content: const Text(
                                      '🔌 Track guardado offline (sin conexión).\nRevisa el menu lateral cuando tengas conexión.',
                                      textAlign: TextAlign.center,
                                    ),
                                    actionsAlignment: MainAxisAlignment.center,
                                    actions: [
                                      SizedBox(
                                        width: 160,
                                        height: 50,
                                        child: TextButton(
                                          onPressed: () async {
                                            await ref.read(pendingTracksProvider.notifier).loadTracks();
                                            if(context.mounted) {
                                              Navigator.of(context).pop();
                                              GoRouter.of(context).go('/');
                                            }
                                          }, 
                                          style: TextButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          child: const Text(
                                            'Aceptar',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              } else if (context.mounted && !result.cancel!) {
                                context.pushNamed(
                                  TrackPreviewScreen.name,
                                  extra: {
                                    'trackFile': result.gpxFile,
                                    'points': result.correctedPoints,
                                  },
                                );
                              } 
                            } else {
                              if (context.mounted) {
                                
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('¿Cancelar grabacion del track?'),
                                    content: const Text('No se ha registrado ni un punto.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('No'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          await locationNotifier.stopTrackingAndSaveGpx(context: context, ref: ref, cancel: true);
                                          // ignore: use_build_context_synchronously
                                          Navigator.pop(context, true);
                                        } ,
                                        child: const Text('Sí, cancelar'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {

                                  // 🔁 REINICIA el estado
                                  ref.read(locationProvider.notifier).resetState();
                                  
                                  if (context.mounted) Navigator.pop(context);
                                }




                              }
                            }
                            
                          }
                        },
                  child: Icon(locationState.isTracking ? Icons.stop : Icons.play_arrow),
                ),
              ],
            ),
          ],
        ),
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

  double _calculateBearing(LatLng start, LatLng end) {
    final startLat = _degToRad(start.latitude);
    final startLng = _degToRad(start.longitude);
    final endLat = _degToRad(end.latitude);
    final endLng = _degToRad(end.longitude);

    final dLng = endLng - startLng;
    final y = sin(dLng) * cos(endLat);
    final x = cos(startLat) * sin(endLat) - sin(startLat) * cos(endLat) * cos(dLng);
    final bearing = atan2(y, x);
    return (_radToDeg(bearing) + 360) % 360;
  }

  double calculateCurrentSpeed(LocationState state) {
    if (state.points.length < 2) return 0;

    final last = state.points.last;
    final previous = state.points[state.points.length - 2];

    final seconds = last.timestamp.difference(previous.timestamp).inSeconds;
    if (seconds == 0) return 0;

    final distanceMeters = _calculateDistance(last, previous);
    final speedMs = distanceMeters / seconds;

    final speedKmh = speedMs * 3.6; // m/s → km/h
    return speedKmh;
  }


  double _degToRad(double deg) => deg * pi / 180;
  double _radToDeg(double rad) => rad * 180 / pi;


}



