import 'dart:typed_data';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/domain/datasources/auth_datasource.dart';
import 'package:ladamadelcanchoapp/domain/entities/user.dart';
import 'package:ladamadelcanchoapp/domain/repositories/auth_repository.dart';
import 'package:ladamadelcanchoapp/infraestructure/models/register_result.dart';
import 'package:ladamadelcanchoapp/infraestructure/models/user_updated_response.dart';

class AuthRepositoryImpl extends AuthRepository{

  final AuthDatasource datasource;

  AuthRepositoryImpl(this.datasource);
  
  @override
  Future<void> checkCookies() {
    return datasource.checkCookies();
  }

  @override
  Future<String> fetchCsrfToken() {
    return datasource.fetchCsrfToken();
  }

  @override
  Future<bool> login(BuildContext context, String email, String password, WidgetRef ref) {
    return datasource.login(context, email, password, ref);
  }

  @override
  Future<RegisterResult> register(BuildContext context, String fullname, String email, String password, WidgetRef ref) {
    return datasource.register(context, fullname, email, password, ref);
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
  Future<UserUpdatedResponse> updateUser(UserEntity user, BuildContext context) {
    return datasource.updateUser(user, context);
  }

  @override
  Future<PersistCookieJar> cookieJar() {
    return datasource.cookieJar();
  }
  
  @override
  Future<UserEntity> getUser(String userId) {
    return datasource.getUser(userId);
  }
  
  


}