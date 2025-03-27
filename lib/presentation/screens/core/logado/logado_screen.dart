import 'package:flutter/material.dart';

class LogadoScreen extends StatelessWidget {

  static const name = 'logado-screen';

  const LogadoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Protegida'),
      ),
      body: const Center(
        child: Text('Ruta protegida, estas logado'),
      ),
    );
  }
}