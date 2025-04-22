import 'package:ladamadelcanchoapp/domain/entities/location_point.dart';

class PendingTrack {
  final String userId;
  final DateTime timestamp;
  final bool isTracking;
  final bool isPaused;
  final double distance;
  final double elevationGain;
  final List<LocationPoint> points;
  final List<LocationPoint> discardedPoints;
  final String mode;

  PendingTrack({
    required this.userId,
    required this.timestamp,
    required this.isTracking,
    required this.isPaused,
    required this.distance,
    required this.elevationGain,
    required this.points,
    required this.discardedPoints,
    required this.mode,
  });

  factory PendingTrack.fromMap(Map<String, dynamic> map) {
    return PendingTrack(
      userId: map['userId'],
      timestamp: DateTime.parse(map['timestamp']),
      isTracking: map['state']['isTracking'],
      isPaused: map['state']['isPaused'],
      distance: (map['state']['distance'] as num).toDouble(),
      elevationGain: (map['state']['elevationGain'] as num).toDouble(),
      points: (map['state']['points'] as List)
          .map((p) => LocationPoint.fromMap(p))
          .toList(),
      discardedPoints: (map['state']['discardedPoints'] as List)
          .map((p) => LocationPoint.fromMap(p))
          .toList(),
      mode: map['state']['mode'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
      'state': {
        'isTracking': isTracking,
        'isPaused': isPaused,
        'distance': distance,
        'elevationGain': elevationGain,
        'points': points.map((p) => p.toMap()).toList(),
        'discardedPoints': discardedPoints.map((p) => p.toMap()).toList(),
        'mode': mode,
      }
    };
  }
}
