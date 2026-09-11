// ignore_for_file: file_names

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/transfer-interna/bloc/transferencia_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';

class DialogTransferencia extends StatelessWidget {
  const DialogTransferencia({
    super.key,
    required this.contextHome,
  });

  final BuildContext contextHome;

  Future<void> _goToInterna(BuildContext context) async {
    // Misma operación que hacía el onTap de "Transferencia" antes de existir
    // este selector: cargar ubicaciones/novedades/locations, mostrar el
    // loading y navegar a la lista de transferencias internas.
    if (contextHome.read<UserBloc>().ubicaciones.isEmpty) {
      contextHome.read<UserBloc>().add(LoadUserLocationsEvent());
    }
    contextHome.read<TransferenciaBloc>().add(LoadAllNovedadesTransferEvent());
    contextHome.read<TransferenciaBloc>().add(LoadLocations());

    // Cerramos este diálogo de selección antes de mostrar el de carga.
    Navigator.pop(context);

    showDialog(
      context: contextHome,
      builder: (context) => const DialogLoading(
        message: 'Cargando interfaz...',
      ),
    );
    await Future.delayed(const Duration(seconds: 1));
    if (!contextHome.mounted) return;
    Navigator.pop(contextHome);
    Navigator.pushReplacementNamed(
      contextHome,
      'transferencias',
    );
  }

  void _goToMultiusuario(BuildContext context) {
    Navigator.pop(context);
    Navigator.pushReplacementNamed(
      contextHome,
      'list-transferencia-multiusuario',
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        backgroundColor: Colors.white,
        actionsAlignment: MainAxisAlignment.center,
        title: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('SELECCIÓN DE TRANSFERENCIA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryColorApp,
                  fontSize: 16,
                )),
            const SizedBox(height: 10),
            Center(
              child: Text(
                  'Seleccione una de las siguientes opciones para realizar el proceso de transferencia',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: black,
                    fontSize: 12,
                  )),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
                onPressed: () => _goToInterna(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 40),
                  backgroundColor: primaryColorApp,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('TRANSFERENCIA INTERNA',
                    style: TextStyle(
                      color: white,
                      fontSize: 12,
                    ))),
            ElevatedButton(
                onPressed: () => _goToMultiusuario(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 40),
                  backgroundColor: primaryColorApp,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('TRANSFERENCIA MULTIUSUARIO',
                    style: TextStyle(
                      color: white,
                      fontSize: 12,
                    ))),
            ElevatedButton(
                onPressed: () {
                  //cerramos el dialogo
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: grey,
                  minimumSize: const Size(200, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('CANCELAR',
                    style: TextStyle(
                      color: white,
                      fontSize: 12,
                    ))),
          ],
        )),
      ),
    );
  }
}
