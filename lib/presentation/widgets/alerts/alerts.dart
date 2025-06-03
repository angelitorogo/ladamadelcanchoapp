import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void mostrarAlerta(BuildContext context, String mensaje, Color color) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog( // ⬅ Usamos `Dialog` para más control
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: SizedBox(
            width: 300, // ⬅ Define el ancho de la alerta
            height: 300,
            child: AlertDialog(
              titlePadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: color, size: 28),
                  const SizedBox(height: 10),
                  const Text('Alerta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Text(
                mensaje,
                textAlign: TextAlign.center, // 🔥 Centra el texto
                style: const TextStyle(fontSize: 17),
              ),
              actions: [
                Center(
                  child: SizedBox(
                    width: 150,
                    height: 50,
                    child: TextButton(
                      onPressed: () {

                        if(mensaje == "Token inválido o expirado") {
                          Future.delayed(const Duration(milliseconds: 200), () {
                            if(context.mounted) {
                              GoRouter.of(context).go('/login');
                            }
                          });
                        }

                        Navigator.of(context).pop();

                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: const Text(
                        'Aceptar',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void mostrarAlertaSuccess(BuildContext context, String mensaje, {String? redirectRoute}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(height: 10),
              Text('Hecho!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: 150,
              height: 50,
              child: TextButton(
                onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
                if (redirectRoute != null) {
                  Future.delayed(const Duration(milliseconds: 200), () {
                    if( context.mounted) {
                      GoRouter.of(context).go(redirectRoute);
                    }
                  });
                }
              },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text(
                  'Aceptar',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
