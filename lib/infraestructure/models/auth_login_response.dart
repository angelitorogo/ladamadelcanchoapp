
class AuthLoginResponse {
    final int statusCode;
    final String message;
    final String csrfToken;

    AuthLoginResponse({
        required this.statusCode,
        required this.message,
        required this.csrfToken,
    });

    factory AuthLoginResponse.fromJson(Map<String, dynamic> json) => AuthLoginResponse(
        statusCode: json["statusCode"] ?? 0,
        message: json["message"] ?? '',
        csrfToken: json["csrfToken"] ?? '',
    );

    Map<String, dynamic> toJson() => {
        "statusCode": statusCode,
        "message": message,
        "csrfToken": csrfToken,
    };
}
