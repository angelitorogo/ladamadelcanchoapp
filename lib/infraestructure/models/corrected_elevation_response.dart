
import 'package:ladamadelcanchoapp/domain/entities/location_point.dart';

class CorrectedElevationResponse {
  final LocationPoint point;
  final bool corrected;

  CorrectedElevationResponse({required this.point, required this.corrected});
}