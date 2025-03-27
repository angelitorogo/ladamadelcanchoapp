import 'package:formz/formz.dart';

// Errores posibles para el rol
enum RoleValidationError { empty }

class Role extends FormzInput<String, RoleValidationError> {
  const Role.pure() : super.pure('');
  // ignore: use_super_parameters
  const Role.dirty([String value = '']) : super.dirty(value);

  static String? roleErrorMessage(RoleValidationError? error) {
    if (error == RoleValidationError.empty) return 'El rol no puede estar vacío';
    return null;
  }

  @override
  RoleValidationError? validator(String value) {
    if (value.isEmpty) return RoleValidationError.empty;
    return null;
  }
}
