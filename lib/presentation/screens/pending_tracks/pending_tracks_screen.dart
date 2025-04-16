import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ladamadelcanchoapp/presentation/providers/pendings/pending_tracks_provider.dart';

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
      ref.read(pendingTracksProvider.notifier).loadTracks(); // 👈 Aquí se cargan
    });
  }

  String _formatTimestamp(String rawTimestamp) {
    final date = DateTime.parse(rawTimestamp).toLocal();
    return DateFormat('dd/MM/yyyy - HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final tracks = ref.watch(pendingTracksProvider);
    final notifier = ref.read(pendingTracksProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Tracks pendientes')),
      body: tracks.isEmpty
          ? const Center(child: Text('No hay tracks pendientes.'))
          : ListView.builder(
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                final track = tracks[index];
                final timestamp = track['timestamp'];
                final distance = track['state']['distance'];

                return ListTile(
                  leading: const Icon(Icons.route),
                  title: Text(_formatTimestamp(timestamp)),
                  subtitle: Text('📏 ${(distance / 1000).toStringAsFixed(2)} km'),
                  trailing: IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          title: const Row(
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
                            SizedBox(
                              width: 100,
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancelar'),
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  await notifier.removeTrack(index);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('❌ Track eliminado'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Eliminar'),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
