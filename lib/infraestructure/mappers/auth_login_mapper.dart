

import 'package:ladamadelcanchoapp/domain/entities/auth.dart';
import 'package:ladamadelcanchoapp/infraestructure/models/auth_login_response.dart';

class AuthLoginMapper {

  static Auth responseToAuth( AuthLoginResponse response) => Auth(
    csrfToken: response.csrfToken,
    statusCode: response.statusCode,
    message: response.message,
  );

}