import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {

  static String apiUrl = dotenv.env['API_URL'] ?? 'sin url de backend';
  
}


class ColorsPeronalized {

  static const Color successColor = Color(0xFF036630); 
  static const Color cancelColor = Color(0xFF610909);
  static const Color infoColor = Color(0xFF042681); 


}