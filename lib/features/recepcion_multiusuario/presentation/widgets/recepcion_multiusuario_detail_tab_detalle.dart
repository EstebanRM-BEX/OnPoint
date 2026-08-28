import 'package:flutter/material.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_session.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/widgets/recepcion_session_card_widget.dart';

/// Tab 1 — información de la recepción: la misma card que se ve en
/// ListRecepcionMultiusuarioScreen, pero solo de la sesión que se tomó.
class RecepcionMultiusuarioDetailTabDetalle extends StatelessWidget {
  const RecepcionMultiusuarioDetailTabDetalle({
    super.key,
    required this.session,
  });

  final RecepcionSession session;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 4),
      child: RecepcionSessionCardWidget(session: session),
    );
  }
}
