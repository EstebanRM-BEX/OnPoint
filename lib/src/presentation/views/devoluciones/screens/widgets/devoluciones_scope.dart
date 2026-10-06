import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/src/presentation/views/devoluciones/screens/bloc/devoluciones_bloc.dart';

/// Expone el [DevolucionesBloc] a una pantalla del flujo de devoluciones y
/// cierra el bloc cuando se sale del flujo.
///
/// La navegación interna es por `pushReplacementNamed` pasando el mismo bloc
/// como argumento, así que esta pantalla se descarta aunque el flujo siga
/// activo: el cierre real lo decide el contador de scopes del bloc
/// ([DevolucionesBloc.detachScope]).
///
/// La instancia vive en el State: el builder de la ruta puede re-ejecutarse
/// y crear un bloc nuevo en cada pasada dejaría la pantalla escuchando a otro.
class DevolucionesScope extends StatefulWidget {
  const DevolucionesScope({super.key, required this.bloc, required this.child});

  /// Bloc que llegó por argumento de ruta; si es null se crea uno acá.
  final DevolucionesBloc? bloc;
  final Widget child;

  @override
  State<DevolucionesScope> createState() => _DevolucionesScopeState();
}

class _DevolucionesScopeState extends State<DevolucionesScope> {
  late final DevolucionesBloc _bloc = widget.bloc ?? DevolucionesBloc();

  @override
  void initState() {
    super.initState();
    _bloc.attachScope();
  }

  @override
  void dispose() {
    _bloc.detachScope();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DevolucionesBloc>.value(
      value: _bloc,
      child: widget.child,
    );
  }
}
