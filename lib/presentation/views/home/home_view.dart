import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ladamadelcanchoapp/config/constants/environment.dart';
import 'package:ladamadelcanchoapp/domain/entities/track.dart';
import 'package:ladamadelcanchoapp/presentation/providers/auth/auth_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/track/track_list_provider.dart';

import 'package:timeago/timeago.dart' as timeago;

class HomeView extends ConsumerWidget {

  static const name = 'home-view';

  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final auth = ref.watch(authProvider);
    final imageUrl = "${Environment.apiUrl}/files/${auth.user?.image}";

    final trackState = ref.watch(trackListProvider);
    final trackNotifier = ref.read(trackListProvider.notifier);

    // Cargar tracks si es necesario
    if (trackState.status == TrackListStatus.initial) {
      Future.microtask(() => trackNotifier.loadTracks(userId: auth.user?.id));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [

          (auth.isAuthenticated) ?
          
          GestureDetector(
            onTap: () {
              GoRouter.of(context).push('/profile');
            },
            child: SizedBox(
              height: 40,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipOval(
                  child: Image.network(
                    imageUrl,
                    width: 40, // Tamaño de la imagen
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.grey,
                    ), // 🔥 Si la imagen no carga, muestra un ícono
                  ),
                ),
              ),
            ),
          )

          :

          SizedBox(
            height: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: IconButton.filledTonal(
                onPressed: () {
                  GoRouter.of(context).push('/login');
                }, 
                icon: const Icon(Icons.login)
              ),
            ),
          ),

        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Builder(
          builder: (_) {
            if (trackState.status == TrackListStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (trackState.status == TrackListStatus.error) {
              return Center(child: Text('Error: ${trackState.errorMessage}'));
            }

            if (trackState.tracks.isEmpty) {
              return const Center(child: Text('No hay rutas disponibles.'));
            }

            
            return RefreshIndicator(
              onRefresh: () async {
                await ref.read(trackListProvider.notifier).loadTracks(userId: auth.user?.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Rutas actualizadas'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: ListView.builder(
                itemCount: trackState.tracks.length,
                physics: const AlwaysScrollableScrollPhysics(), // permite arrastrar aunque haya pocos elementos
                itemBuilder: (context, index) {
                  final track = trackState.tracks[index];
                  timeago.setLocaleMessages('es', timeago.EsMessages());
                  return TrackCard(
                    image: (track.images != null && track.images!.isNotEmpty) ? track.images!.first : null,
                    track: track,
                  );
                },
              ),
            );

          },
        ),
      ),
    );
  }


}

class TrackCard extends StatelessWidget {

  final String? image;
  final Track track;

  const TrackCard({super.key, this.image, required this.track});

  @override
  Widget build(BuildContext context) {


    //const imageTrackUrl = 'https://upload.wikimedia.org/wikipedia/en/6/60/No_Picture.jpg';
    //final imageTrackUrl = "${Environment.apiUrl}/files/${track.images.first}";

    var imageTrackUrl = (track.images?.isNotEmpty ?? false)
      ? "${Environment.apiUrl}/files/tracks/${track.images!.first}"
      : 'https://upload.wikimedia.org/wikipedia/en/6/60/No_Picture.jpg';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: SizedBox(
          height: 120,
          child: Row(
            children: [
              // 📷 Imagen (30%)
              Container(
                width: MediaQuery.of(context).size.width * 0.3,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
                  image: DecorationImage(
                    image: NetworkImage(imageTrackUrl), // Puedes cambiar esto si tienes una lista de imágenes por ruta
                    fit: BoxFit.cover,
                    onError: (error, stackTrace) {}, // No mostrar error
                  ),
                ),
              ),

              // 🧾 Info del track (70%)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // 🏷 Nombre
                      Row(
                        children: [
                          const Icon(Icons.route, size: 18, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              track.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      // ⏱ Time ago
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 18, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(timeago.format(track.createdAt, locale: 'es')),
                        ],
                      ),

                      // 📏 Distancia (de momento vacío)
                      Row(
                        children: [
                          const Icon(Icons.straighten, size: 18, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(track.distance), // Distancia se rellenará luego
                          const SizedBox(width: 20,),
                          const Icon(Icons.terrain, size: 18, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(track.elevationGain),
                        ],
                      ),
                    ],
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