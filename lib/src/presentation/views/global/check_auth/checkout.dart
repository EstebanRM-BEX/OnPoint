// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:wms_app/src/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/src/services/webSocket_service.dart';

class CheckAuthPage extends StatefulWidget {
  const CheckAuthPage({super.key});

  @override
  State<CheckAuthPage> createState() => _CheckAuthPageState();
}

class _CheckAuthPageState extends State<CheckAuthPage> {
  @override
  void initState() {
    super.initState();
    _validateSession();
  }

  /// Lógica principal de validación
  Future<void> _validateSession() async {
    // 1. Paso Básico: ¿Existe el flag de "logueado"?
    bool isLoggedIn = await PrefUtils.getIsLoggedIn();
    if (!isLoggedIn) {
      _navigateTo('enterprice');
      return;
    }

    // 2. Paso de Seguridad: ¿Cuánto tiempo pasó desde la última vez que usó la app?
    final lastActive = await PrefUtils.getLastActiveTime();

    if (lastActive != null) {
      final now = DateTime.now();
      final difference = now.difference(lastActive);

      // Límite de 1 hora
      if (difference >= const Duration(hours: 1)) {
        print(
          "💀 Sesión expirada (App cerrada durante ${difference.inMinutes} mins). Forzando logout...",
        );

        // Limpiamos la sesión
        await PrefUtils.clearSession();
        _navigateTo('enterprice');
        return;
      }
    }

    // 3. Éxito: La sesión es válida y está a tiempo.
    // Actualizamos la hora actual para reiniciar el contador de esta nueva sesión.
    await PrefUtils.saveLastActiveTime();

    // Reconectamos el socket antes de ir al Home
    WebSocketService().connect();

    _navigateTo('/home');
  }

  void _navigateTo(String routeName) {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
