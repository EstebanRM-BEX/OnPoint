import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/info_rapida/domain/entities/config_info_rapida_usuario.dart';
import 'package:wms_app/features/info_rapida/domain/entities/info_rapida.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/cards/paquete_cards.dart';
import 'package:wms_app/features/info_rapida/presentation/widgets/common/info_rapida_header.dart';

/// Detalle de un paquete y los productos que contiene (solo lectura).
class PaqueteInfoPage extends StatelessWidget {
  final PaqueteInfo paquete;
  final ConfigInfoRapidaUsuario config;

  const PaqueteInfoPage({
    super.key,
    required this.paquete,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      body: Column(
        children: [
          InfoRapidaHeader(onBack: () => Navigator.pop(context)),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: SizedBox(
              width: double.infinity,
              child: PaqueteDetailCard(paquete: paquete),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 10, left: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Productos',
                style: TextStyle(
                  color: black,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: paquete.productos.length,
                itemBuilder: (_, index) =>
                    PaqueteProductoCard(producto: paquete.productos[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
