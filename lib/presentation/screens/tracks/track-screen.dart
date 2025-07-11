import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:ladamadelcanchoapp/config/constants/environment.dart';
import 'package:ladamadelcanchoapp/domain/entities/location_point.dart';
import 'package:ladamadelcanchoapp/domain/entities/track.dart';
import 'package:ladamadelcanchoapp/infraestructure/mappers/icons_weather_mapper.dart';
import 'package:ladamadelcanchoapp/infraestructure/mappers/nominatim_mapper.dart';
import 'package:ladamadelcanchoapp/infraestructure/mappers/weather_mapper.dart';
import 'package:ladamadelcanchoapp/infraestructure/utils/utils_track.dart';
import 'package:ladamadelcanchoapp/presentation/extra/check_connectivity.dart';
import 'package:ladamadelcanchoapp/presentation/providers/auth/auth_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/city_name/city_name_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/side_menu/side_menu_state_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/track/hovered_point_index_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/track/only_track_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/track/track_list_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/track/track_nearest_list_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/track/track_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/weather/weather_provider.dart';
import 'package:ladamadelcanchoapp/presentation/screens/auth/user_screen.dart';
import 'package:ladamadelcanchoapp/presentation/screens/edit_track/edit_track_screen.dart';
import 'package:ladamadelcanchoapp/presentation/screens/tracks/full_screen_carousel_view.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ladamadelcanchoapp/presentation/widgets/sidemenu/side_menu.dart';





class TrackScreen extends ConsumerStatefulWidget {
  final int? trackIndex;
  final String trackName;
  static const name = 'track-screen';
  const TrackScreen({super.key, this.trackIndex, required this.trackName});
  @override
  ConsumerState<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends ConsumerState<TrackScreen> {
  bool _isLoading = true;
  late List<Track> tracks;
  Track? track;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>(); 
  

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadTrack();
  }

  

  Future<void> loadTrack() async {

    try {

      track = await ref.watch(trackUploadProvider.notifier).existsTrackForName(widget.trackName, ref);

      if( track != null){
        ref.read(trackProvider.notifier).loadTrack(track!);
      }

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      setState(() => _isLoading = false);
      
    }
  }



  @override
  Widget build(BuildContext context) {

    final authState = ref.watch(authProvider).user;
    Track? track = ref.watch(trackProvider);

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        //print('✅ volviendo desde TrackScreen');
        ref.read(trackListProvider.notifier).reset();
        ref.read(sideMenuStateProvider.notifier).resetUserScreen();
        await ref.read(trackListProvider.notifier).changeOrdersAndDirection(ref,'created_at', 'desc', null);
        await ref.read(trackListProvider.notifier).loadTracks(
          ref,
          limit: 5,
          page: 1,
          append: false,
        );
        return true;
      },
      
      child: Scaffold(
        key: scaffoldKey,
        drawer: SideMenu(scaffoldKey: scaffoldKey),
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          scrolledUnderElevation: 0,
          title: Text(track != null ? track.name.split('.').first : 'Cargando...'),
          actions: [

            (authState != null) ?
            IconButton(
              onPressed: () async {
                if (track == null) return;

                // 1. Toggle local inmediato (actualiza el icono)
                ref.read(trackProvider.notifier).toggleFavoriteLocal();

                try {
                  // 2. Backend toggle
                  await ref.read(trackUploadProvider.notifier).toggleFavorite(
                    ref,
                    track.id,
                    track.isFavorite!, // ¡Importante! Enviamos el valor original (ya invertido localmente)
                    authState,
                  );
                } catch (e) {
                  // 3. Si falla, revertimos el cambio
                  ref.read(trackProvider.notifier).toggleFavoriteLocal();


                }
              },

              icon: Icon(
                track != null && track.isFavorite! ? Icons.favorite : Icons.favorite_border,
                color: track != null &&  track.isFavorite! ? Colors.red : Colors.white,
                size: 25,
              ),



            ) 
          :

          const SizedBox()

          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : track == null
                ? const Center(child: Text('No se pudo cargar el track.'))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _DatosWidget(track: track),
                      _Map(track: track),
                      _Perfil(track: track),
                      _Description(track: track,),
                      const SizedBox(height: 20),
                      if (track.images != null && track.images!.isNotEmpty)
                        _Card(track: track)
                      else
                        const Text('No hay imágenes disponibles.'),
                      const SizedBox(height: 20),
                      _WeatherData(firstPoint: track.points!.first),
                      _Nearest(track: track),
                      const SizedBox(height: 0),
                      

                      if(authState != null && authState.id == track.user!.id)
                        _Buttons(track: track,),
                      const SizedBox(height: 20),


                    ],
                  ),
      ),
    );
  }
}



class _DatosWidget extends ConsumerWidget {

  final Track track;

  const _DatosWidget({required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
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

              GestureDetector(
                onTap: () async {

                  await ref.read(trackListProvider.notifier).loadTracks(
                    ref,
                    limit: 5,
                    page: 1,
                    userId: track.user!.id,
                  );

                  if(context.mounted) {
                    context.pushNamed( UserScreen.name, extra: track.user);
                  }
                  
                },
                child: Text(track.user!.fullname)),
      
              const SizedBox(height: 16),

              Row(
                children: [
                  Text(
                '📏 Distancia:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 6),

              /*
              Text(
                distance >= 1000
                  ? '${(distance / 1000).toStringAsFixed(1)} km'
                  : '${distance.toInt()} metros',
              ),
              */
              Text('${(distance).toStringAsFixed(2)} km'),

      
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
                Text(
                  (track.description?.trim().isNotEmpty ?? false)
                      ? (track.description!.length > 25
                          ? '${track.description!.substring(0, 25)}...'
                          : track.description!)
                      : 'No hay descripción'
                )

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

    final points = track.points!;
    final flSpots = buildElevationProfile(track.points!, double.parse(track.distance));
    print('📏 Distancia final en el gráfico: ${flSpots.last.x}');
    //print('📄 Distancia guardada en el track: ${track.distance} km');

    final elevations = track.points!.map((p) => p.elevation).toList();
    
    final minElevation = elevations.reduce(min);
    final maxElevation = elevations.reduce(max);
    final diffElevation = maxElevation - minElevation;

    // Margen fijo mínimo de seguridad visual
    const double margin = 100; // puedes poner 10, 15, 20... lo que se vea mejor

    // Calculamos el eje Y ajustado y redondeado a la decena más próxima
    int minY = ((minElevation - margin) ~/ 100) * 100;
    int maxY = (((maxElevation + margin) + 9) ~/ 5) * 5;

    double intervalElevation;
    double intervalDistance;


    final distanceKm = flSpots.last.x / 1000;


    if(distanceKm <=5) {
      intervalDistance = 500;
    } else if(distanceKm <= 10) {
      intervalDistance = 1000;
    } else if( distanceKm <= 20) {
      intervalDistance = 2000;
    } else if(distanceKm <= 30) {
      intervalDistance = 4000;
    } else {
      intervalDistance = 5000;
    }

    if (diffElevation <= 50) {

      intervalElevation = 50;
      minY = (minElevation ~/ 30) * 30;
      maxY = (minY + 3 * intervalElevation + ((diffElevation ~/ intervalElevation) * intervalElevation)).toInt();

    } else if (diffElevation <= 100) {

      intervalElevation = 100;
      minY = (minElevation ~/ 100) * 100;
      maxY = (((maxElevation + 99) ~/ 100) * 100) + 100;

    } else if (diffElevation <= 200) {

      intervalElevation = 100;
      minY = (minElevation ~/ 100) * 100;
      maxY = (((maxElevation + 99) ~/ 100) * 100) + 100;

    } else if (diffElevation <= 300) {

      intervalElevation = 100;
      minY = (minElevation ~/ 100) * 100;
      maxY = (((maxElevation + 99) ~/ 100) * 100);

    } else if (diffElevation <= 600) {

      intervalElevation = 200;
      minY = (minElevation ~/ 100) * 100;
      maxY = (((maxElevation + 99) ~/ 100) * 100);
      
    } else {
      
      intervalElevation = 250;
      minY = (minElevation ~/ 100) * 100;
      maxY = (((maxElevation + 399) ~/ 100) * 100);

    }


    

    return SizedBox(
      height: 230,
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
                    //maxX: double.parse(track.distance) * 1000, // asegúrate de que esté en metros si usas intervalos en metros
                    maxX: flSpots.last.x,
                    minY: minY.toDouble(),
                    maxY: maxY.toDouble(),
                
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
                            
                            const FlLine(
                              // ignore: deprecated_member_use
                              color: Colors.black, // 🎯 Línea vertical
                              strokeWidth: 2,
                            ),
                                                
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
                        spots: flSpots, // este debe tener x = distancia acumulada en metros
                        isCurved: true,
                        color: Colors.black,
                        barWidth: 2,
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: const LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              ColorsPeronalized.successColor,
                              Colors.yellow,
                              Colors.orange,
                              ColorsPeronalized.cancelColor,
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
                          interval: intervalElevation,
                          getTitlesWidget: (value, meta) {
                            if (value % intervalElevation != 0) return const SizedBox.shrink();

                            return Text('${value.toInt()}', style: const TextStyle(fontSize: 10));
                          },

                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: intervalDistance,
                          getTitlesWidget: (value, meta) {
                            // solo mostrar si el valor es múltiplo del intervalo
                            if (value % intervalDistance != 0) return const SizedBox.shrink();

                            final finalKm = (value / 1000) < 5 
                            ?
                              (value / 1000).toStringAsFixed(1)
                            :
                              (value / 1000).toStringAsFixed(0);

                            return Padding(
                              padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
                              child: Text(finalKm == '0.0' ? '0': finalKm, style: const TextStyle(fontSize: 10)),
                            );
                          }

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
  ConsumerState<_Map> createState() => _TrackMapState();
}

class _TrackMapState extends ConsumerState<_Map> {
  final GlobalKey _mapKey = GlobalKey();
  GoogleMapController? _mapController;
  Offset? _currentOffset;
  late final List<LatLng> _polylinePoints;

  @override
  void initState() {
    super.initState();
    _polylinePoints = widget.track.points!
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();
  }

  @override
  Widget build(BuildContext context) {

    final hoveredPoint = ref.watch(hoveredPointLatLngProvider);

    // Se ejecuta en el frame siguiente, ideal para leer el tamaño y los bounds ya renderizados
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      if (hoveredPoint == null) {
        if (_currentOffset != null) {
          setState(() {
            _currentOffset = null;
          });
        }
        return;
      }

      if (_mapController == null) return;

      final bounds = await _mapController!.getVisibleRegion();
      final mapBox = _mapKey.currentContext?.findRenderObject() as RenderBox?;
      if (mapBox == null) return;

      final mapSize = mapBox.size;

      final offsetInMap = latLngToOffset(
        point: hoveredPoint,
        bounds: bounds,
        mapSize: mapSize,
      );

      if (_currentOffset != offsetInMap) {
        setState(() {
          _currentOffset = offsetInMap;
        });
      }
    });


    return SizedBox(
      height: 400,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              GoogleMap(
                key: _mapKey,
                mapType: MapType.hybrid,
                initialCameraPosition: CameraPosition(
                  target: _polylinePoints.first,
                  zoom: 16,
                ),
                onMapCreated: (controller) async {
                  _mapController = controller;
                  await Future.delayed(const Duration(milliseconds: 300));
                  _fitBounds();
                },
                polylines: {
                  Polyline(
                    polylineId: const PolylineId('track'),
                    points: _polylinePoints,
                    color: Colors.blue,
                    width: 4,
                  ),
                },
                markers: {
                  Marker(
                    markerId: const MarkerId('start'),
                    position: _polylinePoints.first,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueGreen),
                  ),
                  Marker(
                    markerId: const MarkerId('end'),
                    position: _polylinePoints.last,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed),
                  ),
                },
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory(() => EagerGestureRecognizer()),
                },
                
              ),
        
              // Punto flotante blanco sobre el mapa
              if (_currentOffset != null)
                Positioned(
                  left: _currentOffset!.dx - 6,
                  top: _currentOffset!.dy - 6,
                  child: IgnorePointer(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blueAccent, width: 2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _fitBounds() {
    if (_mapController == null || _polylinePoints.length < 2) return;

    final bounds = _getLatLngBounds(widget.track.points!);
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
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

  Offset latLngToOffset({
    required LatLng point,
    required LatLngBounds bounds,
    required Size mapSize,
  }) {
    // Coordenadas de los límites
    final southWest = bounds.southwest;
    final northEast = bounds.northeast;

    // Diferencias de latitud y longitud
    final latRange = northEast.latitude - southWest.latitude;
    final lngRange = northEast.longitude - southWest.longitude;

    // Coordenadas relativas (0..1)
    final xPercent = (point.longitude - southWest.longitude) / lngRange;
    final yPercent = 1 - ((point.latitude - southWest.latitude) / latRange); // invertido

    // Offset en píxeles dentro del widget
    return Offset(
      xPercent * mapSize.width,
      yPercent * mapSize.height,
    );
  }
}

class _Nearest extends ConsumerStatefulWidget {
  final Track track;
  const _Nearest({required this.track});

  @override
  ConsumerState<_Nearest> createState() => _NearestState();
}

class _NearestState extends ConsumerState<_Nearest> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(trackNearestListProvider.notifier).resetState();
      ref.read(trackNearestListProvider.notifier).loadNearestTracks(ref, widget.track.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tracksNearest = ref.watch(trackNearestListProvider);

    
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 20),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📍 Rutas Cercanas:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(height: 12),

            if(tracksNearest.tracks.isEmpty)
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),

            SizedBox(
              height: 200, // altura de las miniaturas
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tracksNearest.tracks.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                
                itemBuilder: (context, index) {
                  
                  final track = tracksNearest.tracks[index];
                  final imageUrl = "${Environment.apiUrl}/files/tracks/${track.images!.first}";

                  return GestureDetector(
                    onTap: () {


                      context.pushNamed(
                        TrackScreen.name,
                        extra: {'trackName': track.name},
                      );  


                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
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

                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('A ${(track.distanceFromCurrent! / 1000).toStringAsFixed(2)} km'),
                              Text('Distancia: ${(double.parse(track.distance)).toStringAsFixed(0)} km'),
                              Text('Desnivel: ${(double.parse(track.elevationGain)).toStringAsFixed(0)} m'),
                            ],
                          ),
                        )

                      ],
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

class _Buttons extends ConsumerWidget {
  final Track track;
  const _Buttons({required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final TrackUploadState trackStatus = ref.watch(trackUploadProvider);

    return SafeArea(
        minimum: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              
              Expanded(
                child: SizedBox(
                  width: 160,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar', style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold
                            ),),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsPeronalized.infoColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      //comprobar si hay o no internet
                      final hasInternet = await checkAndWarnIfNoInternet(context);
                  
                      if(hasInternet && context.mounted) {
                  
                        final result = await context.pushNamed(
                          EditTrackScreen.name, // o TrackPreviewScreen.name
                          extra: {
                            'trackFile': track.name, // puedes cambiar por un File real si lo necesitas
                            'points': track.points,
                            'images': track.images,
                            'trackId': track.id,
                          },
                        );
                  
                        if (result == 'uploaded') {
                          // Track subido, eliminarlo
                          //await ref.read(pendingTracksProvider.notifier).removeTrack(index);
                        }
                  
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(width: 10,),

              ( trackStatus.status == TrackUploadStatus.loading ) ?


                SizedBox(
                  width: 160,
                  height: 50,
                  child: TextButton(
                    onPressed: null, // 🔒 Deshabilitado mientras carga
                    style: TextButton.styleFrom(
                      backgroundColor: ColorsPeronalized.cancelColor, // 🔥 Color de fondo
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.all(12), // 📏 Tamaño del botón
                    ),
                    child: const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white, // 🎨 Color del loading
                        strokeWidth: 3, // 📏 Grosor del círculo
                      ),
                    ),
                  ),
                )

              :

              Expanded(
                child: SizedBox(
                  width: 160,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.cancel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsPeronalized.cancelColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          insetPadding: const EdgeInsets.all(10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          title: const Column(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: ColorsPeronalized.cancelColor),
                              SizedBox(width: 10),
                              Text('¿Eliminar track?'),
                            ],
                          ),
                          content: const Text(
                            '¿Seguro que deseas eliminar este track?\nEsta acción no se puede deshacer.',
                            textAlign: TextAlign.center,
                          ),
                          actionsAlignment: MainAxisAlignment.spaceAround,
                          actions: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                              width: 140,
                              height: 50,
                              child: FilledButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  backgroundColor: ColorsPeronalized.cancelColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Cancelar'),
                              ),
                            ),
                            const SizedBox(width: 10,),
                            SizedBox(
                              width: 140,
                              height: 50,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: ColorsPeronalized.successColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  
                                  final result = await ref.read(trackUploadProvider.notifier).deleteTrack(ref, track.id);
                                  
                                  if (context.mounted && result.statusCode == 200) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('✅ ${result.data['message']}'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                            
                                    await ref.read(trackListProvider.notifier).loadTracks(
                                      ref,
                                      limit: 5,
                                      page: 1,
                                      append: false
                                    );
                            
                                    await Future.delayed(const Duration(milliseconds: 500));
                            
                                    if (context.mounted) {
                                      context.go('/');
                                    }
                            
                                  } else if( context.mounted && result.statusCode == 500) {
                            
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('❌ Servidor parece caído, intentelo mas tarde'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                            
                                  }

                                },
                                child: const Text('Eliminar'),
                              ),
                            ),
                              ],
                            )
                            
                          ],
                        ),
                      );
                    },
                    label: const Text('Eliminar', style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold
                            ),),
                  ),
                ),
              ),


            ],
          ),
        ),
      );
  }
}

class _Description extends StatelessWidget {

  final Track track;

  const _Description({required this.track});

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
              '📝 Descripción:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary),
            ),

            const SizedBox(height: 12),

             Container(
              width: double.infinity,
              decoration: BoxDecoration(
                
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.transparent),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                track.description?.trim().isNotEmpty == true
                    ? track.description!
                    : 'Sin descripción.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),

          ],
        ),
      ),
    );
  }
}

class _WeatherData extends ConsumerStatefulWidget {
  final LocationPoint firstPoint;
  const _WeatherData({required this.firstPoint,});

  @override
  ConsumerState<_WeatherData> createState() => _WeatherDataState();
}

class _WeatherDataState extends ConsumerState<_WeatherData> {
  WeatherResponse? localWeatherData;
  NominatimResponse? dataLocationPoint;
  String cityName = '';

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      localWeatherData = await ref.read(weatherProvider.notifier).fetchWeatherData(widget.firstPoint);
      dataLocationPoint = await ref.read(cityNameProvider.notifier).fetchCityName(widget.firstPoint);

      if(dataLocationPoint?.address.city != '') {
        cityName = dataLocationPoint!.address.city;
      } else if( dataLocationPoint?.displayName != '') {
        cityName = dataLocationPoint!.displayName;
      } else {
        cityName = 'Indeterminado';
      }


      setState(() {}); // actualiza la vista con los datos
    });
  }

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
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🌤️ El Tiempo:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                  child: Text(
                    cityName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            if (localWeatherData != null)
              WeatherTable(daily: localWeatherData!.daily)
            else
              const Center(child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              )),
          ],
        ),
      ),
    );
  }
}

class WeatherTable extends StatelessWidget {
  final Daily daily;

  const WeatherTable({required this.daily, super.key});

  @override
  Widget build(BuildContext context) {

    const daysToShow = 4;

    return Table(
      columnWidths: const {
        0: FixedColumnWidth(50),
      },
      border: TableBorder.all(color: Colors.grey.shade300),
      children: [
        // 🗓️ Cabecera: días de la semana
        TableRow(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(child: Text('Dia', style: TextStyle(fontSize: 11))),
            ), // celda vacía arriba a la izquierda
            for (final date in daily.time.take(daysToShow))
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text('${DateFormat.E('es_ES').format(date)} ${date.day}' , style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
          ],
        ),
        // ☁️ ICONO TIEMPO
        TableRow(
          children: [
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Icon(Icons.wb_cloudy, size: 18),
            ), // icono de clima
            for (final code in daily.weathercode.take(daysToShow))
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(child: Text(WeatherEmoji.getEmoji(code), style: const TextStyle(fontSize: 18))),
              )
          ],
        ),
        // 💧 PRECIPITACIÓN
        TableRow(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(child: Icon(Icons.grain)),
            ), // icono lluvia
            for (final prec in daily.precipitationSum.take(daysToShow))
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
                child: Center(child:
                (prec.toStringAsFixed(1) == '0.0') ? const Text('-', style: TextStyle(fontSize: 12),) : Text('${prec.toStringAsFixed(1)} mm', style: const TextStyle(fontSize: 12))
                ),
              ),
          ],
        ),
        // 🔥 TEMP MÁX
        TableRow(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(child: Icon(Icons.thermostat)),
            ), // icono temperatura
            for (final max in daily.temperature2MMax.take(daysToShow))
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Center(child: Text('${max.toStringAsFixed(0)}°', style: const TextStyle(fontSize: 12),)),
              ),
          ],
        ),
        // ❄️ TEMP MÍN
        TableRow(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(child: Icon(Icons.ac_unit)),
            ), // icono frío
            for (final min in daily.temperature2MMin.take(daysToShow))
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Center(child: Text('${min.toStringAsFixed(0)}°', style: const TextStyle(fontSize: 12),)),
              ),
          ],
        ),
      ],
    );
  }
}
