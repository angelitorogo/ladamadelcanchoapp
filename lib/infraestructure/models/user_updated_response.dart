
class UserUpdatedResponse {
    final String id;
    final String email;
    final String fullname;
    final String password;
    final String role;
    final String telephone;
    final String image;
    final bool active;
    final int theme;
    final DateTime createdAt;
    final DateTime updatedAt;
    final String language;

    UserUpdatedResponse({
        required this.id,
        required this.email,
        required this.fullname,
        required this.password,
        required this.role,
        required this.telephone,
        required this.image,
        required this.active,
        required this.theme,
        required this.createdAt,
        required this.updatedAt,
        required this.language,
    });

    factory UserUpdatedResponse.fromJson(Map<String, dynamic> json) => UserUpdatedResponse(
        id: json["id"],
        email: json["email"],
        fullname: json["fullname"],
        password: json["password"],
        role: json["role"],
        telephone: json["telephone"],
        image: json["image"],
        active: json["active"],
        theme: json["theme"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        language: json["language"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "email": email,
        "fullname": fullname,
        "password": password,
        "role": role,
        "telephone": telephone,
        "image": image,
        "active": active,
        "theme": theme,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "language": language,
    };
}
