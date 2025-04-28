import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/presentation/providers/auth/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> showDebugDialog(BuildContext context, WidgetRef ref) async {
      final prefs = await SharedPreferences.getInstance();
      final prefsKeys = prefs.getKeys();

      final prefsInfo = prefsKeys.isEmpty
          ? 'No hay preferencias guardadas.'
          : prefsKeys.map((k) => '• $k: ${prefs.get(k)}').join('\n');

      final jar = ref.read(authProvider.notifier).jar();
      final cookies = await jar?.loadForRequest(Uri.parse('https://cookies.argomez.com'));


      final cookiesInfo = cookies?.isEmpty ?? true
        ? 'No hay cookies guardadas.'
        : cookies!.map((c) => '• ${c.name} = ${c.value}').join('\n');

      // Mostramos todo en un AlertDialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Debug info'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🔑 SharedPreferences:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(prefsInfo),
                  const SizedBox(height: 12),
                  const Text('🍪 Cookies:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(cookiesInfo),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
    }