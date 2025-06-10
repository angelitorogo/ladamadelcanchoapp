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
  final UserEntity? user;
  final double? distanceFromCurrent;
  final bool isFavorite;

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
    this.user,
    this.distanceFromCurrent,
    required this.isFavorite
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
    distanceFromCurrent: json['distanceFromCurrent'],
    isFavorite: json['isFavorite'] ?? false,
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
    'user': user?.toJson(),
    'distanceFromCurrent': distanceFromCurrent,
    'isFavorite': isFavorite,
  };

    Track copyWith({
    String? id,
    String? userId,
    String? name,
    String? distance,
    String? elevationGain,
    String? description,
    String? type,
    List<String>? images,
    List<LocationPoint>? points,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserEntity? user,
    double? distanceFromCurrent,
    bool? isFavorite,
  }) {
    return Track(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      distance: distance ?? this.distance,
      elevationGain: elevationGain ?? this.elevationGain,
      description: description ?? this.description,
      type: type ?? this.type,
      images: images ?? this.images,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      user: user ?? this.user,
      distanceFromCurrent: distanceFromCurrent ?? this.distanceFromCurrent,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }


}


class Metadata {
    final int totalTracks;
    final int page;
    final int lastPage;

    Metadata({
        required this.totalTracks,
        required this.page,
        required this.lastPage,
    });

    factory Metadata.fromJson(Map<String, dynamic> json) => Metadata(
        totalTracks: json["totalTracks"],
        page: json["page"],
        lastPage: json["lastPage"],
    );

    Map<String, dynamic> toJson() => {
        "totalTracks": totalTracks,
        "page": page,
        "lastPage": lastPage,
    };
}