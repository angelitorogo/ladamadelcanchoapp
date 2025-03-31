import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/infraestructure/inputs/inputs.dart';
import 'package:ladamadelcanchoapp/presentation/providers/auth/auth_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/forms/login_notifier.dart';
import 'package:ladamadelcanchoapp/presentation/widgets/widgets.dart';

class LoginScreen extends StatelessWidget {
  static const name = 'login-screen';

  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: _LoginView(),
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 40),
              FlutterLogo(size: 200),
              SizedBox(height: 10),
              _LoginForm(),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}


class _LoginForm extends ConsumerWidget {
  const _LoginForm();

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final loginState = ref.watch(loginProvider); //estado
    final loginNotifier = ref.read(loginProvider.notifier); //notifier

    final authState = ref.watch(authProvider); //estado
    final authNotifier = ref.read(authProvider.notifier); //notifier

    final colors = Theme.of(context).colorScheme;

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
            initialValue: 'angelitorogo@hotmail.com', //eliminar linea.
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
            initialValue: 'Rod00gom!', //Eliminar linea
            validator: (_) {
              return loginState.passwordTouched
                  ? Password.passwordErrorMessage(loginState.password.error)
                  : null;
            },
          ),

          const SizedBox(height: 20),

          (!authState.isLoading) ?


          // Botón de login
          SizedBox(
            width: 150,
            height: 50,
            child: FilledButton.tonalIcon(

              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(WidgetState.disabled)) {
                    return const Color(0xFF566D79); // 🔘 Color cuando está deshabilitado
                  }
                  return colors.onPrimaryFixedVariant; // 🔥 Color cuando está activo
                }),
                foregroundColor: WidgetStateProperty.all(Colors.white), // 🎨 Color del texto e icono
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), // 📏 Bordes redondeados
                  ),
                ),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),

              //para no tener que escriboir email y password mientras dure el desarrollo y no deshabilite el boton de login. quitar esto y descomentar lo de abajo
              onPressed: () async {
                      await authNotifier.login(
                        context,
                        loginState.email.value,
                        loginState.password.value,
                        ref
                      );
                    },

              /*
              onPressed: authState.isLoading ||
                      loginState.status != FormzSubmissionStatus.success
                  /? null
                  : () async {
                      await authNotifier.login(
                        context,
                        loginState.email.value,
                        loginState.password.value,
                      );
                    },
              */
              icon: const Icon(Icons.login, size: 30, color: Colors.white,),
              label: const Text('Login', style: TextStyle(fontSize: 17)),
            ),
          )

          :


          SizedBox(
            width: 150,
            height: 50,
            child: TextButton(
              onPressed: null, // 🔒 Deshabilitado mientras carga
              style: TextButton.styleFrom(
                backgroundColor: colors.onPrimaryFixedVariant, // 🔥 Color de fondo
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
                borderRadius: BorderRadius.circular(15),
              ),
              title: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 28),
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
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
