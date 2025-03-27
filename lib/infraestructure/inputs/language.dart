import 'package:formz/formz.dart';

// Errores posibles para el idioma
enum LanguageValidationError { empty }

class Language extends FormzInput<String, LanguageValidationError> {
  const Language.pure() : super.pure('');
  // ignore: use_super_parameters
  const Language.dirty([String value = '']) : super.dirty(value);

  static String? languageErrorMessage(LanguageValidationError? error) {
    if (error == LanguageValidationError.empty) return 'Debe seleccionar un idioma';
    return null;
  }

  @override
  LanguageValidationError? validator(String value) {
    if (value.isEmpty) return LanguageValidationError.empty;
    return null;
  }
}
