import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/domain/datasources/track_datasource.dart';
import 'package:ladamadelcanchoapp/domain/entities/track.dart';
import 'package:ladamadelcanchoapp/infraestructure/utils/global_cookie_jar.dart';
import 'package:ladamadelcanchoapp/presentation/providers/auth/auth_provider.dart';

class TrackDatasourceImpl implements TrackDatasource {
  
  
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://cookies.argomez.com/api/tracks',
    followRedirects: false,
    validateStatus: (status) => status != null && status < 500,
  ));

  //final _cookieJar = GlobalCookieJar.instance;
  late final PersistCookieJar _cookieJar;
  String? _csrfToken;

  TrackDatasourceImpl() {
    GlobalCookieJar.instance.then((jar) {
      _cookieJar = jar;
      _dio.interceptors.add(CookieManager(_cookieJar));

      // Interceptor para depurar cookies enviadas
      /*
      _dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          final cookies = await _cookieJar.loadForRequest(Uri.parse('https://cookies.argomez.com'));
          print('🍪 Cookies enviadas en ${options.path}:');
          for (final cookie in cookies) {
            print('➡️ ${cookie.name} = ${cookie.value}');
          }

          handler.next(options);
        },
      ));
      */
    
    });
  }

  Future<void> checkCookies() async {
    /*final cookies = */await _cookieJar.loadForRequest(Uri.parse('https://cookies.argomez.com'));
    //print('🍪 Cookies guardadas track: $cookies');
  }

  /// ✅ Obtener CSRF token (reutilizable)
  Future<void> _fetchCsrfToken() async {


    try {

      final authDio = Dio(BaseOptions(
        baseUrl: 'https://cookies.argomez.com/api/auth',
        validateStatus: (status) => status != null && status < 500,
      ));

      authDio.interceptors.add(CookieManager(_cookieJar));

      // 🔍 VERIFICAMOS cookies antes de llamar CSRF
      _cookieJar.loadForRequest(Uri.parse('https://cookies.argomez.com'));

      final response = await authDio.get('/csrf-token');

      if (response.statusCode == 200) {
        _csrfToken = response.data['csrfToken'];
        await checkCookies();
        return;
      }

      throw Exception('Error CSRF: ${response.statusCode}');
    } catch (e) {
      throw Exception('❌ No se pudo obtener CSRF: $e');
    }
  }




  @override
  Future<Map<String, dynamic>> uploadTrack(WidgetRef ref, String name, File gpxFile, String description, String type, String distance, String elevationGain, {List<File> images = const[]}) async {
    
    await _fetchCsrfToken(); // ✅ CSRF requerido

    //print('✅ Images3: $images');

    final formData = FormData.fromMap({
      'user': ref.watch(authProvider).user!.id,
      'name': name,
      'distance': distance,
      'elevation_gain': elevationGain,
      'description': description,
      'type': type,
      'gpx': await MultipartFile.fromFile(
        gpxFile.path,
        filename: gpxFile.uri.pathSegments.last,
      ),
      if (images.isNotEmpty)
        'images': await Future.wait(images.map((img) async {
          return await MultipartFile.fromFile(img.path, filename: img.uri.pathSegments.last);
        })),
    });

    //ver exactamente qué cookies se van a enviar en una petición con Dio y dio_cookie_manager


    try {

      
      final response = await _dio.post(
        '/upload',
        data: formData,
        options: Options(
          headers: {
            'X-CSRF-Token': _csrfToken,
          },
        ),
      );

      if (response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Error al subir el track: ${response.data['message']}');
      }
    } catch (e) {
      throw Exception('❌ Error en uploadTrack: $e');
    }
  }
  
  @override
  Future<Map<String, dynamic>> loadAllTracks({int limit = 10, int page = 1, String? userId, String? orderBy, String? direction}) async {

    //await _fetchCsrfToken(); // ✅ CSRF requerido


    try {
      final response = await _dio.get(
        '/',
        queryParameters: {
        'limit': limit,
        'page': page,
        'orderBy': orderBy,
        'direction': direction,
        if (userId != null) 'userId': userId,
      },
        options: Options(
          headers: {
            'X-CSRF-Token': _csrfToken,
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Error');
      }
    } catch (e) {
      if( e is DioException) {
        throw DioException.connectionError(
          requestOptions: RequestOptions(
            path: '/', // la ruta que falló
            baseUrl: _dio.options.baseUrl, // opcional
          ),
          reason: e.toString(),
        );
      } else {
        throw Exception('❌ Error: $e');
      } 
      
    }

    
  }
  
  @override
  Future<bool> existsTrack(String name) async {

    //try {
      final response = await _dio.get(
        '/track/$name' ,
        options: Options(
          headers: {
            'X-CSRF-Token': _csrfToken,
          },
        ),
      );

      if (response.statusCode == 200) {
        final isAvailable = response.data.toString().toLowerCase() == 'true';
        return isAvailable;
      } else{ 
        return false;
      }

    /*
    } catch (e) {
      if( e is DioException) {
        throw DioException.connectionError(
          requestOptions: RequestOptions(
            path: '/', // la ruta que falló
            baseUrl: _dio.options.baseUrl, // opcional
          ),
          reason: e.toString(),
        );
      } else {
        throw Exception('❌ Error: $e');
      } 
      
    }
    */

  }

  @override
  Future<Track> loadTrack(String id) async {

    

    final response = await _dio.get(
      '/$id' ,
      options: Options(
        headers: {
          'X-CSRF-Token': _csrfToken,
        },
      ),
    );

    final track = Track.fromJson(response.data);

    return track;
  }


  //https://cookies.argomez.com/api/tracks?limit=10&page=1&userId=23235555
}
