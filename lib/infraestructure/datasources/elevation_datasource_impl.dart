import 'dart:async';
import 'package:dio/dio.dart';
import 'package:ladamadelcanchoapp/domain/datasources/elevation_datasource.dart';
import 'package:ladamadelcanchoapp/domain/entities/location_point.dart';
import 'package:ladamadelcanchoapp/infraestructure/models/corrected_elevation_response.dart';

class ElevationDatasourceImpl implements ElevationDatasource {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.open-elevation.com/api',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  @override
  Future<List<LocationPoint>> getElevations(List<LocationPoint> points) async {

    final locations = points.map((p) => '${p.latitude},${p.longitude}').join('|');

    //print('📍 Puntos Originales: $locations');

    try {

      final response = await _dio.get(
      'https://api.opentopodata.org/v1/mapzen', // 🔁 URL completa, ignora el baseUrl
      queryParameters: {
        'locations': locations,
      },
    );

      if (response.statusCode == 200 && response.data['results'] != null) {
        final results = response.data['results'] as List;

        //print('📍${results.length}, Puntos corregidos: ${response.data['results']}');


        return List.generate(points.length, (i) {
          final orig = points[i];
          final ele = results[i]['elevation'] ?? orig.elevation;
          return LocationPoint(
            latitude: orig.latitude,
            longitude: orig.longitude,
            elevation: ele.toDouble(),
            timestamp: orig.timestamp,
          );
        });
      }

      throw Exception('❌ Error en respuesta OpenElevation: ${response.statusCode}');
    } catch (e) {
      throw Exception('❌ No se pudo obtener elevaciones: $e');
    }
  }

  @override
  Future<CorrectedElevationResponse> getElevationForPoint(LocationPoint point) async {
    try {
      final response = await _dio.get(
        'https://api.opentopodata.org/v1/mapzen', // 🔁 URL completa para ignorar el baseUrl global
        queryParameters: {
          'locations': '${point.latitude},${point.longitude}',
        },
      );

      if (response.statusCode == 200 &&
          response.data['results'] != null &&
          response.data['results'].isNotEmpty) {
        final ele = response.data['results'][0]['elevation'];

        //print('📍 Punto corregido. Original: ${point.elevation} - Corregido: $ele');

        return CorrectedElevationResponse(
          point: LocationPoint(
            latitude: point.latitude,
            longitude: point.longitude,
            elevation: ele.toDouble(),
            timestamp: point.timestamp,
          ),
          corrected: true,
        );
      }

      //print('📍 Punto NO corregido. Original: ${point.elevation}');

      // Si no hay elevación válida
      return CorrectedElevationResponse(
        point: point,
        corrected: false,
      );
    } catch (_) {
      // En caso de error, fallback sin corrección
      //print('📍 Punto NO corregido. Original: ${point.elevation}');
      return CorrectedElevationResponse(
        point: point,
        corrected: false,
      );
    }
  }



}
