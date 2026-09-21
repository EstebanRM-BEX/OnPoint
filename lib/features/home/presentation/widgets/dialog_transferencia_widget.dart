import 'package:flutter/material.dart';
import 'package:wms_app/shared/widgets/selection_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/transfer-interna/bloc/transferencia_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';

class DialogTransferencia extends StatelessWidget {
  const DialogTransferencia({super.key, required this.contextHome});

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
      builder: (context) =>
          const DialogLoading(message: 'Cargando interfaz...'),
    );
    await Future.delayed(const Duration(seconds: 1));
    if (!contextHome.mounted) return;
    Navigator.pop(contextHome);
    Navigator.pushReplacementNamed(contextHome, 'transferencias');
  }

  void _goToMultiusuario(BuildContext context) {
    Navigator.pop(context);
    Navigator.pushReplacementNamed(
      contextHome,
      'list-transferencia-multiusuario',
    );
  }

  void _goToCrear(BuildContext context) {
    // CreateTransferBloc ahora vive escopeado a la ruta 'create-transfer' y
    // es la propia pantalla (CreateTransferScreen.initState) la que dispara
    // la carga inicial — acá solo navegamos.
    Navigator.pop(context);
    Navigator.pushReplacementNamed(contextHome, 'create-transfer');
  }

  @override
  Widget build(BuildContext context) {
    return SelectionDialog(
      icon: Icons.sync_alt,
      title: 'Selección de Transferencia',
      message:
          'Seleccione una de las siguientes opciones para realizar el '
          'proceso de transferencia',
      options: [
        SelectionOption(
          title: 'Traslado Interno',
          description: 'Movimiento entre ubicaciones de la bodega',
          icon: Icons.swap_horiz,
          onTap: () => _goToInterna(context),
        ),
        SelectionOption(
          title: 'Traslado Multiusuario',
          description: 'Varios operarios en un mismo traslado',
          icon: Icons.groups_outlined,
          onTap: () => _goToMultiusuario(context),
        ),
        SelectionOption(
          title: 'Crear Transferencia',
          description: 'Registrar una transferencia nueva',
          icon: Icons.add_circle_outline,
          onTap: () => _goToCrear(context),
        ),
      ],
    );
  }
}
