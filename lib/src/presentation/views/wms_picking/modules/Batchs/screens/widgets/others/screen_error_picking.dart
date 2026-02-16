import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';

class ErrorPicking extends StatelessWidget {
  const ErrorPicking({
    super.key,
    required this.size,
  });

  final Size size;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 100,
              width: 200,
              child: Image.asset(
                "assets/images/logo.jpeg",
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Error al cargar los datos...",
              style: TextStyle(fontSize: 18, color: black),
            ),
            const Text(
              "Comprueba tu conexión a internet",
              style: TextStyle(fontSize: 16, color: black),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: Size(size.width * 0.6, 40),
                ),
                child: const Text(
                  "Atras",
                  style: TextStyle(color: white, fontSize: 16),
                ))
          ],
        ),
      ),
    );
  }
}

  
