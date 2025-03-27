
class UserEntity {
  final String id;
  final String email;
  final String fullname;
  final String role;
  final String? telephone;
  final String? image;
  final bool active;
  final int theme;
  //final DateTime createdAt;
  //final DateTime updatedAt;
  final String language;

  UserEntity({
    required this.id,
    required this.email,
    required this.fullname,
    required this.role,
    this.telephone,
    this.image,
    required this.active,
    required this.theme,
    //required this.createdAt,
    //required this.updatedAt,
    required this.language,
  });

  // ✅ Convertir JSON a UserEntity
  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullname: json['fullname'] ?? '',
      role: json['role'] ?? '',
      telephone: json['telephone'],
      image: json['image'],
      active: json['active'] ?? false,
      theme: json['theme'] ?? 0,
      //createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime(1970, 1, 1),
      //updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime(1970, 1, 1),
      language: json['language'] ?? 'es',
    );
  }

  // ✅ Convertir UserEntity a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullname': fullname,
      'role': role,
      'telephone': telephone,
      'image': image,
      'active': active,
      'theme': theme,
      //'createdAt': createdAt.toIso8601String(),
      //'updatedAt': updatedAt.toIso8601String(),
      'language': language,
    };
  }


}
