import 'package:formz/formz.dart';

// Errores posibles para el nombre completo
enum ImageValidationError { empty, tooShort }

class ImageInput extends FormzInput<String, ImageValidationError> {
  const ImageInput.pure() : super.pure('');
  // ignore: use_super_parameters
  const ImageInput.dirty([String value = '']) : super.dirty(value);

  static String? fullnameErrorMessage(ImageValidationError? error) {
    switch (error) {
      case ImageValidationError.empty:
        return 'El nombre no puede estar vacío';
      case ImageValidationError.tooShort:
        return 'Debe tener al menos 3 caracteres';
      default:
        return null;
    }
  }

  @override
  ImageValidationError? validator(String value) {
    if (value.isEmpty) return ImageValidationError.empty;
    if (value.length < 3) return ImageValidationError.tooShort;
    return null;
  }
}
