
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:ladamadelcanchoapp/config/constants/environment.dart';
import 'package:ladamadelcanchoapp/domain/entities/location_point.dart';
import 'package:ladamadelcanchoapp/domain/entities/track.dart';
import 'package:ladamadelcanchoapp/infraestructure/utils/utils_track.dart';
import 'package:ladamadelcanchoapp/presentation/providers/track/hovered_point_index_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/track/track_list_provider.dart';
import 'package:ladamadelcanchoapp/presentation/screens/tracks/full_screen_carousel_view.dart';
import 'package:fl_chart/fl_chart.dart';

class TrackScreen extends ConsumerStatefulWidget {
  final int trackIndex;

  static const name = 'track-screen';

  const TrackScreen({super.key, required this.trackIndex});

  @override
  ConsumerState<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends ConsumerState<TrackScreen> {
  Track? _track;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadTrack();
  }

  Future<void> loadTrack() async {
    try {
      final tracks = ref.watch(trackListProvider).tracks;
      if (widget.trackIndex < 0 || widget.trackIndex >= tracks.length) {
        throw Exception('Índice de track inválido');
      }
      final track = tracks[widget.trackIndex];
      setState(() {
        _track = track;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al cargar el track: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(_track != null ? _track!.name.split('.').first : 'Cargando...'),
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _track == null
            ? const Center(child: Text('No se pudo cargar el track.'))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // DATOS
                  _DatosWidget(track: _track!),

                  // MAPA (✅ ahora es completamente interactivo)
                  _Map(track: _track!),

                  // PERFIL TRACK
                  _Perfil(track: _track!),

                  // IMAGENES
                  if (_track!.images != null && _track!.images!.isNotEmpty)
                    _Card(track: _track!)
                  else
                    const Text('No hay imágenes disponibles.'),

                  const SizedBox(height: 60),
                ],
              ),
  );
}

}


class _DatosWidget extends StatelessWidget {

  final Track track;

  const _DatosWidget({required this.track});

  @override
  Widget build(BuildContext context) {
    
    final elevation = double.parse(track.elevationGain);
    final distance = double.parse(track.distance);
    final formattedDate = DateFormat('dd-MM-yyyy HH:mm').format(track.createdAt.toLocal());

    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
      
              Text(
                '👤 Usuario:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 6),
              Text(track.user.fullname),
      
              const SizedBox(height: 16),

              Row(
                children: [
                  Text(
                '📏 Distancia:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 6),

              Text(
                distance >= 1000
                  ? '${(distance / 1000).toStringAsFixed(1)} km'
                  : '${distance.toInt()} metros',
              ),

      
              const SizedBox(width: 8),
      
              Text(
                '⬆️ Des:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 6),
              Text('${elevation.toInt()} m'),
                ],
              ),
      
              
      
              if (track.description != null) ...[
                const SizedBox(height: 16),
                Text(
                  '📝 Descripción:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 6),
                Text((track.description?.trim().isNotEmpty ?? false) ? track.description! : 'No hay descripción')

              ],
      
              if (track.type != null) ...[
                const SizedBox(height: 16),
                Text(
                  '🏷️ Tipo:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 6),
                Text(track.type!),
              ],
      
              const SizedBox(height: 16),
      
              Text(
                '📅 Creado:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 6),
              Text(formattedDate),
      
            ],
          ),
        ),
      ),
    );

  }
}


class _Card extends StatelessWidget {

  final Track track;

  const _Card({required this.track});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              '🖼️ Imágenes:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary),
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 100, // altura de las miniaturas
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: track.images!.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                
                itemBuilder: (context, index) {
                  final imageUrl = "${Environment.apiUrl}/files/tracks/${track.images![index]}";

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenCarouselView(
                            images: track.images!,
                            initialIndex: index,
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        imageUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[300],
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                },


              ),
            ),

          ],
        ),
      ),
    );
  }
}


class _Perfil extends ConsumerWidget {
  final Track track;
  const _Perfil({required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final elevations = track.points!.map((p) => p.elevation).toList();
    final minElevation = elevations.reduce(min);
    final maxElevation = elevations.reduce(max);
    final double interval = maxElevation - minElevation < 600 ? 100 : 200;
    final points = track.points!;

    return SizedBox(
      height: 275,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📈 Perfil',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: LineChart(
                  
                  LineChartData(
                    backgroundColor: const Color.fromARGB(255, 106, 186, 223),
                    minX: 0,
                    maxX: double.parse(track.distance), // asegúrate de que esté en metros si usas intervalos en metros
                    minY: (minElevation ~/ 100) * 100,
                    maxY: ((maxElevation + 99) ~/ 100) * 100 + 200,
                
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: Colors.black, // 🎨 Fondo del cartelito
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final elevation = spot.y.toStringAsFixed(1);
                            final distance = (spot.x / 1000).toStringAsFixed(1);
                            return LineTooltipItem(
                              '$elevation m\n$distance km',
                              const TextStyle(
                                color: Colors.white,  // 🖍 Color del texto
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList();
                        },
                      ),
                      touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                        if (response != null && response.lineBarSpots != null && response.lineBarSpots!.isNotEmpty) {
                          final index = response.lineBarSpots!.first.spotIndex;
                          final p = points[index];
                          ref.read(hoveredPointLatLngProvider.notifier).setPoint(LatLng(p.latitude, p.longitude));
                        } else {
                          ref.read(hoveredPointLatLngProvider.notifier).clear();
                        }
                      },
                      handleBuiltInTouches: true, // activa el comportamiento por defecto
                      getTouchedSpotIndicator:
                        (LineChartBarData barData, List<int> indicators) {
                        return indicators.map((int index) {
                          return TouchedSpotIndicatorData(
                            const FlLine(color: Colors.transparent), // oculta la línea vertical
                            FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, bar, index) =>
                                  FlDotCirclePainter(
                                    radius: 4,
                                    color: Colors.blue, // 🎯 color del punto
                                    strokeColor: Colors.blue,
                                    strokeWidth: 1,
                                  ),
                            ),
                          );
                        }).toList();
                      },
                    ),
                    
                    lineBarsData: [
                      LineChartBarData(
                        spots: buildElevationProfile(track.points!), // este debe tener x = distancia acumulada en metros
                        isCurved: true,
                        color: Colors.black,
                        barWidth: 2,
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: const LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.green,
                              Colors.yellow,
                              Colors.orange,
                              Colors.red,
                            ],
                          ),
                        ),
                
                        dotData: const FlDotData(show: false),
                      )
                    ],
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: interval,
                          getTitlesWidget: (value, meta) {
                            return Text('${value.toInt()}', style: const TextStyle(fontSize: 10));
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1000, // 👈 Etiqueta cada 1000 metros (1 km)
                          getTitlesWidget: (value, meta) {
                            final totalDistance = double.parse(track.distance);
                            final km = (value / 1000).toStringAsFixed(0); // Redondeado al km
                            // Ocultar si está cerca del valor final
                            if ((value - totalDistance).abs() < 1.0) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(10, 5, 5, 5), // Mueve el texto hacia arriba
                              child: Text(km, style: const TextStyle(fontSize: 10)),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      drawHorizontalLine: true,
                      horizontalInterval: 100, // cada 100m en el eje Y
                      verticalInterval: 1000,  // cada 1000m en el eje X, ajusta al que uses realmente
                      getDrawingHorizontalLine: (value) => FlLine(
                        // ignore: deprecated_member_use
                        color: Colors.grey.withOpacity(0.3),
                        strokeWidth: 1,
                      ),
                      getDrawingVerticalLine: (value) => FlLine(
                        // ignore: deprecated_member_use
                        color: Colors.grey.withOpacity(0.3),
                        strokeWidth: 1,
                      ),
                    ),
                
                    borderData: FlBorderData(show: true),
                  ),
                ),
              ),
            ],
          ),

        ),
      ),
    );
  }
} 

class _Map extends ConsumerStatefulWidget {
  final Track track;

  const _Map({required this.track});

  @override
  ConsumerState<_Map> createState() => _MapState();
}

class _MapState extends ConsumerState<_Map> {
  GoogleMapController? mapController;
  MapType _mapType = MapType.hybrid;

  @override
  Widget build(BuildContext context) {

    final hoveredLatLng = ref.watch(hoveredPointLatLngProvider);

    final List<LatLng> polylinePoints = widget.track.points!
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    final Set<Marker> markers = {
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
    };


    // 👉 Añadir marcador dinámico según índice tocado
    if (hoveredLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('hovered'),
          position: hoveredLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }


    return SizedBox(
      height: 400,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 16, 5, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              GoogleMap(
                mapType: _mapType,
                initialCameraPosition: CameraPosition(
                  target: polylinePoints.first,
                  zoom: 16,
                ),
                myLocationEnabled: false,
                zoomGesturesEnabled: true,
                scrollGesturesEnabled: true,
                rotateGesturesEnabled: true,
                tiltGesturesEnabled: true,
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                },
                polylines: {
                  Polyline(
                    polylineId: const PolylineId('preview_polyline'),
                    points: polylinePoints,
                    color: Colors.blue,
                    width: 5,
                  ),
                },
                markers: markers,
                onMapCreated: (controller) async {
                  mapController = controller;
                  await Future.delayed(const Duration(milliseconds: 300));
                  _fitBounds();
                },
              ),

              // 🟢 Botón flotante dentro del mapa
              Positioned(
                top: 10,
                right: 10,
                child: FloatingActionButton(
                  heroTag: 'mapTypeBtn',
                  mini: true,
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  onPressed: () {
                    setState(() {
                      _mapType = _mapType == MapType.normal ? MapType.hybrid : MapType.normal;
                    });
                  },
                  child: const Icon(Icons.layers),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _fitBounds() {
    if (mapController == null || widget.track.points!.length < 2) return;

    final bounds = _getLatLngBounds(widget.track.points!);
    mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  LatLngBounds _getLatLngBounds(List<LocationPoint> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}