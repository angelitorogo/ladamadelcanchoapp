
class AuthVerifyUserResponse {
    final bool isLogged;
    final User user;

    AuthVerifyUserResponse({
        required this.isLogged,
        required this.user,
    });

    factory AuthVerifyUserResponse.fromJson(Map<String, dynamic> json) => AuthVerifyUserResponse(
        isLogged: json["isLogged"],
        user: User.fromJson(json["user"]),
    );

    Map<String, dynamic> toJson() => {
        "isLogged": isLogged,
        "user": user.toJson(),
    };
}

class User {
    final String id;
    final String email;
    final String fullname;
    final String role;
    final String telephone;
    final String image;
    final bool active;
    final int theme;
    final DateTime createdAt;
    final DateTime updatedAt;
    final String language;

    User({
        required this.id,
        required this.email,
        required this.fullname,
        required this.role,
        required this.telephone,
        required this.image,
        required this.active,
        required this.theme,
        required this.createdAt,
        required this.updatedAt,
        required this.language,
    });

    factory User.fromJson(Map<String, dynamic> json) => User(
        id: json["id"],
        email: json["email"],
        fullname: json["fullname"],
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
