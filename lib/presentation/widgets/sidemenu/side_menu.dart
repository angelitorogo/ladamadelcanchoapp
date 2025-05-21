import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ladamadelcanchoapp/config/menu/menu_items.dart';
import 'package:ladamadelcanchoapp/presentation/extra/check_connectivity.dart';
import 'package:ladamadelcanchoapp/presentation/providers/auth/auth_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/pendings/pending_tracks_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/side_menu/side_menu_state_provider.dart';
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
    final direction = ref.watch(trackListProvider).direction;
    final order = ref.watch(trackListProvider).orderBy;
    final iconOrder = direction == 'asc' ? Icons.trending_up : Icons.trending_down;

    final sideMenuState = ref.watch(sideMenuStateProvider);
    final sideMenuNotifier = ref.read(sideMenuStateProvider.notifier);

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

      const MenuItem(
        title: 'Salir',
        icon: Icons.logout,
        
      ),

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
          menuItem.onTap!(ref);
        } else if (menuItem.link != null) {
          context.push(menuItem.link!);
        }

        widget.scaffoldKey.currentState?.closeDrawer();
      },
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height - 30,
          child: Column(
            children: [

              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('La Dama del Cancho', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),

              // SECCIÓN SCROLLABLE CON TODAS LAS EXPANSIONTILES
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      /// --- PRINCIPAL ---
                      ExpansionTile(
                        initiallyExpanded: sideMenuState.isPrincipalExpanded,
                        onExpansionChanged: (expanded) {
                          sideMenuNotifier.setPrincipalExpanded(expanded);
                        },
                        title: const Text('Principal'),
                        childrenPadding: const EdgeInsets.only(left: 12),
                        tilePadding: const EdgeInsets.fromLTRB(28, 0, 16, 0),
                        children: [
                          ListTile(
                            leading: Icon(appMenuItems[0].icon),
                            title: Text(appMenuItems[0].title),
                            onTap: () {
                              context.go(appMenuItems[0].link!);
                              widget.scaffoldKey.currentState?.closeDrawer();
                            },
                          ),
                          ListTile(
                            leading: Icon(appMenuItems[1].icon),
                            title: Text(appMenuItems[1].title),
                            onTap: () {
                              context.go(appMenuItems[1].link!);
                              widget.scaffoldKey.currentState?.closeDrawer();
                            },
                          ),
                          ListTile(
                            leading: Icon(appMenuItems[2].icon),
                            title: Text(appMenuItems[2].title),
                            onTap: () {
                              context.go(appMenuItems[2].link!);
                              widget.scaffoldKey.currentState?.closeDrawer();
                            },
                          ),
                        ],
                      ),

                      /// --- TRACKS ---
                      ExpansionTile(
                        initiallyExpanded: sideMenuState.isTracksExpanded,
                        onExpansionChanged: (expanded) {
                          sideMenuNotifier.setTracksExpanded(expanded);
                        },
                        title: const Text('Tracks'),
                        childrenPadding: const EdgeInsets.only(left: 12),
                        tilePadding: const EdgeInsets.fromLTRB(28, 0, 16, 0),
                        children: [
                          Builder(
                            builder: (context) {
                              final pendingTracks = ref.watch(pendingTracksProvider);
                              final hasPendings = pendingTracks.isNotEmpty;

                              return ListTile(
                                leading: Icon(appMenuItems[3].icon),
                                title: Row(
                                  children: [
                                    const Text('Tracks Pendientes'),
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
                                onTap: () {
                                  context.push(appMenuItems[3].link!);
                                  widget.scaffoldKey.currentState?.closeDrawer();
                                },
                              );
                            },
                          ),
                          ListTile(
                            leading: Icon(appMenuItems[4].icon),
                            title: Text(appMenuItems[4].title),
                            onTap: () {
                              context.push(appMenuItems[4].link!);
                              widget.scaffoldKey.currentState?.closeDrawer();
                            },
                          ),
                        ],
                      ),

                      /// --- ORDENAR TRACKS POR ---
                      ExpansionTile(
                        initiallyExpanded: sideMenuState.isOrderExpanded,
                        onExpansionChanged: (expanded) {
                          sideMenuNotifier.setOrderExpanded(expanded);
                        },
                        title: const Text('Ordenar tracks por:'),
                        childrenPadding: const EdgeInsets.only(left: 12),
                        tilePadding: const EdgeInsets.fromLTRB(28, 0, 16, 0),
                        children: [
                          ListTile(
                            leading: Icon(appMenuItems[5].icon),
                            title: const Text('Distancia'),
                            trailing: order == 'distance' ? Icon(iconOrder, size: 20) : null,
                            onTap: () {
                              appMenuItems[5].onTap?.call(ref);
                              widget.scaffoldKey.currentState?.closeDrawer();
                            },
                          ),
                          ListTile(
                            leading: Icon(appMenuItems[6].icon),
                            title: const Text('Desnivel'),
                            trailing: order == 'elevation_gain' ? Icon(iconOrder, size: 20) : null,
                            onTap: () {
                              appMenuItems[6].onTap?.call(ref);
                              widget.scaffoldKey.currentState?.closeDrawer();
                            },
                          ),
                          ListTile(
                            leading: Icon(appMenuItems[7].icon),
                            title: const Text('Fecha'),
                            trailing: order == 'created_at' ? Icon(iconOrder, size: 20) : null,
                            onTap: () {
                              appMenuItems[7].onTap?.call(ref);
                              widget.scaffoldKey.currentState?.closeDrawer();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(),

              /// --- SECCIÓN INFERIOR: LOGIN / REGISTRO / SALIR ---
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 12, bottom: 20),
                child: auth.isAuthenticated
                    ? ListTile(
                        leading: Icon(appMenuItems[8].icon),
                        title: Text(appMenuItems[8].title),
                        onTap: () async {
                          final hasInternet = await checkAndWarnIfNoInternet(context);
                          if (hasInternet) {
                            ref.read(authProvider.notifier).logout(ref);
                            widget.scaffoldKey.currentState?.closeDrawer();
                          }
                        },
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                              leading: Icon(appMenuItems[9].icon),
                              title: Text(
                                appMenuItems[9].title,
                                style: const TextStyle(fontSize: 14),
                              ),
                              onTap: () {
                                context.push(appMenuItems[9].link!);
                                widget.scaffoldKey.currentState?.closeDrawer();
                              },
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                              leading: Icon(appMenuItems[10].icon),
                              title: Text(
                                appMenuItems[10].title,
                                style: const TextStyle(fontSize: 14),
                              ),
                              onTap: () {
                                context.push(appMenuItems[10].link!);
                                widget.scaffoldKey.currentState?.closeDrawer();
                              },
                            ),
                          ),
                        ],
                      ),

              ),
            ],
          ),
        )
      ],
    );
  }
}