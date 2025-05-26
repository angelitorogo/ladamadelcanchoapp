
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ladamadelcanchoapp/config/constants/environment.dart';
import 'package:ladamadelcanchoapp/domain/entities/user.dart';
import 'package:ladamadelcanchoapp/presentation/providers/track/track_list_provider.dart';
import 'package:ladamadelcanchoapp/presentation/screens/tracks/user_tracks_screen.dart';
import 'package:ladamadelcanchoapp/presentation/widgets/sidemenu/side_menu.dart';

class UserScreen extends ConsumerStatefulWidget {
  final UserEntity user;
  static const name = 'user-screen';

  const UserScreen({super.key, required this.user});

  @override
  ConsumerState<UserScreen> createState() => _UserScreenState();
}


class _UserScreenState extends ConsumerState<UserScreen> {

  
  

  @override
  Widget build(BuildContext context) {

  int totalUserTracks = ref.watch(trackListProvider).totalTracks;

    return Scaffold(
      drawer: SideMenu(scaffoldKey: GlobalKey<ScaffoldState>()),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 0,
        title: Text(widget.user.fullname),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Data(user: widget.user),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                context.pushNamed(
                    UserTracksScreen.name,
                    extra: widget.user,
                  );
              },
              icon: const Icon(Icons.list),
              label: Text('Mostrar rutas ($totalUserTracks)'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Data extends StatelessWidget {
  final UserEntity user;

  const _Data({required this.user});

  @override
  Widget build(BuildContext context) {
    final String imageUrl = "${Environment.apiUrl}/files/${user.image}";

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: Container(
            width: 100,
            height: 100,
            color: Colors.grey[300],
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.person, size: 50, color: Colors.grey),
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _UserInfoRow(label: 'Nombre', value: user.fullname),
                const SizedBox(height: 10),
                _UserInfoRow(label: 'Email', value: user.email),
                const SizedBox(height: 10),
                _UserInfoRow(label: 'Rol', value: user.role),
                if (user.telephone != null && user.telephone!.isNotEmpty)
                  Column(
                    children: [
                      const SizedBox(height: 10),
                      _UserInfoRow(label: 'Teléfono', value: user.telephone!),
                    ],
                  )
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UserInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _UserInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(Icons.info_outline, size: 16, color: colors.primary),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
