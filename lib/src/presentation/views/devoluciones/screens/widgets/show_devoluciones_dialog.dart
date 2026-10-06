import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/bloc/devoluciones_bloc.dart';

/// `showDialog` que re-expone el [DevolucionesBloc] de la pantalla.
///
/// El bloc vive escopeado a las rutas de devolución y los diálogos se montan
/// en una ruta hermana (no descendiente), así que sin esto
/// `context.read<DevolucionesBloc>()` dentro del diálogo no lo encuentra.
Future<T?> showDevolucionesDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final bloc = context.read<DevolucionesBloc>();
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (_) =>
        BlocProvider.value(value: bloc, child: Builder(builder: builder)),
  );
}
