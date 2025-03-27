

import 'package:ladamadelcanchoapp/domain/entities/user.dart';
import 'package:ladamadelcanchoapp/infraestructure/models/auth_verify_user_response.dart';

class AuthVerifyUserMapper {

  static UserEntity responseToAuth( AuthVerifyUserResponse response) => UserEntity(
    id: response.user.id, 
    email: response.user.email, 
    fullname: response.user.fullname, 
    role: response.user.role, 
    telephone: response.user.telephone, 
    image: response.user.image, 
    active: response.user.active, 
    theme: response.user.theme, 
    //createdAt: response.user.createdAt, 
    //updatedAt: response.user.updatedAt, 
    language: response.user.language
  );

}