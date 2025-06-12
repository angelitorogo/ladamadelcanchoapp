import 'package:flutter/material.dart';

class WeatherCodeIcon {
  static Icon getIcon(int code) {
    if ([0].contains(code)) return const Icon(Icons.wb_sunny, color: Colors.orange); // Soleado
    if ([1, 2].contains(code)) return const Icon(Icons.wb_cloudy, color: Colors.grey); // Parcial
    if ([3].contains(code)) return const Icon(Icons.cloud, color: Colors.blueGrey); // Nublado
    if ([45, 48].contains(code)) return const Icon(Icons.foggy, color: Colors.grey); // Niebla
    if ([51, 53, 55, 61, 63, 65, 80, 81, 82].contains(code)) {
      return const Icon(Icons.grain, color: Colors.blue); // Lluvia
    }
    if ([71, 73, 75, 85, 86].contains(code)) return const Icon(Icons.ac_unit, color: Colors.lightBlue); // Nieve
    if ([95, 96, 99].contains(code)) return const Icon(Icons.bolt, color: Colors.deepPurple); // Tormenta
    return const Icon(Icons.help_outline); // Desconocido
  }
}


class WeatherEmoji {
  static String getEmoji(int code) {
    if ([0].contains(code)) return '☀️';       // Soleado
    if ([1, 2].contains(code)) return '🌤️';    // Parcialmente nublado
    if ([3].contains(code)) return '☁️';       // Nublado
    if ([45, 48].contains(code)) return '🌫️';  // Niebla
    if ([51, 53, 55].contains(code)) return '🌦️'; // Llovizna
    if ([61, 63, 65, 80, 81, 82].contains(code)) return '🌧️'; // Lluvia
    if ([71, 73, 75, 85, 86].contains(code)) return '🌨️'; // Nieve
    if ([95, 96, 99].contains(code)) return '🌩️'; // Tormenta
    return '❓'; // Desconocido
  }
}