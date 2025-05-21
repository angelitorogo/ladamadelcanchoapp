

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/domain/entities/user.dart';
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
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>(); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 0,
        title: Text(widget.user.fullname),
      ),
      body: const Placeholder(),
      drawer: SideMenu(scaffoldKey: scaffoldKey)
    );
  }
}

