import 'package:flutter/material.dart';
import 'package:wms_app/features/info_rapida/domain/entities/config_info_rapida_usuario.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida.dart';
import 'package:wms_app/features/info_rapida/presentation/pages/location_info_page.dart';
import 'package:wms_app/features/info_rapida/presentation/pages/paquete_info_page.dart';
import 'package:wms_app/features/info_rapida/presentation/pages/product_info_page.dart';

/// Navegación interna del módulo. Cada página crea su propio bloc y recibe
/// por argumento solo la entity que necesita (no se pasa un bloc entre rutas
/// como en el legacy).
class InfoRapidaNavigator {
  const InfoRapidaNavigator._();

  /// Abre el detalle que corresponde al tipo de resultado.
  static Future<void> abrirResultado(
    BuildContext context,
    InfoRapida info, {
    required ConfigInfoRapidaUsuario config,
  }) {
    final page = switch (info) {
      ProductoInfo p => ProductInfoPage(producto: p, config: config),
      UbicacionInfo u => LocationInfoPage(ubicacion: u, config: config),
      PaqueteInfo pq => PaqueteInfoPage(paquete: pq, config: config),
    };
    return Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}
