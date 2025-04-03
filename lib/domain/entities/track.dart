class Track {
  final String id;
  final String userId;
  final String name;
  final String distance;
  final String elevationGain;
  final String? description;
  final List<String>? images;
  final DateTime createdAt;
  final DateTime updatedAt;

  Track({
    required this.id,
    required this.userId,
    required this.name,
    required this.distance,
    required this.elevationGain,
    this.description,
    this.images,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Track.fromJson(Map<String, dynamic> json) => Track(
        id: json['id'],
        userId: json['userId'],
        name: json['name'],
        distance: json['distance'],
        elevationGain: json['elevation_gain'],
        description: json['description'],
        images: (json['images'] as List?)?.map((e) => e.toString()).toList(),
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'distance': distance,
        'elevation_gain': elevationGain,
        'description': description,
        'images': images,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
