
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formz/formz.dart';
import 'package:ladamadelcanchoapp/domain/entities/user.dart';
import 'package:ladamadelcanchoapp/infraestructure/inputs/inputs.dart';
import 'package:ladamadelcanchoapp/infraestructure/repositories/auth_repository_impl.dart';
import 'package:ladamadelcanchoapp/presentation/providers/auth/auth_provider.dart';
import 'package:ladamadelcanchoapp/presentation/providers/auth/auth_repository_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:ladamadelcanchoapp/presentation/providers/forms/login_notifier.dart';

/// 🔥 Proveedor del formulario de perfil
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileFormState>((ref) {
  final authState = ref.watch(authProvider); // ⬅ Obtiene el usuario autenticado
  final loginState = ref.watch(loginProvider);
  final authRepository = ref.watch(authRepositoryProvider);
  return ProfileNotifier(authState.user, authRepository, ref, loginState);
});

/// 📌 Estado del formulario de perfil
class ProfileFormState {
  final Email email;
  final bool emailTouched;
  final Fullname fullname;
  final bool fullnameTouched;
  final Role role;
  final Telephone telephone;
  final bool telephoneTouched;
  final Active active;
  final Language language;
  final ThemeInput theme;
  final String? image;
  final FormzSubmissionStatus status;
  final bool isLoading;
  final String? errorMessage;
  final bool isNewImage;

  const ProfileFormState({
    this.email = const Email.pure(),
    this.emailTouched = false,
    this.fullname = const Fullname.pure(),
    this.fullnameTouched = false,
    this.role = const Role.pure(),
    this.telephone = const Telephone.pure(),
    this.telephoneTouched = false,
    this.active = const Active.pure(),
    this.language = const Language.pure(),
    this.theme = const ThemeInput.pure(),
    this.image = '',
    this.status = FormzSubmissionStatus.success, // como todos los inputs tienen datos iniciales, ponemos que el formulario de inicio ya es valido
    this.isLoading = false,
    this.errorMessage,
    this.isNewImage = false
  });

  ProfileFormState copyWith({
    Email? email,
    bool? emailTouched,
    Fullname? fullname,
    bool? fullnameTouched,
    Role? role,
    Telephone? telephone,
    bool? telephoneTouched,
    Active? active,
    Language? language,
    ThemeInput? theme,
    String? image,
    FormzSubmissionStatus? status,
    bool? isLoading,
    String? errorMessage,
    bool? isNewImage
  }) {
    return ProfileFormState(
      email: email ?? this.email,
      emailTouched: emailTouched ?? this.emailTouched,
      fullname: fullname ?? this.fullname,
      fullnameTouched: fullnameTouched ?? this.fullnameTouched,
      role: role ?? this.role,
      telephone: telephone ?? this.telephone,
      telephoneTouched: telephoneTouched ?? this.telephoneTouched,
      active: active ?? this.active,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      image: image ?? this.image,
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isNewImage: isNewImage ?? this.isNewImage
    );
  }
}

/// 📌 Notifier para manejar el formulario
class ProfileNotifier extends StateNotifier<ProfileFormState> {
  final AuthRepositoryImpl authRepository;
  final Ref ref; // ✅ Para leer otros providers
  final LoginFormState loginState;

  ProfileNotifier(UserEntity? user, this.authRepository, this.ref, this.loginState)
      : super(user != null
            ? ProfileFormState(
                email: Email.dirty(user.email),
                fullname: Fullname.dirty(user.fullname),
                role: Role.dirty(user.role),
                telephone: Telephone.dirty(user.telephone ??''),
                active: Active.dirty(user.active),
                language: Language.dirty(user.language),
                theme: ThemeInput.dirty(user.theme),
                image: user.image,
              )
            : const ProfileFormState());

  Future<void> selectImage({required bool fromCamera}) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 80, // Ajusta la calidad de la imagen
    );

    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);

      // ✅ Asegurar que la UI ya está construida antes de actualizar el estado
      Future.delayed(Duration.zero, () {
        state = state.copyWith(image: imageFile.path, status: _validateForm(), isNewImage: true); 
      });
    }
  }

  
  void resetUserProfile() {
    final user = ref.read(authProvider).user;
    if (user != null) {
      Future.delayed(Duration.zero, () {
        state = state.copyWith(image: user.image);
      });
    }
  }

  void emailChanged(String value) {
    final email = Email.dirty(value);
    state = state.copyWith(
      email: email,
      emailTouched: true,
      status: _validateForm(),
    );
  }

  void fullnameChanged(String value) {
    final fullname = Fullname.dirty(value);
    state = state.copyWith(
      fullname: fullname,
      fullnameTouched: true,
      status: _validateForm(),
    );
  }

  void telephoneChanged(String value) {
    final telephone = Telephone.dirty(value);
    state = state.copyWith(
      telephone: telephone,
      telephoneTouched: true,
      status: _validateForm(),
    );
  }


  /// 🔥 Método para resetear el formulario
  void resetForm(UserEntity user) {
    state = ProfileFormState(
      email: Email.dirty(user.email),
      fullname: Fullname.dirty(user.fullname),
      role: Role.dirty(user.role),
      telephone: Telephone.dirty(user.telephone ?? ''),
      active: Active.dirty(user.active),
      language: Language.dirty(user.language),
      theme: ThemeInput.dirty(user.theme),
      image: user.image,
      isNewImage: false
    );
  }

    FormzSubmissionStatus _validateForm() {
    return Formz.validate([state.email, state.fullname, state.telephone])
        ? FormzSubmissionStatus.success
        : FormzSubmissionStatus.failure;
  }

}

