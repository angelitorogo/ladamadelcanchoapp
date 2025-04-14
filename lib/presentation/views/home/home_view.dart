
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ladamadelcanchoapp/config/constants/environment.dart';
import 'package:ladamadelcanchoapp/domain/entities/track.dart';
import 'package:ladamadelcanchoapp/presentation/providers/auth/auth_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/track/track_list_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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


    Future<void> showDebugDialog(BuildContext context) async {
      final prefs = await SharedPreferences.getInstance();
      final prefsKeys = prefs.getKeys();

      final prefsInfo = prefsKeys.isEmpty
          ? 'No hay preferencias guardadas.'
          : prefsKeys.map((k) => '• $k: ${prefs.get(k)}').join('\n');

      final jar = ref.read(authProvider.notifier).jar();
      final cookies = await jar?.loadForRequest(Uri.parse('https://cookies.argomez.com'));


      final cookiesInfo = cookies?.isEmpty ?? true
        ? 'No hay cookies guardadas.'
        : cookies!.map((c) => '• ${c.name} = ${c.value}').join('\n');

      // Mostramos todo en un AlertDialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Debug info'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🔑 SharedPreferences:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(prefsInfo),
                  const SizedBox(height: 12),
                  const Text('🍪 Cookies:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(cookiesInfo),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
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

      floatingActionButton: FloatingActionButton(
        onPressed: () => showDebugDialog(context),
        child: const Icon(Icons.bug_report),
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

    final icon = switch (track.type) {
      'Senderismo' => Icons.directions_walk,
      'Ciclismo' => Icons.directions_bike,
      'Conduciendo' => Icons.directions_car,
      _ => Icons.help_outline, // por si acaso
    };

    //const imageTrackUrl = 'https://upload.wikimedia.org/wikipedia/en/6/60/No_Picture.jpg';
    //final imageTrackUrl = "${Environment.apiUrl}/files/${track.images.first}";

    var imageTrackUrl = (track.images?.isNotEmpty ?? false)
      ? "${Environment.apiUrl}/files/tracks/${track.images!.first}"
      : 'https://upload.wikimedia.org/wikipedia/en/6/60/No_Picture.jpg';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
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
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.3,
                  height: double.infinity, // o fija si sabes el alto
                  child: Image.network(
                    imageTrackUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported),
                    ),
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
                          const Icon(Icons.route, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              track.name.split('.').first,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      // ⏱ Time ago
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(timeago.format(track.createdAt, locale: 'es')),
                        ],
                      ),

                      // 📏 Distancia (de momento vacío)
                      Row(
                        children: [
                          const Icon(Icons.straighten, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text('${((double.tryParse(track.distance) ?? 0.0) / 1000).toStringAsFixed(2)} km'),
                          const SizedBox(width: 15,),
                          const Icon(Icons.terrain, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text('${((double.tryParse(track.elevationGain) ?? 0.0)).toStringAsFixed(0)} m'),
                          const SizedBox(width: 15,),
                          Icon(icon, size: 16, color: Colors.grey),
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