import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/infraestructure/inputs/inputs.dart';
import 'package:ladamadelcanchoapp/presentation/extra/check_connectivity.dart';
import 'package:ladamadelcanchoapp/presentation/providers/auth/auth_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/forms/register_notifier.dart';
import 'package:ladamadelcanchoapp/presentation/widgets/alerts/alerts.dart';
import 'package:ladamadelcanchoapp/presentation/widgets/widgets.dart';

class RegisterScreen extends StatelessWidget {

  static const name = 'register-screen';

  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: _RegisterView(),
    );
  }
}

class _RegisterView extends StatelessWidget {
  const _RegisterView();

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
              SizedBox(height: 40),
              _RegisterForm(),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}


class _RegisterForm extends ConsumerWidget {
  const _RegisterForm();

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final registerState = ref.watch(registerProvider); //estado
    final registerNotifier = ref.read(registerProvider.notifier); //notifier

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

          // Nombre completo
          CustomTextFormFiled(
            label: 'Nombre completo',
            prefixIcon: Icons.person_sharp,
            onChanged: registerNotifier.fullnameChanged,
            initialValue: 'Pepe Perez', //eliminar linea.
            validator: (_) {
              return registerState.fullnameTouched
                  ? Fullname.fullnameErrorMessage(registerState.fullname.error)
                  : null;
            },
          ),

          const SizedBox(height: 20),

          // Email
          CustomTextFormFiled(
            label: 'Correo electrónico',
            prefixIcon: Icons.email,
            onChanged: registerNotifier.emailChanged,
            initialValue: 'pepe@pepe.com', //eliminar linea.
            validator: (_) {
              return registerState.emailTouched
                  ? Email.emailErrorMessage(registerState.email.error)
                  : null;
            },
          ),

          const SizedBox(height: 20),

          // Contraseña
          CustomTextFormFiled(
            label: 'Contraseña',
            prefixIcon: Icons.password,
            obscureText: true,
            onChanged: registerNotifier.passwordChanged,
            initialValue: 'Rod00gom!', //Eliminar linea
            validator: (_) {
              return registerState.passwordTouched
                  ? Password.passwordErrorMessage(registerState.password.error)
                  : null;
            },
          ),

          const SizedBox(height: 20),

          // Contraseña
          CustomTextFormFiled(
            label: 'Repite contraseña',
            prefixIcon: Icons.password,
            obscureText: true,
            onChanged: registerNotifier.password2Changed,
            initialValue: 'Rod00gom!', //Eliminar linea
            validator: (_) {
              return registerState.password2Touched
                  ? Password.passwordErrorMessage(registerState.password2.error)
                  : null;
            },
          ),

          const SizedBox(height: 40),

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

              onPressed: () async{

                /*// Validar el formulario  
                print('DATA:');
                print(registerState.fullname.value);
                print(registerState.email.value);
                print(registerState.password.value);
                print(registerState.password2.value);
                */

                if(registerState.password.value != registerState.password2.value) {
                  mostrarAlerta(context, 'Contraseñas no coinciden');
                  return;
                }

                final hasInternet = await checkAndWarnIfNoInternet(context);
                if(hasInternet) {

                  final result = await authNotifier.register(
                    // ignore: use_build_context_synchronously
                    context,
                    registerState.fullname.value,
                    registerState.email.value,
                    registerState.password.value,
                    ref
                  );

                  if (result.success) {
                    // ✅ Registro OK, ya se redirige dentro del notifier
                    if (context.mounted) {
                      mostrarAlertaSuccess(context, result.message!, redirectRoute: '/');
                    }
                  } else {
                    // ❌ Mostrar alerta con mensaje del backend
                    if (context.mounted) {
                      mostrarAlerta(context, result.message!);
                    }
                  }

                }


              },
              
            
            
              
              icon: const Icon(Icons.person_add, size: 30, color: Colors.white,),
              label: const Text('Registro', style: TextStyle(fontSize: 17)),
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

  


  
}
