

import 'dart:typed_data';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/domain/entities/user.dart';
import 'package:ladamadelcanchoapp/infraestructure/models/register_result.dart';
import 'package:ladamadelcanchoapp/infraestructure/models/user_updated_response.dart';

abstract class AuthDatasource {

  Future<String> fetchCsrfToken();

  Future<void> checkCookies();

  Future<bool> login(BuildContext context,String email, String password, WidgetRef ref);

  Future<RegisterResult> register(BuildContext context,String fullname, String email, String password, WidgetRef ref);

  Future<UserEntity> authVerifyUser();

  Future<void> logout(); 

  Future<UserEntity> getUser(String userId);

  Future<Uint8List?> fetchUserImage(String imagePath);

  Future<UserUpdatedResponse> updateUser(UserEntity user, BuildContext context);

  Future<PersistCookieJar> cookieJar();

}