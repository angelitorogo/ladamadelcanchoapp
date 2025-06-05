import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ladamadelcanchoapp/presentation/providers/auth/auth_provider.dart';

class CheckAuthScreen extends ConsumerStatefulWidget {
  final Widget child;
  const CheckAuthScreen({super.key, required this.child});

  @override
  ConsumerState<CheckAuthScreen> createState() => _CheckAuthScreenState();
}

class _CheckAuthScreenState extends ConsumerState<CheckAuthScreen> {

  bool _initialized = false;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      _verifySessionOnStartup();
      _initialized = true;
    }

  }

  Future<void> _verifySessionOnStartup() async {
    var hasToken = false;
    final auth = ref.read(authProvider);
    final jar = await ref.read(authProvider.notifier).jar();
    final cookies = await jar?.loadForRequest(Uri.parse('https://cookies.argomez.com'));    
    
    if(cookies != null) {
      hasToken = cookies.any((c) => c.name == 'auth_token');
    }


    if (hasToken && auth.isAuthenticated) {
      // 👍 tiene auth_token y autenticado, dejamos pasar sin tocar el estado
      return;
    } else {
      Future.delayed(Duration.zero, () {
        if(mounted) {
          GoRouter.of(context).go('/login');
        } 
      });
    }

  }


  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
