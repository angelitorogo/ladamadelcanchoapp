import 'dart:io';

import 'package:ladamadelcanchoapp/domain/entities/location_point.dart';

class GpxResult {
  final File gpxFile;
  final List<LocationPoint> correctedPoints;

  GpxResult({required this.gpxFile, required this.correctedPoints});
}