
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:ladamadelcanchoapp/config/constants/environment.dart';
import 'package:ladamadelcanchoapp/domain/entities/location_point.dart';
import 'package:ladamadelcanchoapp/domain/entities/track.dart';
import 'package:ladamadelcanchoapp/infraestructure/datasources/location_datasource_impl.dart';
import 'package:ladamadelcanchoapp/infraestructure/utils/utils_track.dart';
import 'package:ladamadelcanchoapp/presentation/extra/check_connectivity.dart';
import 'package:ladamadelcanchoapp/presentation/providers/location/location_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:ladamadelcanchoapp/presentation/providers/track/only_track_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/track/track_provider.dart';


class EditTrackScreen extends ConsumerStatefulWidget {
  final String trackFile;
  final List<LocationPoint> points;
  final List<String>? images;
  final String trackId;

  const EditTrackScreen({
    super.key,
    required this.trackFile,
    required this.points,
    required this.trackId,
    this.images
  });

  static const name = 'edit-track-screen';

  @override
  ConsumerState<EditTrackScreen> createState() => _EditTrackScreenState();
}

class _EditTrackScreenState extends ConsumerState<EditTrackScreen> {
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
  List<String> serverImages = [];


  @override
  void initState() {
    super.initState();
    //final rawName = widget.trackFile.uri.pathSegments.last;
    final defaultName = widget.trackFile.replaceAll('.gpx', '');
    _nameController = TextEditingController(text: defaultName);
    polylinePoints = widget.points.map((p) => LatLng(p.latitude, p.longitude)).toList();
    bounds = _calculateBounds(polylinePoints);
    _calculateTrackStats();

    // 🟡 Inicializar imágenes del servidor
    serverImages = widget.images ?? [];

  }

  // 🟡 Nuevo método para eliminar imagen del servidor
  void _removeServerImage(int index) {
    setState(() {
      serverImages.removeAt(index);
    });
  }


  // 🟡 Modificar _pickImages para añadir sin reemplazar
  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();

    if (picked.isNotEmpty) {
      setState(() {
        selectedImages.addAll(picked.map((xfile) => File(xfile.path)));
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

    // ignore: unused_local_variable
    double gain = 0;
    double loss = 0;

    maxElevation = widget.points.first.elevation;
    minElevation = widget.points.first.elevation;

    for (var i = 0; i < widget.points.length - 1; i++) {
      final currElevation = widget.points[i].elevation;
      final nextElevation = widget.points[i + 1].elevation;

      final result = calculateDisAndEle(widget.points);
      distanceKm = result.totalDistanceMeters / 1000;
      elevationGain = result.totalElevationGain;

      final delta = nextElevation - currElevation;
      if (delta > 0) gain += delta;
      if (delta < 0) loss += delta.abs();

      if (currElevation > maxElevation) maxElevation = currElevation;
      if (currElevation < minElevation) minElevation = currElevation;
    }


    elevationLoss = loss;
    

    final startTime = widget.points.first.timestamp.toLocal();
    final endTime = widget.points.last.timestamp.toLocal();
    duration = endTime.difference(startTime);
    startTimeStr = DateFormat.Hm().format(startTime);
    endTimeStr = DateFormat.Hm().format(endTime);
  }

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
    //final uploadState = ref.watch(trackUploadProvider);
    //final uploader = ref.read(trackUploadProvider.notifier);

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

    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Editar track')),
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
                  // 🟡 MODIFICADO: Mostrar imágenes servidor + locales y permitir eliminación
                  SizedBox(
                    height: 80,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: serverImages.length + selectedImages.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          if (index < serverImages.length) {
                            final String imageUrl = '${Environment.apiUrl}/files/tracks/${serverImages[index]}';
                            
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    imageUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () => _removeServerImage(index),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          } else {
                            final localIndex = index - serverImages.length;
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    selectedImages[localIndex],
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedImages.removeAt(localIndex);
                                      });
                                    },
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SafeArea(
              minimum: const EdgeInsets.only(bottom: 40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    // ❌ CANCELAR
                    Expanded(
                      child: SizedBox(
                        width: 160,
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.cancel),
                          label: const Text('Cancelar', style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold
                          ),),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                        
                            context.pop();
                        
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // ✅ GUARDAR
                    Expanded(
                      child:  
                      ref.watch(trackUploadProvider).status == TrackUploadStatus.loading
                          ? SizedBox(
                              width: 160,
                              height: 50,
                              child: TextButton(
                                onPressed: null,
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.all(12),
                                ),
                                child: const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                ),
                              ),
                            )
                      :
                      SizedBox(
                        width: 160,
                        height: 50,
                        child: ElevatedButton.icon(
                          icon:  const Icon(Icons.update_outlined),
                          label: const Text('Actualizar', style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold
                          ),),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                        
                            //comprobar si hay o no internet
                            final hasInternet = await checkAndWarnIfNoInternet(context);
                        
                            if(hasInternet) {
                        
                              final name = _nameController.text.trim();
                              final description = descriptionController.text;
                              final images = selectedImages;
                          
                        
                              if(serverImages.isEmpty) {
                                final File fileCaptureMap = await captureMap();
                                images.add(fileCaptureMap);
                              }
                        
                        
                              
                              
                              // ignore: use_build_context_synchronously
                              final response = await ref.read(trackUploadProvider.notifier).updateTrack(
                                widget.trackId,
                                '$name.gpx',
                                description,
                                imagesOld: serverImages,
                                images: images,
                              );
                        
                              if(response.data['ok']) {
                        
                                Track? track = await ref.read(trackUploadProvider.notifier).existsTrackForName('$name.gpx');
                        
                                if( track != null){
                                  ref.read(trackProvider.notifier).updateTrack(track);
                                }
                                  
                                if(context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('✅ ${response.data['message']}'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }  
                                
                              } else {
                                response;
                              }
                        
                        
                        
                              
                        
                            } 
                        
                            
                          },
                        ),
                      ),
                    ),
                    

                  ],
                ),
              ),
            ),

          ],
        ),
      )
    );

    
    
    
  }

  String _formatDuration(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes % 60;
    return h > 0 ? '${h}h ${m}min' : '${m}min';
  }



}



