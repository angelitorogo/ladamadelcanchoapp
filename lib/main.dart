import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/config/router/app_router.dart';
import 'package:ladamadelcanchoapp/config/theme/app_theme.dart';
import 'package:intl/date_symbol_data_local.dart';



Future main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  // Ocultar barras de navegación y de estado (modo inmersivo)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await initializeDateFormatting('es_ES', null);   //para poder hacer Text(DateFormat.E('es_ES').format(date)),  en la linea 1282 de track_screen.dart

  runApp(
    const ProviderScope(child: MainApp())
  );
}

class MainApp extends StatelessWidget {
  
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {


    return MaterialApp.router(
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      theme: AppTheme().getTheme(),



    );
  }
}
