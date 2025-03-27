
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:ladamadelcanchoapp/domain/datasources/auth_datasource.dart';
import 'package:ladamadelcanchoapp/domain/entities/user.dart';
import 'package:ladamadelcanchoapp/infraestructure/mappers/auth_verify_user_mapper.dart';
import 'package:ladamadelcanchoapp/infraestructure/models/auth_verify_user_response.dart';
import 'package:ladamadelcanchoapp/infraestructure/models/user_updated_response.dart';

class AuthDatasourceImpl  extends AuthDatasource{

  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://cookies.argomez.com/api/auth',
    followRedirects: false,
    validateStatus: (status) => status != null && status < 500,
  ));
  String? _csrfToken; // Guardamos el CSRF token
  final _cookieJar = CookieJar();

  AuthDatasourceImpl() {
    _dio.interceptors.add(CookieManager(_cookieJar)); // 📌 Agregamos el interceptor de cookies
  }

  @override
  Future<void> checkCookies() async {
    /*final cookies = */await _cookieJar.loadForRequest(Uri.parse('https://cookies.argomez.com'));
    //print('Cookies guardadas: $cookies');
  }

  @override
  Future<void> fetchCsrfToken() async {
     try {
      final response = await _dio.get('/csrf-token');

      if (response.statusCode == 200) {
        _csrfToken = response.data['csrfToken'];
        //print('CSRF Token obtenido: $_csrfToken');

        // 📌 Revisar si hay cookies almacenadas después de obtener el token
        await checkCookies();

      } else {
        //print('Error al obtener CSRF Token: ${response.statusCode}');
      }
    } catch (e) {
      //print('Error en fetchCsrfToken: $e');
    }
  }

  @override
  Future<bool> login(BuildContext context, String email, String password) async {
    try {
      await fetchCsrfToken();

      final response = await _dio.post(
        '/login',
        data: {'email': email, 'password': password},
        options: Options(
          headers: {'X-CSRF-Token': _csrfToken},
        ),
      );

      //print("📡 Respuesta del servidor: ${response.data}");

      if (response.statusCode == 201 && response.data['message'] == 'Login exitoso') {
        return true;
      } else {
        //print("⚠️ Login fallido, backend devolvió: ${response.data}");
        return false;
      }

    } catch (e) {
      //print("❌ Error en login: $e");
      return false;
    }
  }


  @override
  Future<UserEntity> authVerifyUser() async {

    try {

      final response = await _dio.get(
        '/verify',
        options: Options(
          headers: {'X-CSRF-Token': _csrfToken},
        ),
      );

      final authVerifiedUser = AuthVerifyUserResponse.fromJson(response.data);

      final user = AuthVerifyUserMapper.responseToAuth(authVerifiedUser);

      
      return user;
      
    } catch (e) {
      throw Exception('Error en login: $e');
    }

    
    
  }
  
  @override
  Future<void> logout() async {

    try {

      await _dio.post(
        '/logout',
        options: Options(
          headers: {'X-CSRF-Token': _csrfToken},
        ),
      );

      // 🔥 Limpiar cookies después de hacer logout
      await _cookieJar.deleteAll();
      //print("Cookies eliminadas correctamente");
      
      
    } catch (e) {
      throw Exception('Error en login: $e');
    }
    
  }

  // ✅ Método para obtener la imagen con autenticación
  @override
  Future<Uint8List?> fetchUserImage(String imagePath) async {
    try {
      final response = await _dio.get(
        'https://cookies.argomez.com/api/files/$imagePath',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'X-CSRF-Token': _csrfToken},
        ),
      );

      if (response.statusCode == 200) {
        return Uint8List.fromList(response.data);
      }
    } catch (e) {
      //print("❌ Error al obtener la imagen: $e");
    }
    return null;
  }
  


@override
Future<UserUpdatedResponse> updateUser(UserEntity user) async {

  String? base64Image;
  dynamic data;

  // ✅ Convertir la imagen a Base64 si el usuario ha seleccionado una
  if (user.image != null  &&  user.image!.length > 60) {
    final File imageFile = File(user.image!);
    if (await imageFile.exists()) {
      final List<int> imageBytes = await imageFile.readAsBytes();
      base64Image = base64Encode(imageBytes);

      // ✅ Enviar datos en JSON incluyendo la imagen en Base64 (si existe)
      data = {
        "id": user.id,
        "email": user.email,
        "fullname": user.fullname,
        "role": user.role,
        "telephone": user.telephone ?? "",
        "active": user.active,
        "theme": user.theme,
        "language": user.language,
        "image": base64Image, // 🔥 Se envía la imagen en Base64 o `null` si no hay nueva imagen
      };
      
    }

  } else {

    // ✅ Enviar datos en JSON incluyendo la imagen en Base64 (si existe)
      data = {
        "id": user.id,
        "email": user.email,
        "fullname": user.fullname,
        "role": user.role,
        "telephone": user.telephone ?? "",
        "active": user.active,
        "theme": user.theme,
        "language": user.language,
      };

  }

  


  final response = await _dio.put(
    "/update",
    data: data,
    options: Options(
      headers: {
        "X-CSRF-Token": _csrfToken,
        "Content-Type": "application/json",
      },
    ),
  );

  if (response.statusCode != 200) {
    throw Exception(response.data['message']);
  }

  final UserUpdatedResponse userUpdated = UserUpdatedResponse(
    id: response.data['id'], 
    email: response.data['email'], 
    fullname: response.data['fullname'], 
    password: response.data['password'], 
    role: response.data['role'], 
    telephone: response.data['telephone'], 
    image: response.data['image'], 
    active: response.data['active'], 
    theme: response.data['theme'], 
    createdAt: DateTime.tryParse(response.data['created_at'])!, 
    updatedAt: DateTime.tryParse(response.data['updated_at'])!, 
    language: response.data['language']
  ); 

  return userUpdated;

  }



    
}

