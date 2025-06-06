import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ladamadelcanchoapp/presentation/extra/check_connectivity.dart';
import 'package:ladamadelcanchoapp/presentation/providers/pendings/pending_tracks_provider.dart';
import 'package:ladamadelcanchoapp/presentation/screens/tracks/preview-track-screen.dart';

class PendingTracksScreen extends ConsumerStatefulWidget {
  static const name = 'pending-tracks-screen';

  const PendingTracksScreen({super.key});

  @override
  ConsumerState<PendingTracksScreen> createState() => _PendingTracksScreenState();
}

class _PendingTracksScreenState extends ConsumerState<PendingTracksScreen> {

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(pendingTracksProvider.notifier).loadTracks(); // 👈 Cargar al iniciar
    });
  }

  String _formatTimestamp(DateTime date) {
    return DateFormat('dd/MM/yyyy - HH:mm').format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final tracks = ref.watch(pendingTracksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tracks pendientes')),
      body: tracks.isEmpty
          ? const Center(child: Text('No hay tracks pendientes.'))
          : ListView.builder(
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                final track = tracks[index];

                return ListTile(
                  leading: const Icon(Icons.route),
                  title: Text(_formatTimestamp(track.timestamp)),
                  subtitle: Text('📏 ${(track.distance / 1000).toStringAsFixed(2)} km'),
                  trailing: IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          insetPadding: const EdgeInsets.all(10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          title: const Column(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.red),
                              SizedBox(width: 10),
                              Text('¿Eliminar track?'),
                            ],
                          ),
                          content: const Text(
                            '¿Seguro que deseas eliminar este track pendiente?\nEsta acción no se puede deshacer.',
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
                                  backgroundColor: Colors.red,
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
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  
                                  await ref.read(pendingTracksProvider.notifier).removeTrack(index);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('✅ Track eliminado'),
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
                  ),
                  onTap: () async {

                    //comprobar si hay o no internet
                    final hasInternet = await checkAndWarnIfNoInternet(context);

                    if(hasInternet && context.mounted) {

                      final result = await context.pushNamed(
                        TrackPreviewScreen.name, // o TrackPreviewScreen.name
                        extra: {
                          'trackFile': File('offline.gpx'), // puedes cambiar por un File real si lo necesitas
                          'points': track.points,
                          'index': index
                        },
                      );

                      if (result == 'uploaded') {
                        // Track subido, eliminarlo
                        //await ref.read(pendingTracksProvider.notifier).removeTrack(index);
                      }

                    } 

                    
                    
                  },
                );
              },
            ),
    );
  }
}