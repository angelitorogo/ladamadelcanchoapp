import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/domain/entities/location_point.dart';
import 'package:ladamadelcanchoapp/infraestructure/datasources/elevation_datasource_impl.dart';
import 'package:ladamadelcanchoapp/infraestructure/datasources/location_datasource_impl.dart';
import 'package:ladamadelcanchoapp/infraestructure/models/gpx_result.dart';
import 'package:ladamadelcanchoapp/infraestructure/repositories/elevation_repository_impl.dart';
import 'package:ladamadelcanchoapp/infraestructure/repositories/location_repository_impl.dart';
import 'package:ladamadelcanchoapp/presentation/providers/auth/auth_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'location_repository_provider.dart';
import 'dart:math';



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
        // Si aún no tenemos uno corregido, descartamos el punto
        return;
      }
    } else {
      lastCorrectedPoint = response.point;
      point = response.point;
    }
    
    // quitar este bloque para que no corrija punto a punto

    final updatedPoints = [...state.points, point];
    double addedDistance = 0;
    double addedElevation = 0;

    if (state.points.isNotEmpty) {
      final last = state.points.last;
      addedDistance = _calculateDistanceMeters(
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

  // 👇 Suscripción a puntos descartados
  datasource.discardedPointsStream.listen((discardedPoint) {
    state = state.copyWith(
      discardedPoints: [...state.discardedPoints, discardedPoint],
    );
  });
}


  void pauseTracking() {
    state = state.copyWith(isPaused: true);
  }

  void resumeTracking() {
    state = state.copyWith(isPaused: false);
  }

  double _calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371000; // radio de la Tierra en metros
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = 
      (sin(dLat / 2) * sin(dLat / 2)) +
      cos(_degToRad(lat1)) * cos(_degToRad(lat2)) *
      (sin(dLon / 2) * sin(dLon / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);

  Future<GpxResult> stopTrackingAndSaveGpx({String? overrideName, String? overrideDescription}) async {
    await _locationSubscription?.cancel();
    await (locationRepository.datasource as LocationDatasourceImpl)
        .location.enableBackgroundMode(enable: false);

    // ✅ Calculamos distancia y desnivel originales
    double totalDistanceMeters = 0;
    double totalElevationGain = 0;

    for (int i = 1; i < state.points.length; i++) {
      final prev = state.points[i - 1];
      final curr = state.points[i];
      final distance = _calculateDistanceMeters(
        prev.latitude, prev.longitude,
        curr.latitude, curr.longitude,
      );
      totalDistanceMeters += distance;
      final elevationDiff = curr.elevation - prev.elevation;
      if (elevationDiff > 0) totalElevationGain += elevationDiff;
    }

    // ✅ Guardamos el estado original antes de corrección
    state = state.copyWith(distance: totalDistanceMeters, elevationGain: totalElevationGain);

    // ✅ Corregimos elevaciones usando Open-Elevation
    final elevationRepository = ElevationRepositoryImpl(ElevationDatasourceImpl());
    List<LocationPoint> correctedPoints;

    //Si queremos corregir al terminar
    /*
    try {
      correctedPoints = await elevationRepository.getCorrectedElevations(state.points);
    } catch (e) {
      // 🚨 Si falla la corrección, usamos los puntos originales
      correctedPoints = state.points;
    }
    */
    correctedPoints = state.points;

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

    // ✅ Construimos GPX manualmente
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<gpx version="1.1" creator="La Dama del Cancho App" '
        'xmlns="http://www.topografix.com/GPX/1/1" '
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
        'xsi:schemaLocation="http://www.topografix.com/GPX/1/1 '
        'http://www.topografix.com/GPX/1/1/gpx.xsd">');

    buffer.writeln('  <metadata>');
    buffer.writeln('    <name>$name</name>');
    buffer.writeln('    <author><name>$author</name></author>');
    buffer.writeln('    <link href="https://ladamadelcancho.argomez.com/">');
    buffer.writeln('      <text>La Dama del Cancho</text>');
    buffer.writeln('    </link>');
    buffer.writeln('    <link href="https://ladamadelcancho.argomez.com/">');
    buffer.writeln('      <text>$name</text>');
    buffer.writeln('    </link>');
    buffer.writeln('    <time>$firstPointTime</time>');
    buffer.writeln('  </metadata>');

    buffer.writeln('  <trk>');
    buffer.writeln('    <name>$name</name>');
    buffer.writeln('    <cmt>$name</cmt>');
    buffer.writeln('    <desc>$description</desc>');
    buffer.writeln('    <type>$mode</type>');
    buffer.writeln('    <trkseg>');

    for (final p in correctedPoints) {
      buffer.writeln('      <trkpt lat="${p.latitude}" lon="${p.longitude}">');
      buffer.writeln('        <ele>${p.elevation}</ele>');
      buffer.writeln('        <time>${p.timestamp.toUtc().toIso8601String()}</time>');
      buffer.writeln('      </trkpt>');
    }

    buffer.writeln('    </trkseg>');
    buffer.writeln('  </trk>');
    buffer.writeln('</gpx>');

    // ✅ Guardamos el archivo GPX
    final gpxString = buffer.toString();
    final directory = await getApplicationDocumentsDirectory();
    final fileName = "$name.gpx";
    final file = File("${directory.path}/$fileName");
    await file.writeAsString(gpxString);

    // ✅ Copia a carpeta pública también
    await saveGpxToPublicDocuments(file);

    state = state.copyWith(isTracking: false, points: correctedPoints);

    return GpxResult(gpxFile: file, correctedPoints: correctedPoints);
  }

    


  Future<void> saveGpxToPublicDocuments(File file) async {
    final downloadsDir = Directory('/storage/emulated/0/Download/GPX/tracks');

    if (!(await downloadsDir.exists())) {
      await downloadsDir.create(recursive: true);
    }

    final publicFile = File('${downloadsDir.path}/${file.uri.pathSegments.last}');
    await file.copy(publicFile.path);
  }


  Future<void> saveGpxToAppDirectory(File file) async {
    final directory = await getExternalStorageDirectory();
    final gpxDir = Directory('${directory!.path}/GPX');
    
    if (!(await gpxDir.exists())) {
      await gpxDir.create(recursive: true);
    }

    final targetFile = File('${gpxDir.path}/${file.uri.pathSegments.last}');
    await file.copy(targetFile.path);
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
