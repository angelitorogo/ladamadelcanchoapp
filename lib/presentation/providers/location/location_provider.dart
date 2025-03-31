import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpx/gpx.dart';
import 'package:ladamadelcanchoapp/domain/entities/location_point.dart';
import 'package:ladamadelcanchoapp/infraestructure/datasources/location_datasource_impl.dart';
import 'package:ladamadelcanchoapp/infraestructure/repositories/location_repository_impl.dart';
import 'package:ladamadelcanchoapp/presentation/providers/auth/auth_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'location_repository_provider.dart';

class LocationState {
  final bool isTracking;
  final List<LocationPoint> points;

  LocationState({this.isTracking = false, this.points = const []});

  LocationState copyWith({bool? isTracking, List<LocationPoint>? points}) {
    return LocationState(
      isTracking: isTracking ?? this.isTracking,
      points: points ?? this.points,
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

  
  void startTracking() async {
     // ✅ Cast seguro para acceder al objeto `Location`
    final location = (locationRepository.datasource as LocationDatasourceImpl).location;

    // ✅ CONFIGURA LA NOTIFICACIÓN PERSISTENTE
    await location.changeNotificationOptions(
      title: 'Grabando ruta...',
      subtitle: 'La Dama del Cancho está registrando tu recorrido.',
      description: 'Tu posición se guarda en segundo plano.',
      onTapBringToFront: true,
      iconName: 'ic_flutter', // <<<<<<<<<<<<<<
    );

    // ✅ ACTIVAR MODO BACKGROUND
    await location.enableBackgroundMode(enable: true);


    state = state.copyWith(isTracking: true, points: []);
    _locationSubscription =
        locationRepository.getLocationStream().listen((point) {
      state = state.copyWith(points: [...state.points, point]);
    });
  }

  Future<File> stopTrackingAndSaveGpx({String? overrideName}) async {
    await _locationSubscription?.cancel();

    await (locationRepository.datasource as LocationDatasourceImpl).location.enableBackgroundMode(enable: false);


    final gpx = Gpx();
    gpx.creator = "La Dama del Cancho App";
    final track = Trk(name: "Track grabado");
    track.trksegs.add(
      Trkseg(
        trkpts: state.points.map((p) {
          final wpt = Wpt(lat: p.latitude, lon: p.longitude);
          wpt.ele = p.elevation;
          wpt.time = p.timestamp;
          return wpt;
        }).toList(),
      ),
    );

    gpx.trks.add(track);
    //final gpxString = GpxWriter().asString(gpx, pretty: true);

    final name = overrideName ?? 'track_${DateTime.now().millisecondsSinceEpoch}'; // ✅ usa nombre si se proporciona
    String author = authState.user!.fullname;
    final firstPointTime = state.points.first.timestamp.toUtc().toIso8601String();

    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<gpx version="1.1" creator="La Dama del Cancho App" '
        'xmlns="http://www.topografix.com/GPX/1/1" '
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
        'xsi:schemaLocation="http://www.topografix.com/GPX/1/1 '
        'http://www.topografix.com/GPX/1/1/gpx.xsd">');

    buffer.writeln('  <metadata>');
    buffer.writeln('    <name>$name</name>');
    buffer.writeln('    <author>');
    buffer.writeln('      <name>$author</name>');
    buffer.writeln('    </author>');
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
    buffer.writeln('    <desc>$name</desc>');
    buffer.writeln('    <trkseg>');

    for (final p in state.points) {
      buffer.writeln('      <trkpt lat="${p.latitude}" lon="${p.longitude}">');
      buffer.writeln('        <ele>${p.elevation}</ele>');
      buffer.writeln('        <time>${p.timestamp.toUtc().toIso8601String()}</time>');
      buffer.writeln('      </trkpt>');
    }

    buffer.writeln('    </trkseg>');
    buffer.writeln('  </trk>');
    buffer.writeln('</gpx>');

    final gpxString = buffer.toString();


    final directory = await getApplicationDocumentsDirectory();
    final fileName = "$name.gpx";
    final file = File("${directory.path}/$fileName");
    await file.writeAsString(gpxString);

    // Guardamos archivo GPX
    await saveGpxToPublicDocuments(file);
    //await saveGpxToAppDirectory(file);

    state = state.copyWith(isTracking: false/*, points: []*/);

    return file;
  }
  


  Future<void> saveGpxToPublicDocuments(File file) async {
    final downloadsDir = Directory('/storage/emulated/0/Download/GPX');

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

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  final locationRepository = ref.watch(locationRepositoryProvider);
  final authState = ref.watch(authProvider);
  return LocationNotifier(locationRepository, authState);
});
