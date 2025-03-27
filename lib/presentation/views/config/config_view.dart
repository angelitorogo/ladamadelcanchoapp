import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ladamadelcanchoapp/config/constants/environment.dart';
import 'package:ladamadelcanchoapp/presentation/providers/auth/auth_provider.dart';


class ConfigView extends ConsumerWidget {

  static const name = 'config-view';

  const ConfigView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    final auth = ref.watch(authProvider);
    final imageUrl = "${Environment.apiUrl}/files/${auth.user?.image}";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        actions: [

          (auth.isAuthenticated) ?
          
          GestureDetector(
            onTap: () {
              GoRouter.of(context).push('/profile');
            },
            child: SizedBox(
              height: 40,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipOval(
                  child: Image.network(
                    imageUrl,
                    width: 40, // Tamaño de la imagen
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.grey,
                    ), // 🔥 Si la imagen no carga, muestra un ícono
                  ),
                ),
              ),
            ),
          )

          :

          SizedBox(
            height: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: IconButton.filledTonal(
                onPressed: () {
                  GoRouter.of(context).push('/login');
                }, 
                icon: const Icon(Icons.login)
              ),
            ),
          ),

        ],
      ),
        
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Config view')
          ],
        ),
      ),
    );
  }
}