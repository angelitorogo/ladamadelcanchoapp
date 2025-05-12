
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ladamadelcanchoapp/config/constants/environment.dart';
import 'package:ladamadelcanchoapp/presentation/extra/check_connectivity.dart';
import 'package:ladamadelcanchoapp/presentation/providers/auth/auth_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/track/track_list_provider.dart';
import 'package:ladamadelcanchoapp/presentation/screens/tracks/track-screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class HomeView extends ConsumerStatefulWidget {
  static const name = 'home-view';

  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  final ScrollController _scrollController = ScrollController();
  final int limit = 5;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      final state = ref.read(trackListProvider);
      final notifier = ref.read(trackListProvider.notifier);

      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (state.status != TrackListStatus.loading && state.currentPage < state.totalPages) {
          final nextPage = state.currentPage + 1;
          notifier.loadTracks(
            limit: limit,
            page: nextPage,
            append: true,
            //userId: ref.read(authProvider).user?.id,
          );
        }
      }
    });

    Future.microtask(() async {
      final auth = ref.read(authProvider);
      // ignore: use_build_context_synchronously
      final hasInternet = await checkAndWarnIfNoInternet(context);
      if (hasInternet) {
        await ref.read(trackListProvider.notifier).loadTracks(
              limit: limit,
              page: 1,
              userId: auth.user?.id,
            );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final imageUrl = "${Environment.apiUrl}/files/${auth.user?.image}";
    final trackState = ref.watch(trackListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          (auth.isAuthenticated)
              ? GestureDetector(
                  onTap: () => GoRouter.of(context).push('/profile'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ClipOval(
                      child: Image.network(
                        imageUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.person, size: 40, color: Colors.grey),
                      ),
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: IconButton.filledTonal(
                    onPressed: () => GoRouter.of(context).push('/login'),
                    icon: const Icon(Icons.login),
                  ),
                ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Builder(
          builder: (_) {
            if (trackState.status == TrackListStatus.loading && trackState.tracks.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (trackState.status == TrackListStatus.error && trackState.tracks.isEmpty) {
              return const Center(child: Text('❌ Error al cargar las rutas'));
            }

            if (trackState.tracks.isEmpty) {
              return const Center(child: Text('No hay rutas disponibles.'));
            }

            return RefreshIndicator(
              onRefresh: () async {
                final hasInternet = await checkAndWarnIfNoInternet(context);
                if (hasInternet) {
                  await ref.read(trackListProvider.notifier).loadTracks(
                        limit: limit,
                        page: 1,
                        append: false,
                        userId: auth.user?.id,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Rutas actualizadas'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              child: ListView.builder(
                key: const PageStorageKey('trackListScroll'),
                controller: _scrollController,
                itemCount: trackState.tracks.length + 1,
                physics: const AlwaysScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  if (index == trackState.tracks.length) {
                    return (trackState.currentPage < trackState.totalPages)
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : const SizedBox.shrink();
                  }

                  final track = trackState.tracks[index];
                  timeago.setLocaleMessages('es', timeago.EsMessages());

                  // ⬇️ Tu misma visualización original del track
                  final icon = switch (track.type) {
                    'Senderismo' => Icons.directions_walk,
                    'Ciclismo' => Icons.directions_bike,
                    'Conduciendo' => Icons.directions_car,
                    _ => Icons.help_outline,
                  };

                  final imageTrackUrl = (track.images?.isNotEmpty ?? false)
                      ? "${Environment.apiUrl}/files/tracks/${track.images!.first}"
                      : 'https://upload.wikimedia.org/wikipedia/en/6/60/No_Picture.jpg';

                  return GestureDetector(
                    onTap: () {
                      context.pushNamed(
                        TrackScreen.name,
                        extra: {'trackIndex': index},
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: SizedBox(
                          height: 120,
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius:
                                    const BorderRadius.horizontal(left: Radius.circular(15)),
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.29,
                                  height: double.infinity,
                                  child: Image.network(
                                    imageTrackUrl,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                          child: CircularProgressIndicator(strokeWidth: 2));
                                    },
                                    errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.route,
                                              size: 16, color: Colors.grey),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              track.name.split('.').first,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold, fontSize: 16),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time,
                                              size: 16, color: Colors.grey),
                                          const SizedBox(width: 6),
                                          Text(timeago.format(track.createdAt, locale: 'es')),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.straighten,
                                              size: 16, color: Colors.grey),
                                          const SizedBox(width: 6),
                                          Text(
                                              '${((double.tryParse(track.distance) ?? 0.0) / 1000).toStringAsFixed(2)} km'),
                                          const SizedBox(width: 15),
                                          const Icon(Icons.terrain,
                                              size: 16, color: Colors.grey),
                                          const SizedBox(width: 6),
                                          Text(
                                              '${(double.tryParse(track.elevationGain) ?? 0.0).toStringAsFixed(0)} m'),
                                          const SizedBox(width: 15),
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
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),

      /*
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDebugDialog(context, ref),
        child: const Icon(Icons.bug_report),
      ),
      */
    );
  }
}
