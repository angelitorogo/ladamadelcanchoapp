import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ladamadelcanchoapp/config/constants/environment.dart';
import 'package:ladamadelcanchoapp/infraestructure/inputs/inputs.dart';
import 'package:ladamadelcanchoapp/infraestructure/utils/secure_storage_helper.dart';
import 'package:ladamadelcanchoapp/presentation/extra/check_connectivity.dart';
import 'package:ladamadelcanchoapp/presentation/providers/auth/auth_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/forms/login_notifier.dart';
import 'package:ladamadelcanchoapp/presentation/providers/track/track_list_provider.dart';
import 'package:ladamadelcanchoapp/presentation/widgets/widgets.dart';
import 'package:local_auth/local_auth.dart';

class LoginScreen extends ConsumerWidget {
  static const name = 'login-screen';

  const LoginScreen({super.key});

  

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: _LoginView(),
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Image.asset(
                'assets/images/icono.png',
                width: 200, // Opcional: tamaño deseado
                height: 200,
                fit: BoxFit.contain, // O BoxFit.cover, según prefieras
              ),
              const SizedBox(height: 40),
              _LoginForm(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}


class _LoginForm extends ConsumerWidget {

 _LoginForm();

  final LocalAuthentication auth = LocalAuthentication();


  Future<void> _checkBiometricAndLogin(WidgetRef ref, BuildContext context) async {
    
    // Instancia de LocalAuthentication (si no la tienes global)
    final auth = LocalAuthentication();

    // Verificar si el dispositivo puede usar biometría
    final available = await auth.canCheckBiometrics;
    final isDeviceSupported = await auth.isDeviceSupported();

    if (!available || !isDeviceSupported) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La autenticación biométrica no está disponible')),
        );
      }
      return;
    }

    try {
      // Intentar autenticar con biometría
      final authenticated = await auth.authenticate(
        localizedReason: 'Inicia sesión con huella',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true, // Mantiene la autenticación si se va a otra app
        ),
      );

      if (!authenticated) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Autenticación cancelada o fallida')),
          );
        }
        return;
      }

      // Leer credenciales guardadas
      final credentials = await SecureStorageHelper.readCredentials();
      final email = credentials['email'];
      final password = credentials['password'];

      if (email != null && password != null) {
        if (context.mounted) {
          ref.read(authProvider.notifier).login(context, email.trim(), password.trim(), ref);
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se encontraron credenciales guardadas')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al usar huella: $e')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context, WidgetRef ref)  {

    final loginState = ref.watch(loginProvider); //estado
    final loginNotifier = ref.read(loginProvider.notifier); //notifier

    final authState = ref.watch(authProvider); //estado
    final authNotifier = ref.read(authProvider.notifier); //notifier


    ref.listen(authProvider, (previous, next) {
      if (previous?.errorMessage != next.errorMessage && next.errorMessage != null) {
        mostrarAlerta(context, next.errorMessage!);
      }
    });


    return Form(
      autovalidateMode: AutovalidateMode.onUserInteraction, // Validación en tiempo real
      child: Column(
        children: [
          // Email
          CustomTextFormFiled(
            label: 'Correo electrónico',
            prefixIcon: Icons.email,
            onChanged: loginNotifier.emailChanged,
            //initialValue: 'angelitorogo@hotmail.com', //eliminar linea.
            validator: (_) {
              return loginState.emailTouched
                  ? Email.emailErrorMessage(loginState.email.error)
                  : null;
            },
          ),

          const SizedBox(height: 20),

          // Contraseña
          CustomTextFormFiled(
            label: 'Contraseña',
            prefixIcon: Icons.password,
            obscureText: true,
            onChanged: loginNotifier.passwordChanged,
            //x
            //initialValue: 'Rod00gom!', //Eliminar linea
            validator: (_) {
              return loginState.passwordTouched
                  ? Password.passwordErrorMessage(loginState.password.error)
                  : null;
            },
          ),

          const SizedBox(height: 40),

          


          // Botón de login
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  
                  SizedBox(
                    width: 160,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: () async {
                        ref.watch(authProvider.notifier).reset();
                        GoRouter.of(context).go('/');
                      },
                      icon: const Icon(Icons.cancel, size: 25, color: Colors.white),
                      label: const Text('Cancelar', style: TextStyle(fontSize: 17, color: Colors.white)),
                      style: FilledButton.styleFrom(
                        backgroundColor: ColorsPeronalized.cancelColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        //foregroundColor: const Color(0xFFEE7B7B), // Esto asegura que los estados hover/pressed también sean redAccent
                      ),
                    ),
                  ),
              
                  (!authState.isLoading) ?
              
                  SizedBox(
                    width: 160,
                    height: 50,
                    child: FilledButton.tonalIcon(
                  
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                          if (states.contains(WidgetState.disabled)) {
                            return const Color(0xFF566D79); // 🔘 Color cuando está deshabilitado
                          }
                          return ColorsPeronalized.successColor; // 🔥 Color cuando está activo
                        }),
                        foregroundColor: WidgetStateProperty.all(Colors.white), // 🎨 Color del texto e icono
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // 📏 Bordes redondeados
                          ),
                        ),
                        padding: WidgetStateProperty.all(
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                      ),
                  
                      //para no tener que escriboir email y password mientras dure el desarrollo y no deshabilite el boton de login. quitar esto y descomentar lo de abajo
                      onPressed: () async {
                  
                        final hasInternet = await checkAndWarnIfNoInternet(context);
                        if(hasInternet) {


                          //print('${loginState.email.value} ${loginState.password.value}');
                  
                          final result = await authNotifier.login(
                            // ignore: use_build_context_synchronously
                            context,
                            loginState.email.value,
                            loginState.password.value,
                            ref
                          );
              
                          if(result) {
                            final userLogged = ref.read(authProvider).user;
                            //Future.delayed(const Duration(milliseconds: 1000));
                            await ref.read(trackListProvider.notifier).loadTracks(
                              ref,
                              page: 1,
                              append: false,
                              loggedUser: userLogged?.id
                            );

                            loginNotifier.resetForm();
                           
                          } 
                  
                        }
                  
                        
                      
                      },
                  
                      icon: const Icon(Icons.login, size: 25, color: Colors.white,),
                      label: const Text('Login', style: TextStyle(fontSize: 17)),
                    ),
                  )
              
                  :
              
              
                  SizedBox(
                    width: 160,
                    height: 50,
                    child: TextButton(
                      onPressed: null, // 🔒 Deshabilitado mientras carga
                      style: TextButton.styleFrom(
                        backgroundColor: ColorsPeronalized.successColor, // 🔥 Color de fondo
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.all(12), // 📏 Tamaño del botón
                      ),
                      child: const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white, // 🎨 Color del loading
                          strokeWidth: 3, // 📏 Grosor del círculo
                        ),
                      ),
                    ),
                  ),
              
              
                ],
              ),

              const SizedBox( height: 200,),
              
              // 👉 Botón de huella
              GestureDetector(
                onTap: () => _checkBiometricAndLogin(ref, context),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer, // azul claro
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.fingerprint,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            ],
          )

          
                    
        
        ],
      ),
    );
  }

  void mostrarAlerta(BuildContext context, String mensaje) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog( // ⬅ Usamos `Dialog` para más control
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: SizedBox(
            width: 300, // ⬅ Define el ancho de la alerta
            height: 300,
            child: AlertDialog(
              titlePadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              title: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: ColorsPeronalized.cancelColor, size: 28),
                  SizedBox(height: 10),
                  Text('Alerta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Text(
                mensaje,
                textAlign: TextAlign.center, // 🔥 Centra el texto
                style: const TextStyle(fontSize: 17),
              ),
              actions: [
                Center(
                  child: SizedBox(
                    width: 150,
                    height: 50,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        backgroundColor: ColorsPeronalized.cancelColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
  }



  
}
