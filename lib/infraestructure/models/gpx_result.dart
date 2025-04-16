import 'dart:io';

import 'package:ladamadelcanchoapp/domain/entities/location_point.dart';

class GpxResult {
  final File? gpxFile;
  final List<LocationPoint>? correctedPoints;
  final bool? cancel;

  GpxResult({this.gpxFile, this.correctedPoints, this.cancel});
}