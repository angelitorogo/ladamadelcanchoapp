import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ladamadelcanchoapp/config/menu/menu_items.dart';
import 'package:ladamadelcanchoapp/presentation/extra/check_connectivity.dart';
import 'package:ladamadelcanchoapp/presentation/providers/auth/auth_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/pendings/pending_tracks_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/track/track_list_provider.dart';

class SideMenu extends ConsumerStatefulWidget {

  final GlobalKey<ScaffoldState> scaffoldKey; //tiene que recibir el key del scaffold padre, para tener la referencia del sacaffold.

  const SideMenu({super.key, required this.scaffoldKey});

  @override
  ConsumerState<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends ConsumerState<SideMenu> {

  int navDrawerIndex = 0; // para saber que opcion del menu esta seleccionada

  @override
  Widget build(BuildContext context) {

    final auth = ref.watch(authProvider);

    final hasNotch = MediaQuery.of(context).viewPadding.top > 35; //saber el espacio que hay desde el borde superior hasta despues del notch, si tuviera mas de 35px es que tiene notch
    

    final appMenuItems = <MenuItem>[
      const MenuItem(
        title: 'Inicio',
        link: '/',
        icon: Icons.home
      ),
      const MenuItem(
        title: 'Mapa',
        link: '/map',
        icon: Icons.smart_button_outlined
      ),

      const MenuItem(
        title: 'Configuración',
        link: '/config',
        icon: Icons.credit_card
      ),

      const MenuItem(
        title: 'Tracks Pendientes',
        link: '/pending-tracks',
        icon: Icons.track_changes
      ),

      const MenuItem(
        title: 'Grabar Track',
        link: '/track-map',
        icon: Icons.save_as
      ),

      MenuItem(
        title: 'Distancia',
        link: '/distance',
        icon: Icons.space_bar,
        onTap: (ref) {
          final direction = ref.read(trackListProvider).direction;
          if(direction == 'asc') {
            ref.read(trackListProvider.notifier).changeOrdersAndDirection('distance', 'desc');
          } else {
            ref.read(trackListProvider.notifier).changeOrdersAndDirection('distance', 'asc');
          }
        }
      ),
      MenuItem(
        title: 'Desnivel',
        link: '/desnivel',
        icon: Icons.terrain,
        onTap: (ref) {
          final direction = ref.read(trackListProvider).direction;
          if(direction == 'asc') {
            ref.read(trackListProvider.notifier).changeOrdersAndDirection('elevation_gain', 'desc');
          } else {
            ref.read(trackListProvider.notifier).changeOrdersAndDirection('elevation_gain', 'asc');
          }
        }
      ),

      MenuItem(
        title: 'Fecha',
        link: '/date',
        icon: Icons.date_range,
        onTap: (ref) {
          final direction = ref.read(trackListProvider).direction;
          if(direction == 'asc') {
            ref.read(trackListProvider.notifier).changeOrdersAndDirection('created_at', 'desc');
          } else {
            ref.read(trackListProvider.notifier).changeOrdersAndDirection('created_at', 'asc');
          }
        }
      ),

      (auth.isAuthenticated) ?

      MenuItem(
        title: 'Salir',
        icon: Icons.logout,
        onTap: (ref) async { // ✅ Pasa `ref` correctamente
          final hasInternet = await checkAndWarnIfNoInternet(context);
          if(hasInternet) {
            ref.read(authProvider.notifier).logout(ref);
          }
          
        },
      ) :

      const MenuItem(
        title: 'Login',
        icon: Icons.login,
        link: '/login',
      ),

      const MenuItem(
        title: 'Registro',
        icon: Icons.person_add,
        link: '/register',
      )

    ];

    return NavigationDrawer(
      selectedIndex: navDrawerIndex,
      onDestinationSelected: (value) {
        setState(() {
          navDrawerIndex = value;
        });



        final menuItem = appMenuItems[value];

        if (menuItem.onTap != null) {
          menuItem.onTap!(ref); // ✅ Ejecuta la función si existe
        } else if (menuItem.link != null) {
          context.push(menuItem.link!); // ✅ Solo navega si hay un link
        }

        widget.scaffoldKey.currentState?.closeDrawer();  // ya podriamos cerrar el side menu, cuando naveguemos a un item

      },
      children: [

        Padding(
          padding: EdgeInsets.fromLTRB(28, hasNotch ? 0 : 20, 16, 10), // en el padding top comprobamos si tiene notch o no, y asignamos o 0 o 20px de padding
          child: const Text('Principal'),
        ),

        ...appMenuItems
        .sublist(0,3)
          .map( (item) => NavigationDrawerDestination(
            icon: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Icon(item.icon),
            ),
            label: Text(item.title)
          ),
        ),

        const Padding(
          padding: EdgeInsets.fromLTRB(28, 5, 28, 0),
          child: Divider(),
        ),

        Padding(
          padding: EdgeInsets.fromLTRB(28, hasNotch ? 0 : 20, 16, 10), // en el padding top comprobamos si tiene notch o no, y asignamos o 0 o 20px de padding
          child: const Text('Tracks'),
        ),

        ...appMenuItems.sublist(3, 5).map((item) {
          if (item.title == 'Tracks Pendientes') {
            final pendingTracks = ref.watch(pendingTracksProvider);
            final hasPendings = pendingTracks.isNotEmpty;

            return NavigationDrawerDestination(
              icon: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Icon(item.icon),
              ),
              label: Row(
                children: [
                  Text(item.title),
                  const SizedBox(width: 6),
                  if (hasPendings)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        pendingTracks.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }

          // Otros ítems normales
          return NavigationDrawerDestination(
            icon: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Icon(item.icon),
            ),
            label: Text(item.title),
          );
        }),



        const Padding(
          padding: EdgeInsets.fromLTRB(28, 5, 28, 0),
          child: Divider(),
        ),

        Padding(
          padding: EdgeInsets.fromLTRB(28, hasNotch ? 0 : 20, 16, 10), // en el padding top comprobamos si tiene notch o no, y asignamos o 0 o 20px de padding
          child: const Text('Ordenar tracks por:'),
        ),

        ...appMenuItems
        .sublist(5,6)
          .map( (item) => NavigationDrawerDestination(
            icon: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Icon(item.icon),
            ),
            label: Text(item.title)
          ),
        ),

        ...appMenuItems
        .sublist(6,7)
          .map( (item) => NavigationDrawerDestination(
            icon: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Icon(item.icon),
            ),
            label: Text(item.title)
          ),
        ),

        ...appMenuItems
        .sublist(7,8)
          .map( (item) => NavigationDrawerDestination(
            icon: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Icon(item.icon),
            ),
            label: Text(item.title)
          ),
        ),

         const Padding(
          padding: EdgeInsets.fromLTRB(28, 5, 28, 0),
          child: Divider(),
        ),


        ...appMenuItems
        .sublist(8,9)
          .map( (item) => NavigationDrawerDestination(
            //enabled: false,
            icon: Icon(item.icon),
            label: Text(item.title)
          ),
        ),


        if(!auth.isAuthenticated)
        ...appMenuItems
        .sublist(9)
          .map( (item) => NavigationDrawerDestination(
            //enabled: false,
            icon: Icon(item.icon),
            label: Text(item.title)
          ),
        ),

      ],
    );
  }
}