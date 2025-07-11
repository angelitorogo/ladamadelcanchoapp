import 'dart:convert';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ladamadelcanchoapp/domain/entities/user.dart';
import 'package:ladamadelcanchoapp/infraestructure/models/register_result.dart';
import 'package:ladamadelcanchoapp/infraestructure/models/user_updated_response.dart';
import 'package:ladamadelcanchoapp/infraestructure/repositories/auth_repository_impl.dart';
import 'package:ladamadelcanchoapp/infraestructure/utils/secure_storage_helper.dart';
import 'package:ladamadelcanchoapp/presentation/providers/auth/auth_repository_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/forms/profile_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/forms/register_notifier.dart';
import 'package:ladamadelcanchoapp/presentation/providers/pendings/pending_tracks_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/track/track_list_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final formNotifier = ref.watch(registerProvider.notifier); 
  return AuthNotifier(authRepository: authRepository, formNotifier: formNotifier);
});

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? csrfToken;
  final String? errorMessage;
  final UserEntity? user; // ✅ Agregamos el usuario autenticado

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.csrfToken,
    this.errorMessage,
    this.user
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? csrfToken,
    String? errorMessage,
    UserEntity? user,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      csrfToken: csrfToken ?? this.csrfToken,
      errorMessage: errorMessage,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepositoryImpl authRepository;
  final RegisterNotifier  formNotifier;

  AuthNotifier({required this.authRepository, required this.formNotifier}) : super(const AuthState()){
    loadSession(); // ✅ Cargar sesión al iniciar la app
  }


  // ✅ Cargar sesión almacenada en SharedPreferences
  Future<void> loadSession() async {

    //print('✅ Cargando sesion...');

    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    final isAuthenticated = prefs.getBool('isAuthenticated') ?? false;

    if (userJson != null && isAuthenticated) {
      final user = UserEntity.fromJson(jsonDecode(userJson)); 
      state = state.copyWith(isAuthenticated: true, user: user);
      //print('✅ Hay usuario: ${user.fullname}');
    } else {
      state = state.copyWith(isAuthenticated: false, user: null);
      //print('❌ No Hay usuario');
    }

  }

  Future<void> updateUser(ProfileFormState profileState, WidgetRef ref, BuildContext context) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

     try {
      final updatedUser  = UserEntity(
        id: ref.read(authProvider).user!.id, 
        email: profileState.email.value,
        fullname: profileState.fullname.value,
        role: ref.read(authProvider).user!.role,
        telephone: profileState.telephone.value,
        image: profileState.image,
        active: ref.read(authProvider).user!.active,
        theme: ref.read(authProvider).user!.theme,
        language: ref.read(authProvider).user!.language,
      );

      final UserUpdatedResponse userUpdated = await authRepository.updateUser(updatedUser, context );
      
      final UserEntity userTempUpdated = UserEntity(
        id: userUpdated.id,
        active: userUpdated.active,
        email: userUpdated.email,
        fullname: userUpdated.fullname,
        language: userUpdated.language,
        role: userUpdated.role,
        theme: userUpdated.theme,
        image: userUpdated.image,
        telephone: userUpdated.telephone
      );
      
      state = state.copyWith(isLoading: false, user: userTempUpdated);

      

      ref.read(profileProvider.notifier).resetForm(userTempUpdated);

    } catch (error) {
      if(error.toString().contains('El teléfono solo puede contener números')){
        state = state.copyWith(isLoading: false, errorMessage: 'El teléfono solo puede contener números');
      } else if(error.toString().contains('502')){
        state = state.copyWith(isLoading: false, errorMessage: 'Servidor no disponible, inténtelo mas tarde');
      } else {
        // Extrae solo el mensaje limpio de la Exception
        final cleanedMessage = error.toString().startsWith('Exception: ')
            ? error.toString().replaceFirst('Exception: ', '')
            : error.toString();
        state = state.copyWith(isLoading: false, errorMessage: cleanedMessage);
      }

      
      
    }

  }

  Future<void> saveSession(UserEntity user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user.toJson())); // Asegúrate de que `UserEntity` tenga un método `toJson`
    await prefs.setBool('isAuthenticated', true);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.setBool('isAuthenticated', false);
  }

  Future<PersistCookieJar?> jar() async {
    return await authRepository.cookieJar();
  }

  Future<bool> login(BuildContext context, String email, String password, WidgetRef ref) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    //email = 'pepe2@pepe.com'; //para no tener que escribir email y password mientras dure el desarrollo
    //email = 'angelitorogo@hotmail.com';
    //email = 'crysmaldonado20@gmail.com'; //para no tener que escribir email y password mientras dure el desarrollo
    //password = 'Rod00gom!'; //para no tener que escriboir email y password mientras dure el desarrollo

   


    try {
      final result = await authRepository.login(context, email, password, ref);


      if (result) {
        await verifyUser();

        /*
        // 🔥 Refrescar las cookies de Dio
        final jar = await authRepository.cookieJar();
        await jar.loadForRequest(Uri.parse('https://cookies.argomez.com'));

        print("🍪 Cookies después de refrescar manualmente:");
        final cookies = await jar.loadForRequest(Uri.parse('https://cookies.argomez.com'));
        for (var cookie in cookies) {
          print("→ ${cookie.name}: ${cookie.value}");
        }
        */

        formNotifier.resetForm();

        await SecureStorageHelper.saveCredentials(email, password);

        await ref.read(trackListProvider.notifier).resetState();
        Future.delayed(const Duration(milliseconds: 500));
        await ref.read(pendingTracksProvider.notifier).loadTracks();
        Future.delayed(const Duration(milliseconds: 500));

        //despues de hacer login refrescamos las cookies
        

        await ref.read(trackListProvider.notifier).loadTracks(
          ref,
          page: 1,
          loggedUser: state.user?.id,
          append: false
        );
        Future.delayed(const Duration(milliseconds: 500));
        if (context.mounted) {

          GoRouter.of(context).go('/');
        }
        return true;
      } else {
        // ✅ Asegurar que el estado de autenticación es FALSO si el login falla
        state = state.copyWith(
          isAuthenticated: false,
          isLoading: false,
          errorMessage: 'Usuario o contraseña incorrectos',
        );

        return false;
      }


    } catch (e) {
      // ✅ También asegurar que `isAuthenticated = false` en caso de error
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        errorMessage: 'Error al iniciar sesión',
      );
      return false;
    }
  }

  Future<void> verifyUser() async {

    state = state.copyWith(isLoading: true);

    try {
      final user = await authRepository.authVerifyUser();
      await saveSession(user); // ✅ Guardar sesión
      state = state.copyWith(isLoading: false, user: user, isAuthenticated: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Error al verificar usuario');
    }

  }

  Future<UserEntity?> getUser(String userId) async {

    state = state.copyWith(isLoading: true);

    try {
      final user = await authRepository.getUser(userId);
      state = state.copyWith(isLoading: false);
      return user;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Error al cargar usuario');
      return null;
    }
    

  }

  Future<void> logout(WidgetRef ref) async {

    state = state.copyWith(isLoading: true);

    try {

      await authRepository.logout();

      await clearSession(); // ✅ Limpiar sesión en SharedPreferences
      

      // ✅ Primero, resetear completamente el estado
      state = const AuthState();

      //state = state.copyWith(isLoading: false, user: null, isAuthenticated: false);
      ref.read(pendingTracksProvider.notifier).reset();
      ref.read(trackListProvider.notifier).reset();

      
      await ref.read(trackListProvider.notifier).loadTracks(
        ref,
        limit: 10,
        page: 1,
        append: false,
      );
      


    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Error al verificar usuario');
    }

  }


  Future<RegisterResult> register(BuildContext context, String fullname, String email, String password, WidgetRef ref) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
 
    //email = 'pepe@pepe.com';
    //fullname = 'Pepe Perez';
    //password = 'Rod00gom!'; //para no tener que escriboir email y password mientras dure el desarrollo

    try {
      final result = await authRepository.register(context, fullname, email, password, ref);


      if (result.success) {
        formNotifier.resetForm();
        state = state.copyWith(isLoading: false);
        /*
        if (context.mounted) {
          GoRouter.of(context).go('/');
        }
        */
        return result;
      } else {
        // ✅ Asegurar que el estado de autenticación es FALSO si el login falla
        state = state.copyWith(
          isLoading: false,
        );
        return result;
      }


    } catch (e) {
      // ✅ También asegurar que `isAuthenticated = false` en caso de error
      state = state.copyWith(
        isLoading: false,
      );
      return RegisterResult(success: false, message: e.toString());
    }
  }


  AuthState reset() {
    formNotifier.resetForm();
    return const AuthState();
  }
}
