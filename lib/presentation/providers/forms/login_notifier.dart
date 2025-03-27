import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formz/formz.dart';
import 'package:ladamadelcanchoapp/infraestructure/inputs/inputs.dart';

// Proveedor del formulario
final loginProvider = StateNotifierProvider<LoginNotifier, LoginFormState>((ref) {
  return LoginNotifier();
});


// Estado del formulario
class LoginFormState {
  final Email email;
  final Password password;
  final FormzSubmissionStatus status;
  final bool emailTouched;
  final bool passwordTouched;

  const LoginFormState({
    this.email = const Email.pure(),
    this.password = const Password.pure(),
    this.status = FormzSubmissionStatus.initial,
    this.emailTouched = false,
    this.passwordTouched = false,
  });

  LoginFormState copyWith({
    Email? email,
    Password? password,
    FormzSubmissionStatus? status,
    bool? emailTouched,
    bool? passwordTouched,
  }) {
    return LoginFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      status: status ?? this.status,
      emailTouched: emailTouched ?? this.emailTouched,
      passwordTouched: passwordTouched ?? this.passwordTouched,
    );
  }
}

// Notifier para manejar el formulario
class LoginNotifier extends StateNotifier<LoginFormState> {
  LoginNotifier() : super(const LoginFormState());

  void emailChanged(String value) {
    final email = Email.dirty(value);
    state = state.copyWith(
      email: email,
      emailTouched: true,
      status: _validateForm(),
    );
  }

  void passwordChanged(String value) {
    final password = Password.dirty(value);
    state = state.copyWith(
      password: password,
      passwordTouched: true,
      status: _validateForm(),
    );
  }


  void resetForm() {
    state = const LoginFormState(
      email: Email.pure(),
      password: Password.pure(),
      emailTouched: false,
      passwordTouched: false,
      status: FormzSubmissionStatus.initial
    );

    //print('${state.email}');
  }

  FormzSubmissionStatus _validateForm() {
    return Formz.validate([state.email, state.password])
        ? FormzSubmissionStatus.success
        : FormzSubmissionStatus.failure;
  }
}

