import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MenuItem {
  final String title;
  final String? link;
  final IconData icon;
  final void Function(WidgetRef ref)? onTap; // ✅ Función opcional

  const MenuItem({
    required this.title, 
    this.link, // ✅ No siempre es obligatorio
    required this.icon,
    this.onTap, // ✅ Función opcional
  });
  
}

