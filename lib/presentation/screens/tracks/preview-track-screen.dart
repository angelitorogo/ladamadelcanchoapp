

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:ladamadelcanchoapp/domain/entities/location_point.dart';
import 'package:ladamadelcanchoapp/infraestructure/datasources/location_datasource_impl.dart';
import 'package:ladamadelcanchoapp/presentation/extra/check_connectivity.dart';
import 'package:ladamadelcanchoapp/presentation/providers/location/location_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/pendings/pending_tracks_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/track/track_list_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/track/track_provider.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';


class TrackPreviewScreen extends ConsumerStatefulWidget {
  final File trackFile;
  final List<LocationPoint> points;
  final int? index;

  const TrackPreviewScreen({
    super.key,
    required this.trackFile,
    required this.points,
    required this.index
  });

  static const name = 'track-preview-screen';

  @override
  ConsumerState<TrackPreviewScreen> createState() => _TrackPreviewScreenState();
}

class _TrackPreviewScreenState extends ConsumerState<TrackPreviewScreen> {
  late final TextEditingController _nameController;
  final TextEditingController descriptionController = TextEditingController();
  late final List<LatLng> polylinePoints;
  late final LatLngBounds? bounds;

  GoogleMapController? mapController;

  double distanceKm = 0;
  Duration duration = Duration.zero;
  String startTimeStr = '';
  String endTimeStr = '';
  double elevationGain = 0;
  double elevationLoss = 0;
  List<File> selectedImages = [];
  double maxElevation = 0;
  double minElevation = 0;


  @override
  void initState() {
    super.initState();
    final rawName = widget.trackFile.uri.pathSegments.last;
    final defaultName = rawName.replaceAll('.gpx', '');
    _nameController = TextEditingController(text: defaultName);
    polylinePoints = widget.points.map((p) => LatLng(p.latitude, p.longitude)).toList();
    bounds = _calculateBounds(polylinePoints);
    _calculateTrackStats();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();

    if (picked.isNotEmpty) {
      setState(() {
        selectedImages = picked.map((xfile) => File(xfile.path)).toList();
      });
    }
  }

  LatLngBounds? _calculateBounds(List<LatLng> points) {

    if (points.isNotEmpty) {
      final latitudes = points.map((p) => p.latitude);
      final longitudes = points.map((p) => p.longitude);

      final southwest = LatLng(latitudes.reduce(min), longitudes.reduce(min));
      final northeast = LatLng(latitudes.reduce(max), longitudes.reduce(max));

      return LatLngBounds(southwest: southwest, northeast: northeast);
    
    }

    return null;

    
  }

  void _calculateTrackStats() {
    if (widget.points.isEmpty) return;

    double total = 0;
    double gain = 0;
    double loss = 0;

    maxElevation = widget.points.first.elevation;
    minElevation = widget.points.first.elevation;

    for (var i = 0; i < widget.points.length - 1; i++) {
      final currElevation = widget.points[i].elevation;
      final nextElevation = widget.points[i + 1].elevation;

      total += _distanceBetween(
        LatLng(widget.points[i].latitude, widget.points[i].longitude),
        LatLng(widget.points[i + 1].latitude, widget.points[i + 1].longitude),
      );

      final delta = nextElevation - currElevation;
      if (delta > 0) gain += delta;
      if (delta < 0) loss += delta.abs();

      if (currElevation > maxElevation) maxElevation = currElevation;
      if (currElevation < minElevation) minElevation = currElevation;
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

  Widget _buildDataCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20),
      child: Center(child: Text(text)),
    );
  }

  Future<File> captureMap() async {
    if (mapController == null || bounds == null) {
      throw Exception('Mapa no disponible para captura');
    }

    // 1. Centra el mapa en todos los puntos
    await mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds!, 50),
    );

    // 2. Espera un poco para que se renderice correctamente
    await Future.delayed(const Duration(milliseconds: 500));

    // 3. Captura del mapa
    final Uint8List? bytes = await mapController?.takeSnapshot();

    final downloadsDir = Directory('/storage/emulated/0/Download/GPX/captures');
    if (!(await downloadsDir.exists())) {
      await downloadsDir.create(recursive: true);
    }

    final imagePath = '${downloadsDir.path}/map_snapshot_${DateTime.now().millisecondsSinceEpoch}.png';
    final imageFile = File(imagePath);

    await imageFile.writeAsBytes(bytes!);
    return imageFile;
  }


  @override
  void dispose() {
    _nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(trackUploadProvider);
    final uploader = ref.read(trackUploadProvider.notifier);
    final locationState = ref.watch(locationProvider);

    final modeState = ref.watch(locationProvider).mode;
    String mode;

    switch (modeState) {
      case TrackingMode.walking:
        mode = 'Senderismo';
        break;
      case TrackingMode.cycling:
        mode = 'Ciclismo';
        break;
      case TrackingMode.driving:
        mode = 'Conduciendo';
        break;
      
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Vista previa del track')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 📝 Campo editable para nombre
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text("Título", style: Theme.of(context).textTheme.titleMedium),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 🗺 Mapa con padding y tamaño fijo
            SizedBox(
              height: 400,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
                child: GoogleMap(
                  mapType: MapType.satellite,
                  initialCameraPosition: CameraPosition(
                    target: polylinePoints.first,
                    zoom: 16,
                  ),
                  myLocationEnabled: false,  //no se muestra mi ubicacion actual en el preview
                  

                  
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
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                    ),
                    Marker(
                      markerId: const MarkerId('end'),
                      position: polylinePoints.last,
                      infoWindow: const InfoWindow(title: 'Fin'),
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                    ),
                  },
                  zoomGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  rotateGesturesEnabled: true,
                  tiltGesturesEnabled: true,

                  onMapCreated: (controller) {
                    mapController = controller;
                    Future.delayed(const Duration(milliseconds: 300), () async {
                      await controller.animateCamera(
                        CameraUpdate.newLatLngBounds(bounds!, 50),
                      );

                    });
                  },

                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer(),
                    ),
                  },

                ),
              ),
            ),

            // 📊 Resumen en tabla con bordes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Detalles", style: Theme.of(context).textTheme.titleMedium),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal:10, vertical: 10),
                    child: Table(
                      border: TableBorder.all(color: Colors.white),
                      columnWidths: const {
                        0: FlexColumnWidth(1),
                        1: FlexColumnWidth(1),
                      },
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      children: [
                        TableRow(children: [
                          _buildDataCell('📏 ${distanceKm.toStringAsFixed(2)} km'),
                          _buildDataCell('⏱ ${_formatDuration(duration)}'),
                        ]),
                        TableRow(children: [
                          _buildDataCell('🕒 $startTimeStr'),
                          _buildDataCell('🕓 $endTimeStr'),
                        ]),
                        TableRow(children: [
                          _buildDataCell('⛰ +${elevationGain.toStringAsFixed(0)} m'),
                          _buildDataCell('⬇️ -${elevationLoss.toStringAsFixed(0)} m'),
                        ]),
                        TableRow(children: [
                          _buildDataCell('🔼 Máx: ${maxElevation.toStringAsFixed(0)} m'),
                          _buildDataCell('🔽 Mín: ${minElevation.toStringAsFixed(0)} m'),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10), // 👈 mismo padding
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Tipo de track', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8), // 👈 añadido para separación uniforme
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(mode),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Descripción", style: Theme.of(context).textTheme.titleMedium),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical:10),
                    child: TextFormField(
                      controller: descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Escribe aquí una descripción opcional...',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white10,
                      ),
                    ),
                  ),
                ],
              ),
            ),


            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Imágenes adjuntas", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.photo_library),
                        label: const Text("Seleccionar imágenes"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 80,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: selectedImages.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              selectedImages[index],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

          ],
        ),
      ),

      // ✅ Botones con estado de carga
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              // ❌ CANCELAR
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.cancel),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('¿Cancelar subida del track?'),
                        content: const Text('Si existe el archivo .gpx, será eliminado del dispositivo.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('No'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Sí, cancelar'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true)  {
                      final path = '/storage/emulated/0/Download/GPX/tracks/${widget.trackFile.uri.pathSegments.last}';
                      final file = File(path);
                      if (await file.exists()) await file.delete();

                      //eliminar track pending del prefs
                      if(widget.index != null) {
                        await ref.read(pendingTracksProvider.notifier).removeTrack(widget.index!);
                      }
                      

                      // 🔁 REINICIA el estado
                      ref.read(locationProvider.notifier).resetState();
                      
                      if (context.mounted) Navigator.of(context).pop('cancelled');
                    }
                  },
                  label: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 10),

              // ✅ GUARDAR
              Expanded(
                child: ElevatedButton.icon(
                  icon: uploadState.status == TrackUploadStatus.loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.cloud_upload),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: uploadState.status == TrackUploadStatus.loading
                      ? null
                      : () async {

                          //comprobar si hay o no internet
                          final hasInternet = await checkAndWarnIfNoInternet(context);

                          if(hasInternet) {

                            final name = _nameController.text.trim();
                            final description = descriptionController.text;
                            final file = widget.trackFile;


                            captureMap();
                            Map<String, dynamic>? response;

                            //print('✅ Images1: $selectedImages');

                            final File fileCaptureMap = await captureMap();


                            
                            // ignore: use_build_context_synchronously
                            response = await uploader.uploadTrack(context, name, file, ref, description, mode, locationState.distance.toString(), locationState.elevationGain.toString(), fileCaptureMap, points: widget.points, images: selectedImages);
                            

                            if (response != null && context.mounted) {

                              // 🔁 Reinicia el estado de ubicación
                              ref.read(locationProvider.notifier).resetState();

                              // 🔁 Recarga el listado de tracks
                              ref.read(trackListProvider.notifier).loadTracks();

                              await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.green),
                                      SizedBox(width: 8),
                                      Text('Track subido'),
                                    ],
                                  ),
                                  content: const Text('El track se ha guardado correctamente en el servidor.'),
                                  actions: [
                                    ElevatedButton(
                                      onPressed: () async {

                                        //eliminar track pending del prefs
                                        if(widget.index != null) {
                                          await ref.read(pendingTracksProvider.notifier).removeTrack(widget.index!);
                                        }

                                        if(context.mounted) {
                                          Navigator.of(context).pop('uploaded');
                                          GoRouter.of(context).go('/');
                                        }

                                      },
                                      child: const Text('Aceptar'),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              if (context.mounted) {
                                selectedImages = [];
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('❌ ${ref.watch(trackUploadProvider).message}'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }

                          }

                          
                        },
                  label: Text(
                    uploadState.status == TrackUploadStatus.loading
                        ? 'Subiendo...'
                        : 'Guardar',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    
      //Debug
      /*
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDebugDialog(context, ref),
        child: const Icon(Icons.bug_report),
      ),
      */
    
    );
  }

  String _formatDuration(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes % 60;
    return h > 0 ? '${h}h ${m}min' : '${m}min';
  }



}



