import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ladamadelcanchoapp/config/constants/environment.dart';
import 'package:ladamadelcanchoapp/domain/entities/track.dart';
import 'package:ladamadelcanchoapp/domain/entities/user.dart';
import 'package:ladamadelcanchoapp/presentation/extra/check_connectivity.dart';
import 'package:ladamadelcanchoapp/presentation/providers/side_menu/side_menu_state_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/track/track_list_provider.dart';
import 'package:ladamadelcanchoapp/presentation/screens/tracks/track-screen.dart';
import 'package:ladamadelcanchoapp/presentation/widgets/sidemenu/side_menu.dart';
import 'package:timeago/timeago.dart' as timeago;

class UserTracksScreen extends ConsumerStatefulWidget {
  static const name = 'user-tracks-screen';

  final UserEntity? user;

  const UserTracksScreen({super.key, required this.user});

  @override
  ConsumerState<UserTracksScreen> createState() => _UserTracksScreenState();
}

class _UserTracksScreenState extends ConsumerState<UserTracksScreen> {
  final ScrollController _scrollController = ScrollController();
  final int limit = 5;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() async {
      final state = ref.read(trackListProvider);
      final notifier = ref.read(trackListProvider.notifier);

      if (_scrollController.hasClients) {
        if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
          if (state.status != TrackListStatus.loading && state.currentPage < state.totalPages) {
            //print('✅ User - carga secundaria...');
            final nextPage = state.currentPage + 1;
            notifier.loadTracks(
              ref,
              limit: limit,
              page: nextPage,
              append: true,
              userId: widget.user?.id,
            );
          }
        }
      }
    });

    Future.microtask(() async {
      ref.read(trackListProvider.notifier).resetState();
      ref.read(trackListProvider.notifier).setLoading();

      //print('✅ User - carga inicial...');
      // ignore: use_build_context_synchronously
      final hasInternet = await checkAndWarnIfNoInternet(context);

      if (hasInternet) {
        await ref.read(trackListProvider.notifier).loadTracks(
          ref,
          limit: limit,
          page: 1,
          append: false,
          userId: widget.user?.id,
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
    final trackState = ref.watch(trackListProvider);

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        await ref.read(trackListProvider.notifier).resetState();
        ref.read(sideMenuStateProvider.notifier).resetUserScreen();
        await ref.read(trackListProvider.notifier).changeOrdersAndDirection(ref, 'created_at', 'desc', null);
        return true;
      },
      child: Scaffold(
        key: scaffoldKey,
        drawer: SideMenu(scaffoldKey: scaffoldKey),
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          scrolledUnderElevation: 0,
          title: Text(widget.user!.fullname),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            final hasInternet = await checkAndWarnIfNoInternet(context);
            if (hasInternet) {
              await ref.read(trackListProvider.notifier).loadTracks(
                ref,
                limit: limit,
                page: 1,
                append: false,
                userId: widget.user?.id,
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
          child: Builder(builder: (_) {
            if (trackState.status == TrackListStatus.loading && trackState.tracks.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView.builder(
              key: const PageStorageKey('trackListScroll'),
              controller: _scrollController,
              itemCount: trackState.tracks.length + 1,
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                if (index == trackState.tracks.length) {
                  return (trackState.status == TrackListStatus.loading &&
                          trackState.tracks.isNotEmpty &&
                          trackState.currentPage < trackState.totalPages)
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : const SizedBox.shrink();
                }

                final track = trackState.tracks[index];

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
                      extra: {'trackIndex': index, 'trackName': track.name},
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                    child: FadeInUp(
                      child: _Card(
                        imageTrackUrl: imageTrackUrl,
                        track: track,
                        icon: icon,
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String imageTrackUrl;
  final Track track;
  final IconData icon;

  const _Card({required this.imageTrackUrl, required this.track, required this.icon});

  @override
  Widget build(BuildContext context) {
    timeago.setLocaleMessages('es', timeago.EsMessages());

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: SizedBox(
        height: 120,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.29,
                height: double.infinity,
                child: Image.network(
                  imageTrackUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  },
                  errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
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
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(timeago.format(track.createdAt, locale: 'es')),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.straighten, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text('${((double.tryParse(track.distance) ?? 0.0)).toStringAsFixed(2)} km'),
                        const SizedBox(width: 15),
                        const Icon(Icons.terrain, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text('${(double.tryParse(track.elevationGain) ?? 0.0).toStringAsFixed(0)} m'),
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
    );
  }
}
