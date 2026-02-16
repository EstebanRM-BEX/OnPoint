import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';

class ErrorDialog {
  static void show({
    required String error,
    required Map<String, dynamic> request,
    Color primaryColor =
        const Color(0xFF1976D2), // por si no defines `primaryColorApp`
  }) {
    Get.defaultDialog(
      title: '',
      contentPadding: const EdgeInsets.all(0),
      backgroundColor: Colors.white,
      radius: 10,
      content: Container(
        height: 400,
        color: Colors.white,
        child: Column(
          children: [
            // Encabezado con botón de cerrar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '360 Software Informa',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
            ),
            // Contenido scrollable
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Error en la petición",
                      style: TextStyle(fontSize: 12, color: black),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error,
                      style: const TextStyle(fontSize: 10),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Request:",
                      style: TextStyle(fontSize: 12, color: black),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        const JsonEncoder.withIndent('  ').convert(request),
                        style: const TextStyle(
                            fontFamily: 'Courier', fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColorApp,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Aceptar',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
