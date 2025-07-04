

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:ladamadelcanchoapp/domain/entities/location_point.dart';
import 'package:ladamadelcanchoapp/infraestructure/models/response_calculates.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fl_chart/fl_chart.dart';

double calculateDistanceMeters(
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


Future<void> saveGpxToPublicDocuments(File file) async {
  final downloadsDir = Directory('/storage/emulated/0/Download/GPX/tracks');

  if (!(await downloadsDir.exists())) {
    await downloadsDir.create(recursive: true);
  }

  final publicFile = File('${downloadsDir.path}/${file.uri.pathSegments.last}');
  await file.copy(publicFile.path);
}

Future<File> saveGpxFile(StringBuffer buffer, String name) async {
  // ✅ Guardamos el archivo GPX
  final gpxString = buffer.toString();
  final directory = await getApplicationDocumentsDirectory();
  final fileName = "$name.gpx";
  final file = File("${directory.path}/$fileName");
  await file.writeAsString(gpxString);

  return file;
}


ResponseCalculates calculateDisAndEle(List<LocationPoint> points) {

  double totalDistanceMeters = 0;
  double totalElevationGain = 0;

  for (int i = 1; i < points.length; i++) {
    final prev = points[i - 1];
    final curr = points[i];
    final distance = calculateDistanceMeters(
      prev.latitude, prev.longitude,
      curr.latitude, curr.longitude,
    );
    totalDistanceMeters += distance;
    final elevationDiff = curr.elevation - prev.elevation;
    if (elevationDiff > 0) totalElevationGain += elevationDiff;
  }

  return ResponseCalculates(totalDistanceMeters: totalDistanceMeters, totalElevationGain: totalElevationGain);


}


Future<void> saveSnapshotToPrefs(Map<String, dynamic> snapshot) async {
  final prefs = await SharedPreferences.getInstance();

  // Convertimos el snapshot a JSON string
  final jsonString = jsonEncode(snapshot);

  // Guardamos en una lista (acumulativa) para soportar múltiples tracks offline
  final currentList = prefs.getStringList('offline_snapshots') ?? [];
  currentList.add(jsonString);

  await prefs.setStringList('offline_snapshots', currentList);

}


Future<List<Map<String, dynamic>>> loadOfflineSnapshots() async {
  final prefs = await SharedPreferences.getInstance();
  final storedList = prefs.getStringList('offline_snapshots') ?? [];

  return storedList.map((json) => jsonDecode(json) as Map<String, dynamic>).toList();
}


// Método para construir los datos del gráfico

List<FlSpot> buildElevationProfile(List<LocationPoint> points, double totalDistanceKm) {
  if (points.isEmpty) return [];

  final totalDistanceMeters = totalDistanceKm * 1000;
  final int pointCount = points.length;
  double accumulatedDistance = 0;
  List<FlSpot> spots = [];

  for (int i = 0; i < pointCount; i++) {
    if (i > 0) {
      accumulatedDistance = totalDistanceMeters * (i / (pointCount - 1));
    }
    spots.add(FlSpot(accumulatedDistance, points[i].elevation));
  }

  return spots;
}

double getDistanceMeters(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371000; // en metros

  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);

  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
      sin(dLon / 2) * sin(dLon / 2);

  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadius * c;
}

double _toRadians(double degree) => degree * pi / 180;

/*
List<FlSpot> buildElevationProfile(List<LocationPoint> points) {
  final List<FlSpot> spots = [];
  double accumulatedDistance = 0;

  for (int i = 0; i < points.length; i++) {
    if (i > 0) {
      accumulatedDistance += getDistanceMeters(
        points[i - 1].latitude,
        points[i - 1].longitude,
        points[i].latitude,
        points[i].longitude,
      );
    }

    // x: distancia acumulada en metros
    // y: elevación
    spots.add(FlSpot(accumulatedDistance, points[i].elevation));
  }

  return spots;
}
*/



// Calcula distancia entre dos coordenadas (en metros)

double calculateDistance(LocationPoint p1, LocationPoint p2) {
  const double R = 6371000; // radio de la Tierra en metros
  final double dLat = (p2.latitude - p1.latitude) * (pi / 180);
  final double dLon = (p2.longitude - p1.longitude) * (pi / 180);

  final double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(p1.latitude * (pi / 180)) *
          cos(p2.latitude * (pi / 180)) *
          sin(dLon / 2) *
          sin(dLon / 2);
  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}
/*
double getDistanceMeters(double lat1, double lon1, double lat2, double lon2) {
  const double R = 6371000; // Radio de la Tierra en metros
  final double dLat = _degreesToRadians(lat2 - lat1);
  final double dLon = _degreesToRadians(lon2 - lon1);

  final double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_degreesToRadians(lat1)) *
          cos(_degreesToRadians(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);

  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}


double _degreesToRadians(double degrees) {
  return degrees * pi / 180;
}
*/