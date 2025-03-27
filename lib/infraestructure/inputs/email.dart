

import 'package:formz/formz.dart';

// Errores posibles para el email
enum EmailValidationError { empty, invalid }

class Email extends FormzInput<String, EmailValidationError> {
  // Constructor para el estado inicial (vacío)
  const Email.pure() : super.pure('');

  // Constructor para el estado modificado
  // ignore: use_super_parameters
  const Email.dirty([String value = '']) : super.dirty(value);

  static String? emailErrorMessage(EmailValidationError? error) {
    switch (error) {
      case EmailValidationError.empty:
        return 'El email no puede estar vacío';
      case EmailValidationError.invalid:
        return 'Correo no válido';
      default:
        return null;
    }
  }

  // Validación del email
  @override
  EmailValidationError? validator(String value) {
    final emailRegex = RegExp(r'^[a-zA-Z\d.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z\d-]+(?:\.[a-zA-Z\d-]+)*$');
    if (value.isEmpty) return EmailValidationError.empty;
    return emailRegex.hasMatch(value) ? null : EmailValidationError.invalid;
  }
}
