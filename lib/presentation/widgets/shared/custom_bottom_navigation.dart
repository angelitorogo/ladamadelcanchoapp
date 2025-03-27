import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomBottomNavigation extends StatelessWidget {
  const CustomBottomNavigation({super.key});

  // funcion para obtener el index actual de la vista
  int getCurrentIndex(BuildContext context) {

    final String location = GoRouterState.of(context).matchedLocation;

    switch (location) {
      case '/':
        return 0;
      case '/map':
        return 1;
      case '/config':
        return 2;
      default:
        return 0;
    }
  }

  // funcion para navegar a una view u otra dependiendo del index seleccionado
  void onItemTapped(BuildContext context, int index) {

    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/map');
        break;
      case 2:
        context.go('/config');
        break;
    }

  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      elevation: 0,
      currentIndex: getCurrentIndex(context), // para marcar el index actual, y que resalte en el bottomNavigation
      onTap: (index) => onItemTapped(context, index),  // onTap es el evento que se dispara cuando se selecciona un item. 'index' es su indice.
      items: const[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map),
          label: 'Mapa'
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Configuracion'
        ),

      ]
    );
  }
}