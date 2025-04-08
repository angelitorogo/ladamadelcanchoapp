import 'package:location/location.dart';
import 'package:ladamadelcanchoapp/domain/datasources/location_datasource.dart';
import '../../domain/entities/location_point.dart';

class LocationDatasourceImpl implements LocationDatasource {
  final Location location = Location();
  LocationPoint? _lastPoint;

  @override
  Stream<LocationPoint> getLocationStream() {
    location.changeSettings(
      accuracy: LocationAccuracy.navigation,
      interval: 2000,
      distanceFilter: 0,
    );

    return location.onLocationChanged
      // Primero filtramos por precisión horizontal (accuracy)
      .where((locData) => locData.accuracy != null && locData.accuracy! <= 20)
      // Después filtramos diferencias de elevación exageradas
      .where((locData) {
        if (_lastPoint == null || locData.altitude == null) {
          // Primer punto o sin elevación, se acepta por defecto
          return true;
        }

        final elevDiff = (locData.altitude! - _lastPoint!.elevation).abs();
        
        // 👇 Ajusta este valor según tu caso (ej.: 10 metros máximo)
        /*
          10 metros: Valor recomendado para senderismo o rutas normales.
          5 metros: Si buscas tracks muy suaves (terreno bastante llano).
          15 metros o más: Solo si realizas rutas en montaña con terreno irregular (puede incluir cambios bruscos reales).
        */
        const maxElevationChange = 15.0;

        if (elevDiff <= maxElevationChange) {
          return true;
        } else {
          // Elevación demasiado brusca, se descarta este punto
          return false;
        }
      })
      .map((locData) {
        final point = LocationPoint(
          latitude: locData.latitude!,
          longitude: locData.longitude!,
          elevation: locData.altitude ?? (_lastPoint?.elevation ?? 0),
          timestamp: DateTime.fromMillisecondsSinceEpoch(locData.time!.toInt()),
        );
        // Guarda referencia del último punto válido
        _lastPoint = point;
        return point;
      });
  }
}
