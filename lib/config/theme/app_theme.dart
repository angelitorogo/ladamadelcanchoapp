import 'package:flutter/material.dart';

class AppTheme {

ThemeData getTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorSchemeSeed: const Color(0xFF2862F5)
);

}