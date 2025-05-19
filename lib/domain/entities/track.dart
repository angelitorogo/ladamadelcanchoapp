import 'package:ladamadelcanchoapp/domain/entities/location_point.dart';
import 'package:ladamadelcanchoapp/domain/entities/user.dart';

class Track {
  final String id;
  final String userId;
  final String name;
  final String distance;
  final String elevationGain;
  final String? description;
  final String? type;
  final List<String>? images;
  final List<LocationPoint>? points;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserEntity user;

  Track({
    required this.id,
    required this.userId,
    required this.name,
    required this.distance,
    required this.elevationGain,
    this.description,
    this.type,
    this.images,
    this.points,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
  });

  factory Track.fromJson(Map<String, dynamic> json) => Track(
    id: json['id'],
    userId: json['userId'],
    name: json['name'],
    distance: json['distance'].toString(),
    elevationGain: json['elevation_gain'].toString(),
    description: json['description'],
    type: json['type'],
    images: (json['images'] as List?)?.map((e) => e.toString()).toList(),
    points: (json['points'] as List?)?.map((p) => LocationPoint.fromMap(p)).toList(),
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
    user: UserEntity.fromJson(json['user']),
  );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'distance': distance,
        'elevation_gain': elevationGain,
        'description': description,
        'type': type,
        'images': images,
        'points': points?.map((p) => p.toMap()).toList(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'user': user.toJson(),
      };
}
