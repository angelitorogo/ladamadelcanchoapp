import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formz/formz.dart';
import 'package:ladamadelcanchoapp/config/constants/environment.dart';
import 'package:ladamadelcanchoapp/infraestructure/inputs/inputs.dart';
import 'package:ladamadelcanchoapp/presentation/extra/check_connectivity.dart';
import 'package:ladamadelcanchoapp/presentation/providers/auth/auth_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/forms/profile_provider.dart';
import 'package:ladamadelcanchoapp/presentation/widgets/alerts/alerts.dart';
import 'package:ladamadelcanchoapp/presentation/widgets/inputs/custom_text_form_filed.dart';
import 'dart:io';

class ProfileScreen extends ConsumerWidget {
  static const name = 'profile-screen';

  const ProfileScreen({super.key});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider); // Estado de autenticación
    final authNotifier = ref.read(authProvider.notifier); //notifier
    final profileState = ref.watch(profileProvider);
    final profileNotifier = ref.read(profileProvider.notifier);

    
    
    String? userImage = profileState.image;

    if( userImage != null && !File(userImage).existsSync()) {
      userImage = null;
    }

    final String imageUrl = "${Environment.apiUrl}/files/${authState.user?.image}";

    final colors = Theme.of(context).colorScheme;

    ref.listen<AuthState>(authProvider, (previous, next) {

      if (previous?.errorMessage != next.errorMessage && next.errorMessage != null) {
        Future.microtask(() {
          if (context.mounted && ModalRoute.of(context)?.isCurrent == true) {
            mostrarAlerta(context, next.errorMessage!, colors.error);
          }
        });
      }

      if (previous?.user != next.user && next.user != null) {
        Future.microtask(() {
          if (context.mounted && ModalRoute.of(context)?.isCurrent == true) {
            mostrarAlertaSuccess(context, "Perfil actualizado con éxito");
          }
        });
      }
    });

  


    return PopScope(
      canPop: true, // Permite el pop
      // ignore: deprecated_member_use
      onPopInvoked: (didPop) {
        if (didPop) {
          // Resetea el estado antes de salir
          ref.read(profileProvider.notifier).resetForm(authState.user!);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Perfil'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: SingleChildScrollView(
            child: Column(
              children: [
      
                // 🔥 Imagen de perfil con icono de cámara
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // 📌 Imagen del perfil
                    ClipOval(
                      child: GestureDetector(
                        onTap: () => _showImagePickerDialog(context, ref),
                        child: profileState.isNewImage
                            ? Image.file(
                                File(userImage!), // ✅ Muestra la imagen nueva seleccionada antes de enviarla
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                imageUrl, // ✅ Si no hay nueva imagen, muestra la del backend
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.person,
                                  size: 90,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),

                    // 📌 Icono de cámara en la esquina inferior derecha
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color:  colors.onPrimaryFixedVariant, // Color de fondo del icono
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2), // Borde blanco alrededor del icono
                        ),
                        padding: const EdgeInsets.all(3),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20, // Tamaño del icono
                        ),
                      ),
                    ),
                  ],
                ),

      
                const SizedBox(height: 20),
      
                Form(
                  autovalidateMode: AutovalidateMode.onUserInteraction, // Validación en tiempo real
                  child: Column(
                    children: [
                      // Fullname
                      CustomTextFormFiled(
                        label: 'Nombre Completo',
                        prefixIcon: Icons.person,
                        initialValue: profileState.fullname.value,
                        onChanged: profileNotifier.fullnameChanged,
                        validator: (_) => Fullname.fullnameErrorMessage(profileState.fullname.error),
                      ),
                      const SizedBox(height: 20),
            
                      // Email
                      CustomTextFormFiled(
                        label: 'Correo electrónico',
                        prefixIcon: Icons.mail,
                        initialValue: profileState.email.value,
                        onChanged: profileNotifier.emailChanged,
                        validator: (_) {
                          return profileState.emailTouched
                              ? Email.emailErrorMessage(profileState.email.error)
                              : null;
                        },
                      ),
                      const SizedBox(height: 20),
            
                      // Role
                      CustomTextFormFiled(
                        label: 'Rol',
                        prefixIcon: Icons.work,
                        initialValue: profileState.role.value,
                        enabled: false,
                        validator: (_) => Role.roleErrorMessage(profileState.role.error),
                      ),
                      const SizedBox(height: 20),
            
                      // Telephone
                      CustomTextFormFiled(
                        label: 'Teléfono',
                        prefixIcon: Icons.phone,
                        initialValue: profileState.telephone.value,
                        onChanged: profileNotifier.telephoneChanged,
                        validator: (_) {
                          final error = profileState.telephone.displayError;
                          return error != null 
                              ? Telephone.telephoneErrorMessage(error) 
                              : null;
                        },
                      ),
                      const SizedBox(height: 20),
            
                      (!authState.isLoading)
                          ? SizedBox(
                              width: 160,
                              height: 50,
                              child: ElevatedButton(
                                style: ButtonStyle(
                                  backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                                    if (states.contains(WidgetState.disabled)) {
                                      return const Color(0xFF566D79);
                                    }
                                    return Colors.green;
                                  }),
                                  foregroundColor: WidgetStateProperty.all(Colors.white),
                                  shape: WidgetStateProperty.all(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  padding: WidgetStateProperty.all(
                                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  ),
                                ),

                                onPressed: authState.isLoading ||
                                  profileState.status != FormzSubmissionStatus.success
                                ? null
                                : () async {
                                    final hasInternet = await checkAndWarnIfNoInternet(context);
                                    if(hasInternet) {
                                      await authNotifier.updateUser(
                                        // ignore: use_build_context_synchronously
                                        profileState, ref, context
                                      );
                                    }

                                    
                                  },
                                child: const Text('Actualizar'),
                              ),
                            )
                          : SizedBox(
                              width: 160,
                              height: 50,
                              child: TextButton(
                                onPressed: null,
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.all(12),
                                ),
                                child: const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ) 
                )
              ],
            ),
          ),
        ),
      
        /*
        floatingActionButton: FloatingActionButton(
          onPressed: () => showDebugDialog(context, ref),
          child: const Icon(Icons.bug_report),
        ),
        */
      
      ),
    );
  }

  


}

void _showImagePickerDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Seleccionar imagen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.of(ctx).pop();
                ref.read(profileProvider.notifier).selectImage(fromCamera: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Seleccionar de galería'),
              onTap: () {
                Navigator.of(ctx).pop();
                ref.read(profileProvider.notifier).selectImage(fromCamera: false);
              },
            ),
          ],
        ),
      );
    },
  );
}
