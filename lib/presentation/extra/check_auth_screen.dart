import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ladamadelcanchoapp/infraestructure/utils/global_cookie_jar.dart';
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
      _checkAuth();
      _checkAuthExpired();
      _initialized = true;
    }
  }

  Future<void> _checkAuth() async {

    final auth = ref.read(authProvider);

    if (!auth.isAuthenticated && mounted)  {
      Future.delayed(Duration.zero, () {
        if(mounted) {
          GoRouter.of(context).go('/login');
        } 
      });
    }

  }

  Future<void> _checkAuthExpired() async {
    final cookies = await GlobalCookieJar.instance.loadForRequest(Uri.parse('https://cookies.argomez.com'));
    final hasToken = cookies.any((c) => c.name == 'auth_token');


    if (!hasToken && mounted) {
      Future.delayed(Duration.zero, () {
        showDialog(
          // ignore: use_build_context_synchronously
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: SizedBox(
                width: 300,
                height: 300,
                child: AlertDialog(
                  titlePadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  title: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 28),
                      SizedBox(height: 10),
                      Text('Sesión expirada', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  content: const Text(
                    'Tu sesión ha caducado.\nPor favor inicia sesión nuevamente.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17),
                  ),
                  actions: [
                    Center(
                      child: SizedBox(
                        width: 150,
                        height: 50,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            GoRouter.of(context).push('/login');
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Text(
                            'Aceptar',
                            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
