
class AllTracksResponse {
    final List<Track> tracks;
    final Metadata metadata;

    AllTracksResponse({
        required this.tracks,
        required this.metadata,
    });

    factory AllTracksResponse.fromJson(Map<String, dynamic> json) => AllTracksResponse(
        tracks: List<Track>.from(json["tracks"].map((x) => Track.fromJson(x))),
        metadata: Metadata.fromJson(json["metadata"]),
    );

    Map<String, dynamic> toJson() => {
        "tracks": List<dynamic>.from(tracks.map((x) => x.toJson())),
        "metadata": metadata.toJson(),
    };
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
        id: json["id"],
        userId: json["userId"],
        name: json["name"],
        distance: json["distance"],
        elevationGain: json["elevation_gain"],
        description: json["description"],
        images: json["images"] == null ? [] : List<String>.from(json["images"]!.map((x) => x)),
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "userId": userId,
        "name": name,
        "distance": distance,
        "elevation_gain": elevationGain,
        "description": description,
        "images": images == null ? [] : List<dynamic>.from(images!.map((x) => x)),
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
    };
}
