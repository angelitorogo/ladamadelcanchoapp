



import 'package:ladamadelcanchoapp/domain/entities/location_point.dart';

Future<StringBuffer> createBufferGpx({
  required String name, 
  required String author, 
  required String firstPointTime, 
  required String description,
  required String mode,
  required List<LocationPoint> points
 }) async {


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

  for (final p in points) {
    buffer.writeln('      <trkpt lat="${p.latitude}" lon="${p.longitude}">');
    buffer.writeln('        <ele>${p.elevation}</ele>');
    buffer.writeln('        <time>${p.timestamp.toUtc().toIso8601String()}</time>');
    buffer.writeln('      </trkpt>');
  }

  buffer.writeln('    </trkseg>');
  buffer.writeln('  </trk>');
  buffer.writeln('</gpx>');


  return buffer;

}