
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/domain/datasources/auth_datasource.dart';
import 'package:ladamadelcanchoapp/domain/entities/user.dart';
import 'package:ladamadelcanchoapp/infraestructure/mappers/auth_verify_user_mapper.dart';
import 'package:ladamadelcanchoapp/infraestructure/models/auth_verify_user_response.dart';
import 'package:ladamadelcanchoapp/infraestructure/models/register_result.dart';
import 'package:ladamadelcanchoapp/infraestructure/models/user_updated_response.dart';
import 'package:ladamadelcanchoapp/infraestructure/utils/dio_global.dart';
import 'package:ladamadelcanchoapp/infraestructure/utils/global_cookie_jar.dart';

class AuthDatasourceImpl  extends AuthDatasource{

  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://cookies.argomez.com/api/auth',
    followRedirects: false,
    validateStatus: (status) => status != null && status < 500,
  ));
  String? _csrfToken; // Guardamos el CSRF token
  //final _cookieJar = GlobalCookieJar.instance;
  final Future<PersistCookieJar> _cookieJar = GlobalCookieJar.instance;


  AuthDatasourceImpl() {
    _cookieJar.then((jar) {
      _dio.interceptors.add(CookieManager(jar));
    });


  }

  
  @override
  Future<void> checkCookies() async {
    final jar = await _cookieJar;
    /*final cookies =*/await jar.loadForRequest(Uri.parse('https://cookies.argomez.com'));
    //print('🍪 Cookies guardadas auth: $cookies');
  }

  @override
  Future<String> fetchCsrfToken() async {
     try {
      final response = await _dio.get('/csrf-token');

      if (response.statusCode == 200) {
        _csrfToken = response.data['csrfToken'];

        // 📌 Revisar si hay cookies almacenadas después de obtener el token
        await checkCookies();
        return _csrfToken!;

      } else {
        throw Exception('Error al obtener CSRF Token');
      }
    } on DioException catch (e) {

      if( e.response?.statusCode == 502) {
        //print("⚠️ Error 502: El servidor está inactivo o no responde.");
        return 'El servidor está inactivo o no responde.';
      } else {
        //print('⚠️ Error en la solicitud CSRF: ${e.message}');
        return 'Error en la solicitud CSRF: ${e.message}';
      }

    } catch (e) {
      // Otro tipo de errores (por ejemplo, de conexión o lógicos)
      //print('⚠️ Error no manejado: $e');
      return 'Error inesperado: $e';
    }  

    
  }

  /*
  // ✅ Refrescar cookies y mostrarlas por consola
  Future<void> refreshCookies() async {
    final jar = await _cookieJar;

    // 🔄 Limpia y vuelve a añadir el interceptor
    _dio.interceptors.clear();
    _dio.interceptors.add(CookieManager(jar));

    // 💬 Cargar cookies actuales para el dominio y mostrarlas
    final cookies = await jar.loadForRequest(Uri.parse('https://cookies.argomez.com'));
    print('🍪 Cookies refrescadas:');
    for (final cookie in cookies) {
      print('→ ${cookie.name}: ${cookie.value}');
    }
  }
  */

  @override
  Future<bool> login(BuildContext context, String email, String password ,WidgetRef ref) async {
    try {

      // ✅ Asegura tener CSRF Token antes de login
      await fetchCsrfToken();



      final response = await _dio.post(
        '/login',
        data: {'email': email, 'password': password},
        options: Options(
          headers: {'X-CSRF-Token': _csrfToken},
        ),
      );

      

      //print("📡 Respuesta del servidor: ${response.data}");

      if (response.headers.map.containsKey('set-cookie')) {
        final cookiesHeader = response.headers.map['set-cookie']!;
        final cookies = cookiesHeader.map((header) => Cookie.fromSetCookieValue(header)).toList();

        final uri = Uri.parse('https://cookies.argomez.com');

        final jar = await _cookieJar;
        await jar.saveFromResponse(uri, cookies);

        /*
        print('🍪 Cookies guardadas manualmente desde set-cookie:');
        for (final cookie in cookies) {
          print('→ ${cookie.name}: ${cookie.value}');
        }
        */

        await refreshDioInterceptors(_dio);

        //print('✅ Interceptores de AuthDatasource actualizados');

      }

      

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

      // ✅ Si no hay CSRF en memoria, intenta obtener uno nuevo automáticamente
      await fetchCsrfToken();

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

      // ✅ Asegura tener CSRF Token antes de hacer logout
      await fetchCsrfToken();

      await _dio.post(
        '/logout',
        options: Options(
          headers: {'X-CSRF-Token': _csrfToken},
        ),
      );


      // 🔥 Limpiar cookies después de hacer logout
      final jar = await _cookieJar;
      await jar.deleteAll();
      //print("Cookies eliminadas correctamente");
      
      //await checkCookies();
      
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
  Future<UserUpdatedResponse> updateUser(UserEntity user, BuildContext context) async {

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
          "telephone": user.telephone == "" ? null : user.telephone,
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
          "telephone": user.telephone == "" ? null : user.telephone,
          "active": user.active,
          "theme": user.theme,
          "language": user.language,
        };

    }


    // ✅ Si no hay CSRF en memoria, intenta obtener uno nuevo automáticamente
    await fetchCsrfToken();


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

    if (response.statusCode == 400 || response.statusCode == 401) {
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
    

  @override
  Future<UserEntity> getUser(String userId) async {

    try {

      // ✅ Si no hay CSRF en memoria, intenta obtener uno nuevo automáticamente
      await fetchCsrfToken();

      final response = await _dio.get(
        '/user/$userId',
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
  Future<RegisterResult> register(BuildContext context, String fullname, String email, String password, WidgetRef ref) async {
    

    try {

      // ✅ Asegura tener CSRF Token antes de login
      await fetchCsrfToken();

      final response = await _dio.post(
        '/register',
        data: {'fullname': fullname, 'email': email, 'password': password},
        options: Options(
          headers: {'X-CSRF-Token': _csrfToken},
        ),
      );

      

      if (response.statusCode == 201 && response.data['message'] == 'Usuario registrado correctamente') {
        final msg = response.data['message'] ?? 'Usuario registrado correctamente';
        return RegisterResult(success: true, message: msg);
      } else {
        //msg = response.data['message'] ?? 'Error al registrar usuario';
        return RegisterResult(success: false, message: response.data['message']);
      }
      
    } catch (e) {
      return RegisterResult(success: false, message: 'Error en el registro');
    }

  }
  
  @override
  Future<PersistCookieJar> cookieJar() async {
    return await _cookieJar;
  }

    

    
}

