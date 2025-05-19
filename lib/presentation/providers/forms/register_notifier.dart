import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formz/formz.dart';
import 'package:ladamadelcanchoapp/infraestructure/inputs/inputs.dart';

// Proveedor del formulario
final registerProvider = StateNotifierProvider<RegisterNotifier, RegisterFormState>((ref) {
  return RegisterNotifier();
});


// Estado del formulario
class RegisterFormState {
  final Email email;
  final Password password;
  final Password password2;
  final Fullname fullname;
  final FormzSubmissionStatus status;
  final bool fullnameTouched;
  final bool emailTouched;
  final bool passwordTouched;
  final bool password2Touched;

  const RegisterFormState({
    this.email = const Email.pure(),
    this.password = const Password.pure(),
    this.password2 = const Password.pure(),
    this.fullname = const Fullname.pure(),
    this.status = FormzSubmissionStatus.initial,
    this.fullnameTouched = false,
    this.emailTouched = false,
    this.passwordTouched = false,
    this.password2Touched = false,
  });

  RegisterFormState copyWith({
    Email? email,
    Password? password,
    Password? password2,
    Fullname? fullname,
    FormzSubmissionStatus? status,
    bool? fullnameTouched,
    bool? emailTouched,
    bool? passwordTouched,
    bool? password2Touched,
  }) {
    return RegisterFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      password2: password2 ?? this.password2,
      fullname: fullname ?? this.fullname,
      status: status ?? this.status,
      fullnameTouched: fullnameTouched ?? this.fullnameTouched,
      emailTouched: emailTouched ?? this.emailTouched,
      passwordTouched: passwordTouched ?? this.passwordTouched,
      password2Touched: password2Touched ?? this.password2Touched,
    );
  }
}

// Notifier para manejar el formulario
class RegisterNotifier extends StateNotifier<RegisterFormState> {
  RegisterNotifier() : super(const RegisterFormState());

  void emailChanged(String value) {
    final email = Email.dirty(value);
    print('🧍 Email actualizado: ${email.value}'); // 👈 Debug print
    state = state.copyWith(
      email: email,
      emailTouched: true,
      status: _validateForm(),
    );
  }

  void fullnameChanged(String value) {
    final fullname = Fullname.dirty(value);
    print('🧍 Nombre actualizado: ${fullname.value}'); // 👈 Debug print
    state = state.copyWith(
      fullname: fullname,
      fullnameTouched: true,
      status: _validateForm(),
    );
  }

  void passwordChanged(String value) {
    final password = Password.dirty(value);
    print('🧍 Nombre actualizado: ${password.value}'); // 👈 Debug print
    state = state.copyWith(
      password: password,
      passwordTouched: true,
      status: _validateForm(),
    );
  }

  void password2Changed(String value) {
    final password2 = Password.dirty(value);
    print('🧍 Nombre actualizado: ${password2.value}'); // 👈 Debug print
    state = state.copyWith(
      password2: password2,
      password2Touched: true,
      status: _validateForm(),
    );
  }


  void resetForm() {
    state = const RegisterFormState(
      email: Email.pure(),
      password: Password.pure(),
      password2: Password.pure(),
      emailTouched: false,
      password2Touched: false,
      passwordTouched: false,
      status: FormzSubmissionStatus.initial
    );

    //print('${state.email}');
  }

  FormzSubmissionStatus _validateForm() {
    return Formz.validate([state.fullname, state.email, state.password, state.password2])
        ? FormzSubmissionStatus.success
        : FormzSubmissionStatus.failure;
  }
}

