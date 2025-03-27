import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ladamadelcanchoapp/config/constants/environment.dart';
import 'package:ladamadelcanchoapp/presentation/providers/auth/auth_provider.dart';

class PruebaScreen extends ConsumerWidget {

  static const name = 'prueba-screen';

  const PruebaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final auth = ref.watch(authProvider);
    final imageUrl = "${Environment.apiUrl}/files/${auth.user?.image}";

    return Scaffold(
      appBar: AppBar(
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

          const SizedBox()
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [


            (auth.isAuthenticated) ?

            Column(

              children: [

                ClipOval(
                  child: Image.network(
                    imageUrl,
                    width: 100, // Tamaño de la imagen
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.person,
                      size: 90,
                      color: Colors.grey,
                    ), // 🔥 Si la imagen no carga, muestra un ícono
                  ),
                ),

                const SizedBox(height: 40),


                SizedBox(
                  height: 80,
                  child: Column(
                    children: [
                      Text(auth.user!.fullname),
                    ],
                  ),
                ),
              ],
            ) 
            
            : const SizedBox(),

            
            
            (!auth.isAuthenticated) 
            
              ? SizedBox(
                  width: 200,
                  height: 50,
                  child: FilledButton.tonalIcon(

                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.green.shade800), // Cambia el color de fondo
                      foregroundColor: WidgetStateProperty.all(Colors.white), // Cambia el color del texto
                    ),
  
                    onPressed: () {
                      
                      GoRouter.of(context).push('/login');
                      
                    },
                    label: const Text('Login', style: TextStyle(fontSize: 20)),
                  ),
                )
              : SizedBox(
                  width: 200,
                  height: 50,
                  child: FilledButton.tonalIcon(

                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.red.shade800), // Cambia el color de fondo
                      foregroundColor: WidgetStateProperty.all(Colors.white), // Cambia el color del texto
                    ),

                    onPressed: () {
                      
                      ref.read(authProvider.notifier).logout();
                      
                    },
                    label: const Text('Logout', style: TextStyle(fontSize: 20)),
                  ),
                ),

            const SizedBox(height: 10,),



            SizedBox(
              width: 200,
              height: 50,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  GoRouter.of(context).push('/protegida');
                },
                label: const Text('Protegida', style: TextStyle(fontSize: 20)),
              ),
            ),

            const SizedBox(height: 10,),
        
            SizedBox(
              width: 200,
              height: 50,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  GoRouter.of(context).push('/no-protegida');
                },
                label: const Text('No protegida', style: TextStyle(fontSize: 20)),
              ),
            ),
        
          ],
        ),
      ),
    );
  }
}