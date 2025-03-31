import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:ladamadelcanchoapp/domain/datasources/track_datasource.dart';
import 'package:ladamadelcanchoapp/infraestructure/utils/global_cookie_jar.dart';
import 'package:ladamadelcanchoapp/presentation/providers/auth/auth_provider.dart';

class TrackDatasourceImpl implements TrackDatasource {
  
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://cookies.argomez.com/api/tracks',
    followRedirects: false,
    validateStatus: (status) => status != null && status < 500,
  ));

  final _cookieJar = GlobalCookieJar.instance;
  String? _csrfToken;

  TrackDatasourceImpl() {
    _dio.interceptors.add(CookieManager(_cookieJar));
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
  Future<Map<String, dynamic>> uploadTrack(String name, File gpxFile) async {
    
    await _fetchCsrfToken(); // ✅ CSRF requerido

    final formData = FormData.fromMap({
      'name': name,
      'gpx': await MultipartFile.fromFile(
        gpxFile.path,
        filename: gpxFile.uri.pathSegments.last,
      ),
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
}
