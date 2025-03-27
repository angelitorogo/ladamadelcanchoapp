import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:ladamadelcanchoapp/domain/datasources/auth_datasource.dart';
import 'package:ladamadelcanchoapp/domain/entities/user.dart';
import 'package:ladamadelcanchoapp/domain/repositories/auth_repository.dart';
import 'package:ladamadelcanchoapp/infraestructure/models/user_updated_response.dart';

class AuthRepositoryImpl extends AuthRepository{

  final AuthDatasource datasource;

  AuthRepositoryImpl(this.datasource);
  
  @override
  Future<void> checkCookies() {
    return datasource.checkCookies();
  }

  @override
  Future<void> fetchCsrfToken() {
    return datasource.fetchCsrfToken();
  }

  @override
  Future<bool> login(BuildContext context, String email, String password) {
    return datasource.login(context, email, password);
  }

  @override
  Future<UserEntity> authVerifyUser() {
    return datasource.authVerifyUser();
  }
  
  @override
  Future<void> logout() {
    return datasource.logout();
  }

  @override
  Future<Uint8List?> fetchUserImage(String imagePath) {
    return datasource.fetchUserImage(imagePath);
  }
  
  @override
  Future<UserUpdatedResponse> updateUser(UserEntity user) {
    return datasource.updateUser(user);
  }
  
}