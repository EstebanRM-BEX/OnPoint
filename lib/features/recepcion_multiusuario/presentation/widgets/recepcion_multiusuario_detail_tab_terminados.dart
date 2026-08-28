import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_session.dart';

/// Tab 3 — productos ya terminados en esta recepción, por mí o por otros
/// operarios. En blanco por ahora.
class RecepcionMultiusuarioDetailTabTerminados extends StatelessWidget {
  const RecepcionMultiusuarioDetailTabTerminados({
    super.key,
    required this.session,
  });

  final RecepcionSession session;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.done_all, color: grey, size: 32),
          SizedBox(height: 8),
          Text(
            'Productos terminados — próximamente',
            style: TextStyle(color: grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
