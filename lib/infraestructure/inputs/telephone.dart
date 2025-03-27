import 'package:formz/formz.dart';

// Errores posibles para el teléfono
enum TelephoneValidationError { empty, invalid }

class Telephone extends FormzInput<String, TelephoneValidationError> {
  const Telephone.pure() : super.pure('');
  // ignore: use_super_parameters
  const Telephone.dirty([String value = '']) : super.dirty(value);

  static String? telephoneErrorMessage(TelephoneValidationError? error) {
    switch (error) {
      case TelephoneValidationError.empty:
        return 'El teléfono no puede estar vacío';
      case TelephoneValidationError.invalid:
        return 'Número de teléfono inválido';
      default:
        return null;
    }
  }

  @override
  TelephoneValidationError? validator(String value) {
    final phoneRegex = RegExp(r'^[0-9]{8,9}$');
    if (value.isEmpty) return TelephoneValidationError.empty;
    if (!phoneRegex.hasMatch(value)) return TelephoneValidationError.invalid;
    return null;
  }
}
