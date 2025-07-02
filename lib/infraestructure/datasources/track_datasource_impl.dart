import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladamadelcanchoapp/domain/datasources/track_datasource.dart';
import 'package:ladamadelcanchoapp/domain/entities/track.dart';
import 'package:ladamadelcanchoapp/domain/entities/user.dart';
import 'package:ladamadelcanchoapp/infraestructure/utils/dio_global.dart';
import 'package:ladamadelcanchoapp/infraestructure/utils/global_cookie_jar.dart';
import 'package:ladamadelcanchoapp/presentation/providers/auth/auth_provider.dart';
import 'package:http_parser/http_parser.dart';

class TrackDatasourceImpl implements TrackDatasource {
  
  
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://cookies.argomez.com/api/tracks',
    followRedirects: false,
    validateStatus: (status) => status != null && status < 500,
  ));

  //final _cookieJar = GlobalCookieJar.instance;
  final Future<PersistCookieJar> _cookieJar = GlobalCookieJar.instance;

  String? _csrfToken;

  TrackDatasourceImpl() {
    
    _setupInterceptors();

  }

  void _setupInterceptors() async {
    final jar = await _cookieJar;

    _dio.interceptors.add(CookieManager(jar));

    /*
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('➡️ PETICIÓN');
        print('--> URL: ${options.baseUrl}${options.path}');
        print('--> Método: ${options.method}');
        print('--> Headers: ${options.headers}');
        print('--> Query: ${options.queryParameters}');
        print('--> Data: ${options.data}');
        print('--> Extra: ${options.extra}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ RESPUESTA');
        print('<-- Status: ${response.statusCode}');
        print('<-- Data: ${response.data}');
        handler.next(response);
      },
      onError: (DioError e, handler) {
        print('❌ ERROR');
        print('<-- Status: ${e.response?.statusCode}');
        print('<-- Error: ${e.error}');
        print('<-- Data: ${e.response?.data}');
        handler.next(e);
      },
    ));
    */
  }

  

  Future<void> checkCookies(WidgetRef ref) async {
    //final jar = await _cookieJar;
    //final cookies = await jar.loadForRequest(Uri.parse('https://cookies.argomez.com'));

    final jar = await ref.read(authProvider.notifier).jar();
    /*final cookies = */await jar?.loadForRequest(Uri.parse('https://cookies.argomez.com'));

    //print('🍪 Cookies guardadas track: $cookies');
  }

  /// ✅ Obtener CSRF token (reutilizable)
  Future<void> _fetchCsrfToken(WidgetRef ref) async {


    try {

      final jar = await _cookieJar;

      final authDio = Dio(BaseOptions(
        baseUrl: 'https://cookies.argomez.com/api/auth',
        validateStatus: (status) => status != null && status < 500,
      ));

      authDio.interceptors.add(CookieManager(jar));

      // 🔍 VERIFICAMOS cookies antes de llamar CSRF
      await jar.loadForRequest(Uri.parse('https://cookies.argomez.com'));

      final response = await authDio.get('/csrf-token');

      if (response.statusCode == 200) {
        _csrfToken = response.data['csrfToken'];
        await checkCookies(ref);
        return;
      } 

      throw Exception('Error CSRF: ${response.statusCode}');
    } catch (e) {
      throw Exception('❌ No se pudo obtener CSRF: $e');
    }
  }




  @override
  Future<Map<String, dynamic>> uploadTrack(WidgetRef ref, String name, File gpxFile, String description, String type, String distance, String elevationGain, {List<File> images = const[]}) async {
    
    await _fetchCsrfToken(ref); // ✅ CSRF requerido

    //print('✅ Distance: $distance');

    final gpxBytes = await gpxFile.readAsBytes();

    try {
      final formData = FormData.fromMap({
        'user': ref.watch(authProvider).user!.id,
        'name': name,
        'distance': distance,
        'elevation_gain': elevationGain,
        'description': description,
        'type': type,
        'gpx': MultipartFile.fromBytes(
          gpxBytes,
          filename: 'garmin_track.gpx',
          contentType: MediaType('application', 'octet-stream'),
        ),
        if (images.isNotEmpty)
          'images': await Future.wait(images.map((img) async {
            return await MultipartFile.fromFile(img.path, filename: img.uri.pathSegments.last);
          })),
      });

      //ver exactamente qué cookies se van a enviar en una petición con Dio y dio_cookie_manager

      await refreshDioInterceptors(_dio);

      /*
      print('✅ Interceptores de TrackDatasource actualizados');

      // 💬 Cargar cookies actuales para la ruta real y mostrarlas
      final jar = await _cookieJar;
      final cookies = await jar.loadForRequest(Uri.parse('https://cookies.argomez.com'));
      print('🍪 Cookies para https://cookies.argomez.com:');
      for (final cookie in cookies) {
        print('→ ${cookie.name}: ${cookie.value}');
      }
      */

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

      throw Exception('❌ ${e.toString()}');

    }

  
  }
  
  @override
  Future<Map<String, dynamic>> loadAllTracks(WidgetRef ref, {int limit = 10, int page = 1, String? loggedUser,  String? userId, String? orderBy, String? direction}) async {

    await _fetchCsrfToken(ref); // ✅ CSRF requerido

    try {
      final response = await _dio.get(
        '/',
        queryParameters: {
        'limit': 10,  //cambiar a 'limit' y cambiar el valor de limit en TODAS las peticiones
        'page': page,
        'orderBy': orderBy,
        'direction': direction,
        if ( loggedUser != null ) 'loggedUser': loggedUser,
        if (userId != null) 'userId': userId,
      },
        options: Options(
          headers: {
            'X-CSRF-Token': _csrfToken,
          },
        ),
      );

      //await Future.delayed(const Duration(seconds: 1));

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
  Future<Response<dynamic>> deleteTrack(WidgetRef ref, String id) async {

    await _fetchCsrfToken(ref); // ✅ CSRF requerido

    try {
      final response = await _dio.delete(
        '/$id',
        options: Options(
          headers: {
            'X-CSRF-Token': _csrfToken,
          },
        ),
      );

      if (response.statusCode == 200) {

        return response;
      } else {
        return response;
      }

    } catch (e) {
      return Response(requestOptions: RequestOptions(), statusCode: 500, statusMessage: 'Error al eliminar el track: $e');
    }


  }
  
  @override
  Future<Track?> existsTrack(String name, String? loggedUser) async {

    final finalName = name.replaceAll('.gpx', '');

    
    try {
      final response = await _dio.get(
        '/track/$finalName' ,
        queryParameters: {
          'loggedUser': loggedUser
        },
        options: Options(
          headers: {
            'X-CSRF-Token': _csrfToken,
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final track = Track.fromJson(response.data); // ✅ Usa tu modelo Track
        return track;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }

      

    


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

  @override
  Future<List<Track>> getNearestTracks(String trackId, String? loggedUser, {int limit = 5}) async {
    final response = await _dio.get('/nearest/$trackId', 
    queryParameters: {
      'limit': limit,
      if ( loggedUser != null ) 'loggedUser': loggedUser,
    });

    final List<dynamic> data = response.data;
    return data.map((json) => Track.fromJson(json)).toList();
  }


  @override
  Future<Response<dynamic>> updateTrack(WidgetRef ref, String id, String name, String description, {List<String> imagesOld = const[], List<File> images = const []}) async {

    try {

      await _fetchCsrfToken(ref); // ✅ CSRF requerido

      final formData = FormData.fromMap({
        'name': name,
        'description': description,
        'imagesOld': imagesOld,
        
        if (images.isNotEmpty) 
          'images': await Future.wait(images.map((img) async {
            return await MultipartFile.fromFile(img.path, filename: img.uri.pathSegments.last);
          })),
      });

      final response = await _dio.put(
        '/$id',
        data: formData,
        options: Options(
          headers: {
            'X-CSRF-Token': _csrfToken,
          },
        ),
      );

      if (response.statusCode == 200) {
        return response;
      } else {
        return Response(requestOptions: RequestOptions(), statusCode: response.statusCode, statusMessage: 'Error al actualizar el track');
      }

      
    } catch (e) {

      return Response(requestOptions: RequestOptions(), statusCode: 500, statusMessage: 'Error al actualizar el track');
      
    }


  }
  
  @override
  Future<void> addFavorite(WidgetRef ref, String trackId, UserEntity userLogged) async {

    await _fetchCsrfToken(ref); // ✅ CSRF requerido

    final response = await _dio.post(
      '/favorites/$trackId',
      queryParameters: {
        'loggedUser': userLogged.id
      },
      options: Options(
        headers: {
          'X-CSRF-Token': _csrfToken,
        },
      ),
    );

    if( response.statusCode == 200) {
      print('✅ Favorito añadido: $trackId');
    } else {
      throw Exception('❌ Error al añadir favorito: ${response.statusCode}');

    }

  }
  
  @override
  Future<void> removeFavorite(WidgetRef ref, String trackId, UserEntity userLogged) async {

    await _fetchCsrfToken(ref); // ✅ CSRF requerido

    final response = await _dio.delete(
      '/favorites/$trackId',
      queryParameters: {
        'loggedUser': userLogged.id
      },
      options: Options(
        headers: {
          'X-CSRF-Token': _csrfToken,
        },
      ),
    );

    if( response.statusCode == 200) {
      print('✅ Favorito eliminado: $trackId');
    } else {
      throw Exception('❌ Error al eliminar favorito: ${response.statusCode}');

    }

  }




  //https://cookies.argomez.com/api/tracks?limit=10&page=1&userId=23235555
}
