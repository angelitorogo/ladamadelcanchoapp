

import 'package:formz/formz.dart';

// Errores posibles para la contraseña
enum PasswordValidationError { empty, tooShort, format }

class Password extends FormzInput<String, PasswordValidationError> {
  // Constructor para el estado inicial (vacío)
  const Password.pure() : super.pure('');

  // Constructor para el estado modificado
  // ignore: use_super_parameters
  const Password.dirty([String value = '']) : super.dirty(value);


  static String? passwordErrorMessage(PasswordValidationError? error) {
    switch (error) {
      case PasswordValidationError.empty:
        return 'La contraseña no puede estar vacía';
      case PasswordValidationError.tooShort:
        return 'Debe tener al menos 6 caracteres';
      case PasswordValidationError.format:
        return 'Debe tener al menos una mayuscula, una minuscula y un numero';
      default:
        return null;
    }
  }
  

  // Validación de la contraseña (mínimo 6 caracteres)
  @override
  PasswordValidationError? validator(String value) {
    final RegExp passwordRegExp = RegExp(r'(?:(?=.*\d)|(?=.*\W+))(?![.\n])(?=.*[A-Z])(?=.*[a-z]).*$',);
    if(value.isEmpty) return PasswordValidationError.empty;
    if( value.length < 6 ) return PasswordValidationError.tooShort;
    if( !passwordRegExp.hasMatch(value) ) return PasswordValidationError.format;

    return null;
  }
}

