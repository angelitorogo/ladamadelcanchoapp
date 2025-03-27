
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ladamadelcanchoapp/presentation/providers/auth/auth_provider.dart';
import 'package:ladamadelcanchoapp/presentation/screens/auth/login_screen.dart';
import 'package:ladamadelcanchoapp/presentation/screens/core/home/home_screen.dart';
import 'package:ladamadelcanchoapp/presentation/screens/core/profile/profile_screen.dart';
import 'package:ladamadelcanchoapp/presentation/screens/map_tracking/map_tracking_screen.dart';
import 'package:ladamadelcanchoapp/presentation/views/config/config_view.dart';
import 'package:ladamadelcanchoapp/presentation/views/home/home_view.dart';
import 'package:ladamadelcanchoapp/presentation/views/map/map_view.dart';

final appRouter = GoRouter(
  initialLocation: '/', 
  routes: [
    // State-Preserving
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => HomeScreen(childView: navigationShell),
      branches: [
        
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) {
                return const HomeView();
              },
            )
        ]),

        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/map',
              builder: (context, state) {
                return const MapView();
              },
            )
        ]),

        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/config',
              builder: (context, state) {
                return const ConfigView();
              },
            )
        ]),
      ]),

      GoRoute(
        path: '/login',
        name: LoginScreen.name,
        builder: (context, state) => const LoginScreen(),
      ),  

      GoRoute(
        path: '/profile',
        name: ProfileScreen.name,
        builder: (context, state) {
          // ✅ Obtenemos el estado de autenticación usando ProviderScope.of()
          final authState = ProviderScope.containerOf(context).read(authProvider);

          // 🔒 Si el usuario NO está autenticado, lo enviamos a /login
          if (!authState.isAuthenticated) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              GoRouter.of(context).go('/login');
            });
            return const SizedBox(); // Devolvemos un widget vacío mientras redirige
          }

          return const ProfileScreen(); // ✅ Si está autenticado, accede a la ruta
        },
      ),

      GoRoute(
        path: '/track-map',
        name: MapTrackingScreen.name,
        builder: (context, state) {
          // ✅ Obtenemos el estado de autenticación usando ProviderScope.of()
          final authState = ProviderScope.containerOf(context).read(authProvider);

          // 🔒 Si el usuario NO está autenticado, lo enviamos a /login
          if (!authState.isAuthenticated) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              GoRouter.of(context).go('/login');
            });
            return const SizedBox(); // Devolvemos un widget vacío mientras redirige
          }

          return const MapTrackingScreen(); // ✅ Si está autenticado, accede a la ruta
        },
      ),


    /*
    GoRoute(
      path: '/login',
      name: LoginScreen.name,
      builder: (context, state) => const LoginScreen(),
    ),  

    GoRoute(
      path: '/core',
      name: PruebaScreen.name,
      builder: (context, state) => const PruebaScreen(),
    ), 

    GoRoute(
      path: '/home',
      name: HomeScreen.name,
      builder: (context, state) => const HomeScreen(),
    ), 
    GoRoute(
      path: '/protegida',
      name: LogadoScreen.name,
      builder: (context, state) {
        // ✅ Obtenemos el estado de autenticación usando ProviderScope.of()
        final authState = ProviderScope.containerOf(context).read(authProvider);

        // 🔒 Si el usuario NO está autenticado, lo enviamos a /login
        if (!authState.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            GoRouter.of(context).go('/login');
          });
          return const SizedBox(); // Devolvemos un widget vacío mientras redirige
        }

        return const LogadoScreen(); // ✅ Si está autenticado, accede a la ruta
      },
    ),

    GoRoute(
      path: '/profile',
      name: ProfileScreen.name,
      builder: (context, state) {
        // ✅ Obtenemos el estado de autenticación usando ProviderScope.of()
        final authState = ProviderScope.containerOf(context).read(authProvider);

        // 🔒 Si el usuario NO está autenticado, lo enviamos a /login
        if (!authState.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            GoRouter.of(context).go('/login');
          });
          return const SizedBox(); // Devolvemos un widget vacío mientras redirige
        }

        return const ProfileScreen(); // ✅ Si está autenticado, accede a la ruta
      },
    ),

    GoRoute(
      path: '/no-protegida',
      name: NoLogadoScreen.name,
      builder: (context, state) => const NoLogadoScreen(),
    ),    
    */


]);


