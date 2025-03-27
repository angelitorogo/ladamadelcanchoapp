import 'package:flutter/material.dart';

class NoLogadoScreen extends StatelessWidget {

  static const name = 'no-logado-screen';

  const NoLogadoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('No protegida'),
      ),
      body: const Center(
        child: Text('Ruta no protegida'),
      ),
    );
  }
}