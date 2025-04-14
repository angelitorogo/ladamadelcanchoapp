import 'package:flutter/material.dart';
import 'package:ladamadelcanchoapp/presentation/widgets/shared/custom_bottom_navigation.dart';
import 'package:ladamadelcanchoapp/presentation/widgets/sidemenu/side_menu.dart';

class HomeScreen extends StatelessWidget {

  static const name = 'home-screen';

  final Widget childView; // esta sera la vista que se mostrara en el home_screen, dependiendo del BottomNavigationBarItem seleccionado en el bottomNavigationBar
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>(); // ✅ Clave compartida

  HomeScreen({super.key, required this.childView});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      key: scaffoldKey, //con esto cuando se pulsa en un elemento del sidemenu o fuera de esta, se cerrara automaticamente
      body: Center(
        child: childView   // esta sera la vista que se mostrara en el home_screen, dependiendo del BottomNavigationBarItem seleccionado en el bottomNavigationBar
      ),
      bottomNavigationBar: const CustomBottomNavigation(),
      drawer: SideMenu(scaffoldKey: scaffoldKey), //mandamos el key del scaffold al sidemenu
    );
  }
}


