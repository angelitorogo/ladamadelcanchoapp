
import 'dart:io';

import 'package:ladamadelcanchoapp/domain/entities/location_point.dart';
import 'package:xml/xml.dart';

Future<List<LocationPoint>> parseGpxFileToPoints(File gpxFile) async {
  final String gpxContent = await gpxFile.readAsString();
  final XmlDocument document = XmlDocument.parse(gpxContent);

  final List<LocationPoint> points = [];

  final trkpts = document.findAllElements('trkpt');
  for (final trkpt in trkpts) {
    final lat = double.parse(trkpt.getAttribute('lat')!);
    final lon = double.parse(trkpt.getAttribute('lon')!);
    final ele = double.tryParse(
          trkpt.getElement('ele')?.innerText ?? '',
        ) ??
        0.0;
    final timeStr = trkpt.getElement('time')?.innerText;
    final timestamp = timeStr != null
        ? DateTime.parse(timeStr)
        : DateTime.now();

    points.add(LocationPoint(
      latitude: lat,
      longitude: lon,
      elevation: ele,
      timestamp: timestamp,
    ));
  }

  return points;
}