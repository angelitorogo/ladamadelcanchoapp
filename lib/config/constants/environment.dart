import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {

  static String apiUrl = dotenv.env['API_URL'] ?? 'sin url de backend';
  
}