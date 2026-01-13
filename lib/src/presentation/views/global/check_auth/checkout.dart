// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:wms_app/src/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/src/services/webSocket_service.dart'; // Ajusta la ruta si es necesario

class CheckAuthPage extends StatelessWidget {
  const CheckAuthPage({super.key});

  /// Lógica principal de validación
  Future<bool> validateSession() async {
    // 1. Paso Básico: ¿Existe el flag de "logueado"?
    bool isLoggedIn = await PrefUtils.getIsLoggedIn();
    if (!isLoggedIn) {
      return false; // No hay sesión, ir al login
    }

    // 2. Paso de Seguridad: ¿Cuánto tiempo pasó desde la última vez que usó la app?
    // Esto cubre el caso cuando el usuario "mata" la app y vuelve horas después.
    final lastActive = await PrefUtils.getLastActiveTime();

    if (lastActive != null) {
      final now = DateTime.now();
      final difference = now.difference(lastActive);

      // ⚠️ CONFIGURACIÓN: Ajusta esto según tu regla de negocio (ej. 1 hora)
      // Para pruebas rápidas puedes usar: if (difference.inSeconds >= 10)
      if (difference.inHours >= 1) {
        print(
            "💀 Sesión expirada (App cerrada durante ${difference.inMinutes} mins). Forzando logout...");

        // Limpiamos la sesión usando el método nuevo que agregamos a PrefUtils
        await PrefUtils.clearSession();
        return false; // Sesión inválida
      }
    }

    // 3. Éxito: La sesión es válida y está a tiempo.
    // Actualizamos la hora actual para reiniciar el contador de esta nueva sesión.
    await PrefUtils.saveLastActiveTime();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // O el color de tu marca
      body: Center(
        child: FutureBuilder<bool>(
          future: validateSession(),
          builder: (context, snapshot) {
            // A. ESTADO CARGANDO
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            // B. ESTADO ERROR (Técnico)
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error al validar sesión:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            // C. ESTADO FINALIZADO (Tenemos un true o false)
            if (snapshot.hasData) {
              final bool isSessionValid = snapshot.data!;

              // Usamos addPostFrameCallback para navegar de forma segura
              // esto evita el error de "setState() or markNeedsBuild() called during build"
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (isSessionValid) {
                  // ✅ Sesión válida -> Vamos al Home
                  // Como la sesión es válida, reconectamos el socket antes de ir al Home.
                  // El método connect() ya tiene validaciones internas, así que es seguro.
                  WebSocketService().connect();
                  Navigator.pushReplacementNamed(context, '/home');
                } else {
                  // ❌ Sesión inválida/expirada -> Vamos al Login (Enterprice)
                  Navigator.pushReplacementNamed(context, 'enterprice');
                }
              });

              // Mientras navega, mostramos un contenedor vacío o el loader
              return Container();
            }

            return const CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}
