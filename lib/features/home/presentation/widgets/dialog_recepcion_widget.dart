import 'package:flutter/material.dart';
import 'package:wms_app/shared/widgets/selection_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/bloc/recepcion_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';

class DialogRecepcion extends StatelessWidget {
  const DialogRecepcion({super.key, required this.contextHome});

  final BuildContext contextHome;

  Future<void> _goToIndividual(BuildContext context) async {
    // Misma operación que hacía el onTap de "Recepción" antes de existir
    // este selector: pedir ubicaciones + novedades, mostrar el loading y
    // navegar a la lista de órdenes de compra.
    context.read<RecepcionBloc>().add(GetLocationsDestEvent());
    context.read<RecepcionBloc>().add(LoadAllNovedadesOrderEvent());

    // Cerramos este diálogo de selección antes de mostrar el de carga.
    Navigator.pop(context);

    showDialog(
      context: contextHome,
      builder: (context) =>
          const DialogLoading(message: 'Cargando recepciones...'),
    );
    await Future.delayed(const Duration(seconds: 1));
    if (!contextHome.mounted) return;
    Navigator.pop(contextHome);
    Navigator.pushReplacementNamed(contextHome, 'list-ordenes-compra');
  }

  void _goToMultiusuario(BuildContext context) {
    Navigator.pop(context);
    Navigator.pushReplacementNamed(contextHome, 'list-recepcion-multiusuario');
  }

  @override
  Widget build(BuildContext context) {
    return SelectionDialog(
      icon: Icons.input,
      title: 'Selección de Recepción',
      message:
          'Seleccione una de las siguientes opciones para realizar el '
          'proceso de recepción',
      options: [
        SelectionOption(
          title: 'Recepción Individual',
          description: 'Órdenes de compra, un operario',
          icon: Icons.person_outline,
          onTap: () => _goToIndividual(context),
        ),
        SelectionOption(
          title: 'Recepción Multiusuario',
          description: 'Varios operarios en una misma recepción',
          icon: Icons.groups_outlined,
          onTap: () => _goToMultiusuario(context),
        ),
      ],
    );
  }
}
