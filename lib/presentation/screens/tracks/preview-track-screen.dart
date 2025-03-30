import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:ladamadelcanchoapp/domain/entities/location_point.dart';

class TrackPreviewScreen extends StatefulWidget {
  final File trackFile;
  final List<LocationPoint> points;

  const TrackPreviewScreen({
    super.key,
    required this.trackFile,
    required this.points,
  });

  static const name = 'track-preview-screen';

  @override
  State<TrackPreviewScreen> createState() => _TrackPreviewScreenState();
}

class _TrackPreviewScreenState extends State<TrackPreviewScreen> {
  late final TextEditingController _nameController;
  late final List<LatLng> polylinePoints;
  late final LatLngBounds bounds;

  GoogleMapController? mapController;

  double distanceKm = 0;
  Duration duration = Duration.zero;
  String startTimeStr = '';
  String endTimeStr = '';
  double elevationGain = 0;
  double elevationLoss = 0;

  @override
  void initState() {
    super.initState();
    final rawName = widget.trackFile.uri.pathSegments.last;
    final defaultName = rawName.replaceAll('.gpx', '');
    _nameController = TextEditingController(text: defaultName);
    polylinePoints = widget.points
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();
    bounds = _calculateBounds(polylinePoints);
    _calculateTrackStats();
  }

  LatLngBounds _calculateBounds(List<LatLng> points) {
    final latitudes = points.map((p) => p.latitude);
    final longitudes = points.map((p) => p.longitude);

    final southwest = LatLng(
      latitudes.reduce(min),
      longitudes.reduce(min),
    );
    final northeast = LatLng(
      latitudes.reduce(max),
      longitudes.reduce(max),
    );

    return LatLngBounds(southwest: southwest, northeast: northeast);
  }

  void _calculateTrackStats() {
    double total = 0;
    double gain = 0;
    double loss = 0;

    for (var i = 0; i < widget.points.length - 1; i++) {
      total += _distanceBetween(
        LatLng(widget.points[i].latitude, widget.points[i].longitude),
        LatLng(widget.points[i + 1].latitude, widget.points[i + 1].longitude),
      );

      final delta =
          widget.points[i + 1].elevation - widget.points[i].elevation;
      if (delta > 0) gain += delta;
      if (delta < 0) loss += delta.abs();
    }

    distanceKm = total;
    elevationGain = gain;
    elevationLoss = loss;

    final startTime = widget.points.first.timestamp.toLocal();
    final endTime = widget.points.last.timestamp.toLocal();
    duration = endTime.difference(startTime);
    startTimeStr = DateFormat.Hm().format(startTime);
    endTimeStr = DateFormat.Hm().format(endTime);
  }

  double _distanceBetween(LatLng a, LatLng b) {
    const earthRadius = 6371; // km
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLon = _deg2rad(b.longitude - a.longitude);

    final lat1 = _deg2rad(a.latitude);
    final lat2 = _deg2rad(b.latitude);

    final aCalc = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2);
    final c = 2 * atan2(sqrt(aCalc), sqrt(1 - aCalc));
    return earthRadius * c;
  }

  double _deg2rad(double deg) => deg * pi / 180;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vista previa')),
        body: const Center(child: Text('No hay puntos para mostrar')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Vista previa del Track')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 📝 Campo editable para nombre
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del track',
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            // 🗺 Mapa con padding y tamaño fijo
            SizedBox(
              height: 400,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GoogleMap(
                  onMapCreated: (controller) {
                    mapController = controller;
                    Future.delayed(const Duration(milliseconds: 300), () {
                      controller.animateCamera(
                        CameraUpdate.newLatLngBounds(bounds, 50),
                      );
                    });
                  },
                  initialCameraPosition: CameraPosition(
                    target: polylinePoints.first,
                    zoom: 15,
                  ),
                  polylines: {
                    Polyline(
                      polylineId: const PolylineId('preview_polyline'),
                      points: polylinePoints,
                      color: Colors.blue,
                      width: 5,
                    ),
                  },
                  markers: {
                    Marker(
                      markerId: const MarkerId('start'),
                      position: polylinePoints.first,
                      infoWindow: const InfoWindow(title: 'Inicio'),
                    ),
                  },
                ),
              ),
            ),

            // 📊 Resumen de datos
            Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
  child: Table(
    border: TableBorder.all(color: Colors.white),
    columnWidths: const {
      0: FlexColumnWidth(1),
      1: FlexColumnWidth(1),
    },
    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
    children: [
      TableRow(
        children: [
          _buildDataCell('📏 ${distanceKm.toStringAsFixed(2)} km'),
          _buildDataCell('⏱ ${_formatDuration(duration)}'),
        ],
      ),
      TableRow(
        children: [
          _buildDataCell('🕒 $startTimeStr'),
          _buildDataCell('🕓 $endTimeStr'),
        ],
      ),
      TableRow(
        children: [
          _buildDataCell('⛰ +${elevationGain.toStringAsFixed(0)} m'),
          _buildDataCell('⬇️ -${elevationLoss.toStringAsFixed(0)} m'),
        ],
      ),
    ],
  ),
),


          ],
        ),
      ),

      // ✅ Botones abajo
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.cancel),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('¿Cancelar y eliminar track?'),
                        content: const Text('El archivo .gpx será eliminado del dispositivo.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('No'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Sí, eliminar'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      try {
                        final fileName = widget.trackFile.uri.pathSegments.last;
                        final path = '/storage/emulated/0/Download/GPX/$fileName';

                        final file = File(path);
                        if (await file.exists()) {
                          await file.delete();
                          //print('✅ Track eliminado: $path');
                        } else {
                          //print('⚠️ Archivo no encontrado en: $path');
                        }

                        if (context.mounted) Navigator.pop(context);

                      } catch (e) {
                        //print('❌ Error al eliminar el archivo: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Error al eliminar el archivo')),
                          );
                        }
                      }
                    }
                  },


                  label: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_upload),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () {
                    final name = _nameController.text.trim();
                    print('Subir track con nombre: $name');
                  },
                  label: const Text('Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),

    );
  }

  String _formatDuration(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes % 60;
    return h > 0 ? '${h}h ${m}min' : '${m}min';
  }

  Widget _buildDataCell(String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20),
    child: Center(child: Text(text)),
  );
}

}
