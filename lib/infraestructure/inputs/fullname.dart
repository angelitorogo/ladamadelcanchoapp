import 'package:formz/formz.dart';

// Errores posibles para el nombre completo
enum FullnameValidationError { empty, tooShort }

class Fullname extends FormzInput<String, FullnameValidationError> {
  const Fullname.pure() : super.pure('');
  // ignore: use_super_parameters
  const Fullname.dirty([String value = '']) : super.dirty(value);

  static String? fullnameErrorMessage(FullnameValidationError? error) {
    switch (error) {
      case FullnameValidationError.empty:
        return 'El nombre no puede estar vacío';
      case FullnameValidationError.tooShort:
        return 'Debe tener al menos 3 caracteres';
      default:
        return null;
    }
  }

  @override
  FullnameValidationError? validator(String value) {
    if (value.isEmpty) return FullnameValidationError.empty;
    if (value.length < 2) return FullnameValidationError.tooShort;
    return null;
  }
}
