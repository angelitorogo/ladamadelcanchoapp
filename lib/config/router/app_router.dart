
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:ladamadelcanchoapp/domain/entities/location_point.dart';
import 'package:ladamadelcanchoapp/presentation/extra/check_auth_screen.dart';
import 'package:ladamadelcanchoapp/presentation/screens/auth/login_screen.dart';
import 'package:ladamadelcanchoapp/presentation/screens/core/home/home_screen.dart';
import 'package:ladamadelcanchoapp/presentation/screens/core/profile/profile_screen.dart';
import 'package:ladamadelcanchoapp/presentation/screens/map_tracking/map_tracking_screen.dart';
import 'package:ladamadelcanchoapp/presentation/screens/pending_tracks/pending_tracks_screen.dart';
import 'package:ladamadelcanchoapp/presentation/screens/tracks/preview-track-screen.dart';
import 'package:ladamadelcanchoapp/presentation/screens/tracks/track-screen.dart';
import 'package:ladamadelcanchoapp/presentation/screens/wellcome/wellcome_screen.dart';
import 'package:ladamadelcanchoapp/presentation/views/config/config_view.dart';
import 'package:ladamadelcanchoapp/presentation/views/home/home_view.dart';
import 'package:ladamadelcanchoapp/presentation/views/map/map_view.dart';

final appRouter = GoRouter(
  initialLocation: '/wellcome', 
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
        path: '/wellcome',
        name: WellcomeScreen.name,
        builder: (context, state) => const WellcomeScreen(),
      ),

      GoRoute(
        path: '/login',
        name: LoginScreen.name,
        builder: (context, state) => const LoginScreen(),
      ),  

      GoRoute(
        path: '/profile',
        name: ProfileScreen.name,
        builder: (context, state) {
          return const CheckAuthScreen(child: ProfileScreen());
        },
      ),

      GoRoute(
        path: '/track-map',
        name: MapTrackingScreen.name,
        builder: (context, state) {
          return const CheckAuthScreen(child: MapTrackingScreen());
        },
      ),

      GoRoute(
        path: '/pending-tracks',
        name: PendingTracksScreen.name,
        builder: (context, state) => const PendingTracksScreen(),
      ),
      
      GoRoute(
        path: '/preview-track',
        name: TrackPreviewScreen.name,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final File trackFile = extra['trackFile'];
          final List<LocationPoint> points = extra['points'];
          final int? index = extra['index'];
          return TrackPreviewScreen(trackFile: trackFile, points: points, index: index);
        },
      ),


      GoRoute(
        path: '/track',
        name: TrackScreen.name,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final int trackIndex = extra['trackIndex'];
          return TrackScreen(trackIndex: trackIndex);
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


