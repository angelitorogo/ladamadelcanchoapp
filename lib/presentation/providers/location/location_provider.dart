import 'dart:async';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/domain/entities/location_point.dart';
import 'package:ladamadelcanchoapp/infraestructure/datasources/elevation_datasource_impl.dart';
import 'package:ladamadelcanchoapp/infraestructure/datasources/location_datasource_impl.dart';
import 'package:ladamadelcanchoapp/infraestructure/models/gpx_result.dart';
import 'package:ladamadelcanchoapp/infraestructure/repositories/elevation_repository_impl.dart';
import 'package:ladamadelcanchoapp/infraestructure/repositories/location_repository_impl.dart';
import 'package:ladamadelcanchoapp/infraestructure/utils/utils_track.dart';
import 'package:ladamadelcanchoapp/infraestructure/utils/create_buffer_gpx.dart';
import 'package:ladamadelcanchoapp/presentation/extra/check_connectivity.dart';
import 'package:ladamadelcanchoapp/presentation/providers/auth/auth_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'location_repository_provider.dart';



class LocationState {
  final bool isTracking;
  final bool isPaused;
  final double distance;
  final double elevationGain;
  final List<LocationPoint> points;
  final List<LocationPoint> discardedPoints;
  final TrackingMode mode; // 🆕 Estado actual del modo

  LocationState({
    this.distance = 0,
    this.elevationGain = 0,
    this.isTracking = false,
    this.isPaused = false,
    this.points = const [],
    this.discardedPoints = const [],
    this.mode = TrackingMode.walking, // 🆕 Modo por defecto
  });

  LocationState copyWith({
    bool? isTracking,
    bool? isPaused,
    double? distance,
    double? elevationGain,
    List<LocationPoint>? points,
    List<LocationPoint>? discardedPoints,
    TrackingMode? mode, // 🆕 Añadido
  }) {
    return LocationState(
      isTracking: isTracking ?? this.isTracking,
      isPaused: isPaused ?? this.isPaused,
      distance: distance ?? this.distance,
      elevationGain: elevationGain ?? this.elevationGain,
      points: points ?? this.points,
      discardedPoints: discardedPoints ?? this.discardedPoints,
      mode: mode ?? this.mode, // 🆕
    );
  }

}


class LocationNotifier extends StateNotifier<LocationState> {
  final LocationRepositoryImpl locationRepository;
  final AuthState authState;
  //StreamSubscription<LocationPoint>? _locationSubscription;
  StreamSubscription<dynamic>? _locationSubscription; // 👈 CAMBIADO
  

  LocationNotifier(this.locationRepository, this.authState) : super(LocationState());

  List<LatLng> get polylinePoints =>
      state.points.map((p) => LatLng(p.latitude, p.longitude)).toList();

  void setTrackingMode(TrackingMode newMode) {
    state = state.copyWith(mode: newMode);
    final datasource = locationRepository.datasource;

    if (datasource is LocationDatasourceImpl) {
      datasource.setTrackingMode(newMode); // 🆕 Informa al datasource
    }
  }
  
  void startTracking({required TrackingMode mode}) async {

    final datasource = locationRepository.datasource as LocationDatasourceImpl;
    final location = datasource.location;
    LocationPoint? lastCorrectedPoint;

    // 🆕 Establecer el modo activo antes de iniciar
    datasource.setTrackingMode(state.mode);


    await location.changeNotificationOptions(
      title: 'Grabando ruta...',
      subtitle: 'La Dama del Cancho está registrando tu recorrido.',
      description: 'Tu posición se guarda en segundo plano.',
      onTapBringToFront: true,
      iconName: 'ic_flutter',
    );

    await location.enableBackgroundMode(enable: true);

    state = state.copyWith(
      isTracking: true,
      isPaused: false,
      points: [],
      distance: 0,
      elevationGain: 0,
      discardedPoints: [],
    );

    _locationSubscription = locationRepository.getLocationStream().listen((point) async {
      if (state.isPaused) return;

      // 🟡 Corregimos la altitud ANTES de usar el punto
      final elevationRepository = ElevationRepositoryImpl(ElevationDatasourceImpl());
      final response = await elevationRepository.getElevationForPoint(point);

      if (!response.corrected) {
        if (lastCorrectedPoint != null) {
          // Copiamos la altitud del último punto corregido
          point = LocationPoint(
            latitude: point.latitude,
            longitude: point.longitude,
            elevation: lastCorrectedPoint!.elevation,
            timestamp: point.timestamp,
          );
        } else {
          // 🟠 Usamos el punto original como fallback si no hay ninguno corregido aún
          lastCorrectedPoint = point;
        }
      } else {
        lastCorrectedPoint = response.point;
        point = response.point;
      }   
      // 🟡 quitar este bloque para que no corrija punto a punto

      final updatedPoints = [...state.points, point];
      double addedDistance = 0;
      double addedElevation = 0;

      if (state.points.isNotEmpty) {
        final last = state.points.last;
        addedDistance = calculateDistanceMeters(
          last.latitude, last.longitude,
          point.latitude, point.longitude,
        );
        final elevationDiff = point.elevation - last.elevation;
        if (elevationDiff > 0) addedElevation = elevationDiff;
      }

      state = state.copyWith(
        points: updatedPoints,
        distance: state.distance + addedDistance,
        elevationGain: state.elevationGain + addedElevation,
      );
    });

  }


  void pauseTracking() {
    state = state.copyWith(isPaused: true);
  }

  void resumeTracking() {
    state = state.copyWith(isPaused: false);
  }

  

  Future<GpxResult> stopTrackingAndSaveGpx({required BuildContext context, required WidgetRef ref, required bool cancel, String? overrideName, String? overrideDescription, List<LocationPoint>? points}) async {

    state = state.copyWith(isTracking: false);

    if (points != null && points.isNotEmpty) {
      // ✅ Hay puntos recibidos
      state = state.copyWith(points: points);
    }

    //comenzamos a escuchar los puntos que nos envia el datasource
    await _locationSubscription?.cancel();
    await (locationRepository.datasource as LocationDatasourceImpl)
        .location.enableBackgroundMode(enable: false);

    // si se ha detenido la grabacion sin tener un solo punto detectado
    if( cancel ) {
      resetState();
      return GpxResult(cancel: true);
    }    

    //Corregir de nuevo los puntos al terminar
    final elevationRepository = ElevationRepositoryImpl(ElevationDatasourceImpl());
    List<LocationPoint> correctedPoints;
    try {

      // Aqui falla algo, no correige los puntos
      correctedPoints = await elevationRepository.getCorrectedElevations(state.points);
    } catch (e) {
      // 🚨 Si falla la corrección, usamos los puntos originales
      correctedPoints = state.points;
    }

    // ✅ Calculamos distancia y desnivel
    final result = calculateDisAndEle(state.points);
    double totalDistanceMeters = result.totalDistanceMeters;
    double totalElevationGain = result.totalElevationGain;

    // ✅ Guardamos el estado original antes de corrección
    state = state.copyWith(points: correctedPoints, distance: totalDistanceMeters, elevationGain: totalElevationGain);


    // si no hay conexion, hay que hacer qalgo para guardar este estado en sharedpreferences y recuperarlo de alguna manera desde el 
    // side menu por ejemplo, con algun chivato.
    final hasInternet = await checkInternetAccess();
    if(!hasInternet) {

      final snapshot = {
        'userId': ref.watch(authProvider).user!.id,
        'timestamp': DateTime.now().toIso8601String(),
        'state': {
          'isTracking': state.isTracking,
          'isPaused': state.isPaused,
          'distance': state.distance,
          'elevationGain': state.elevationGain,
          'points': state.points.map((p) => p.toMap()).toList(),
          'discardedPoints': state.discardedPoints.map((p) => p.toMap()).toList(),
          'mode': state.mode.name,
        }
      };

      await saveSnapshotToPrefs(snapshot);
      //print('📦 Guardado snapshot offline!!! ');

      resetState();

      

      return GpxResult(cancel: true);
      
    }
    

    

    


    // ✅ Determinamos nombre y modo
    final name = overrideName ?? 'track_${DateTime.now().millisecondsSinceEpoch}';
    final mode = switch (state.mode) {
      TrackingMode.walking => 'Senderismo',
      TrackingMode.cycling => 'Ciclismo',
      TrackingMode.driving => 'Conduciendo',
    };
    final description = overrideDescription ?? mode;
    final author = authState.user!.fullname;
    final firstPointTime = correctedPoints.isNotEmpty
        ? correctedPoints.first.timestamp.toUtc().toIso8601String()
        : '';


    //creamos el archivos GPX
    final buffer = await createBufferGpx(name: name, author: author, firstPointTime: firstPointTime, description: description, mode: mode, points: correctedPoints);

    //salvamos en directorio privado de la app
    final file = await saveGpxFile(buffer, name);

    //Copia a carpeta pública también
    await saveGpxToPublicDocuments(file);

    return GpxResult(gpxFile: file, correctedPoints: correctedPoints, cancel: false);
  }

  void resetState() {
    _locationSubscription?.cancel(); // Por si acaso
    // 🧼 Cerramos el controlador de descartados tambien por si acaso
    final datasource = locationRepository.datasource;
    if (datasource is LocationDatasourceImpl) {
      datasource.dispose();
    }
    state = LocationState(); // Estado por defecto
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    // 🧼 Cerramos el controlador de descartados
    final datasource = locationRepository.datasource;
    if (datasource is LocationDatasourceImpl) {
      datasource.dispose();
    }
    super.dispose();
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  final locationRepository = ref.watch(locationRepositoryProvider);
  final authState = ref.watch(authProvider);
  return LocationNotifier(locationRepository, authState);
});
