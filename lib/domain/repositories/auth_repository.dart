
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:ladamadelcanchoapp/domain/entities/user.dart';
import 'package:ladamadelcanchoapp/infraestructure/models/user_updated_response.dart';

abstract class AuthRepository {

  Future<void> fetchCsrfToken();

  Future<void> checkCookies();

  Future<bool> login(BuildContext context,String email, String password);

  Future<UserEntity> authVerifyUser(); 

  Future<void> logout();

  Future<Uint8List?> fetchUserImage(String imagePath);

  Future<UserUpdatedResponse> updateUser(UserEntity user);

}