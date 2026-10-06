import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/create-transfer/bloc/crate_transfer_bloc.dart';

/// Expone el [CreateTransferBloc] a una pantalla del módulo y lo cierra al
/// salir del módulo si no hay una transferencia en curso.
///
/// Con borrador (origen/destino/productos) el bloc se conserva
/// (`CreateTransferBloc.resumeOrCreate`) para retomar donde quedó; sin él se
/// libera, así no queda vivo un bloc vacío en el Home.
///
/// La instancia vive en el State: el builder de la ruta puede re-ejecutarse.
class CreateTransferScope extends StatefulWidget {
  const CreateTransferScope({
    super.key,
    required this.bloc,
    required this.child,
  });

  /// Bloc que llegó por argumento de ruta; si es null se retoma/crea el borrador.
  final CreateTransferBloc? bloc;
  final Widget child;

  @override
  State<CreateTransferScope> createState() => _CreateTransferScopeState();
}

class _CreateTransferScopeState extends State<CreateTransferScope> {
  late final CreateTransferBloc _bloc =
      widget.bloc ?? CreateTransferBloc.resumeOrCreate();

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
    return BlocProvider<CreateTransferBloc>.value(
      value: _bloc,
      child: widget.child,
    );
  }
}
