import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/domain/entities/track.dart';
import 'package:ladamadelcanchoapp/presentation/providers/track/track_provider.dart';

class TrackScreen extends ConsumerStatefulWidget {
  final String trackId;

  static const name = 'track-screen';

  const TrackScreen({super.key, required this.trackId});

  @override
  ConsumerState<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends ConsumerState<TrackScreen> {
  Track? _track;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTrack();
  }

  Future<void> loadTrack() async {
    try {
      final track = await ref.read(trackUploadProvider.notifier).loadTrackForId(widget.trackId);
      setState(() {
        _track = track;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (context.mounted) {
        // ignore: use_build_context_synchronously
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
        title: Text(_track != null ? 'Track: ${_track!.name}' : 'Cargando...'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _track == null
              ? const Center(child: Text('No se pudo cargar el track.'))
              : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🆔 ID: ${_track!.id}'),
            Text('👤 Usuario: ${_track!.userId}'),
            Text('📛 Nombre: ${_track!.name}'),
            Text('📏 Distancia: ${_track!.distance}'),
            Text('⛰️ Desnivel: ${_track!.elevationGain}'),
            if (_track!.description != null)
              Text('📝 Descripción: ${_track!.description}'),
            if (_track!.type != null)
              Text('🏷️ Tipo: ${_track!.type}'),
            Text('📅 Creado: ${_track!.createdAt.toLocal()}'),
            Text('📅 Actualizado: ${_track!.updatedAt.toLocal()}'),
            const SizedBox(height: 20),

            const Text('🖼️ Imágenes:', style: TextStyle(fontWeight: FontWeight.bold)),
            if (_track!.images != null && _track!.images!.isNotEmpty)
              ..._track!.images!.map((img) => Text('• $img'))
            else
              const Text('No hay imágenes'),

            const SizedBox(height: 20),

            const Text('📍 Puntos GPS:', style: TextStyle(fontWeight: FontWeight.bold)),
            if (_track!.points != null && _track!.points!.isNotEmpty)
              ..._track!.points!.map((p) => Text(
                    '• Lat: ${p.latitude}, Lon: ${p.longitude}, Ele: ${p.elevation}, Time: ${p.timestamp.toLocal()}',
                    style: const TextStyle(fontSize: 12),
                  ))
            else
              const Text('No hay puntos registrados'),
          ],
        ),
      )
      , // Aquí iría el contenido con los detalles del track
    );
  }
}


