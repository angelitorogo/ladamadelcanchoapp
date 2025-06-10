import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ladamadelcanchoapp/presentation/providers/side_menu/side_menu_state_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/track/track_list_provider.dart';
import 'package:ladamadelcanchoapp/presentation/widgets/sidemenu/side_menu.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final StatefulNavigationShell childView;
  const HomeScreen({super.key, required this.childView});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int currentIndex = 0;

  void onTap(int index) async {
    if (index == 0) {
      ref.read(trackListProvider.notifier).reset();
      ref.read(sideMenuStateProvider.notifier).resetUserScreen();
      ref.read(trackListProvider.notifier).changeOrdersAndDirection(ref, 'created_at', 'desc', null);
      
    }

    widget.childView.goBranch(index,
        initialLocation: index == widget.childView.currentIndex);
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      key: _scaffoldKey,
      drawer: currentIndex == 0
          ? SideMenu(scaffoldKey: _scaffoldKey)
          : null,
      body: widget.childView,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Config'),
        ],
      ),
    );
  }
}
