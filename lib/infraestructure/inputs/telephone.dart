import 'package:formz/formz.dart';

// Errores posibles para el teléfono
enum TelephoneValidationError { invalid }

class Telephone extends FormzInput<String, TelephoneValidationError> {
  const Telephone.pure() : super.pure('');
  const Telephone.dirty([super.value = '']) : super.dirty();

  static String? telephoneErrorMessage(TelephoneValidationError? error) {
  if (error == TelephoneValidationError.invalid) {
    return 'Número de teléfono inválido';
  }
  // Si error es null (o cualquier otro caso), no hay mensaje de error
  return null;
}

  @override
  TelephoneValidationError? validator(String value) {

    if (value.trim().isEmpty) return null; // Campo vacío es válido
    final phoneRegex = RegExp(r'^[0-9]{8,9}$');
    if (!phoneRegex.hasMatch(value)) return TelephoneValidationError.invalid;
    return null;
  }
}
