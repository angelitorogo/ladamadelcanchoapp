import 'package:formz/formz.dart';

enum UsernameError { invalid, length }

class Username extends FormzInput<String, UsernameError>
    with FormzInputErrorCacheMixin {
  Username.pure([super.value = '']) : super.pure();

  Username.dirty([super.value = '']) : super.dirty();

  @override
  UsernameError? validator(String value) {

    if( value.isEmpty || value.trim().isEmpty ) return  UsernameError.invalid;
    if( value.length < 3 ) return UsernameError.length;

    return null;

  }
}