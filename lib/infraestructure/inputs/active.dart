import 'package:formz/formz.dart';

// Errores posibles para el estado activo/inactivo
enum ActiveValidationError { notSelected }

class Active extends FormzInput<bool, ActiveValidationError> {
  const Active.pure() : super.pure(false);
  // ignore: use_super_parameters
  const Active.dirty([bool value = false]) : super.dirty(value);

  static String? activeErrorMessage(ActiveValidationError? error) {
    if (error == ActiveValidationError.notSelected) return 'Debe seleccionar una opción';
    return null;
  }

  @override
  ActiveValidationError? validator(bool value) {
    return null; // No es necesario validar ya que es un booleano
  }
}
