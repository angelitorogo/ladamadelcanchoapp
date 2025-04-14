import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:ladamadelcanchoapp/domain/datasources/track_datasource.dart';
import 'package:ladamadelcanchoapp/infraestructure/utils/global_cookie_jar.dart';

class TrackDatasourceImpl implements TrackDatasource {
  
  
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://cookies.argomez.com/api/tracks',
    followRedirects: false,
    validateStatus: (status) => status != null && status < 500,
  ));

  //final _cookieJar = GlobalCookieJar.instance;
  late final CookieJar _cookieJar;
  String? _csrfToken;

  TrackDatasourceImpl() {
    GlobalCookieJar.instance.then((jar) {
      _cookieJar = jar;
      _dio.interceptors.add(CookieManager(_cookieJar));
    });
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
        return;
      }

      throw Exception('Error CSRF: ${response.statusCode}');
    } catch (e) {
      throw Exception('❌ No se pudo obtener CSRF: $e');
    }
  }




  @override
  Future<Map<String, dynamic>> uploadTrack(String name, File gpxFile, String description, String type, String distance, String elevationGain, {List<File> images = const[]}) async {
    
    await _fetchCsrfToken(); // ✅ CSRF requerido

    //print('✅ Images3: $images');

    final formData = FormData.fromMap({
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
  Future<Map<String, dynamic>> loadAllTracks({int limit = 10, int offset = 0, String? userId}) async {

    //await _fetchCsrfToken(); // ✅ CSRF requerido

    try {
      final response = await _dio.get(
        '/',
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
      throw Exception('❌ Error: $e');
    }

    
  }


  //https://cookies.argomez.com/api/tracks?limit=10&page=1&userId=23235555
}
