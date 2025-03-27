import 'package:formz/formz.dart';

// Errores posibles para el tema
enum ThemeValidationError { empty }

class ThemeInput extends FormzInput<int, ThemeValidationError> {
  const ThemeInput.pure() : super.pure(0);
  // ignore: use_super_parameters
  const ThemeInput.dirty([int value = 0]) : super.dirty(value);

  static String? themeErrorMessage(ThemeValidationError? error) {
    if (error == ThemeValidationError.empty) return 'Debe seleccionar un tema';
    return null;
  }

  @override
  ThemeValidationError? validator(int value) {
    return null;
  }
}
