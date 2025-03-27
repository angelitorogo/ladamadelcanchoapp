
class Auth {
  final String csrfToken;
  final int statusCode;
  final String message;


  Auth({
    required this.csrfToken,
    required this.statusCode,
    required this.message,
  });
  
}