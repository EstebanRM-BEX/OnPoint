import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_session.dart';

/// Acción del validador en el tab Detalle (solo usuarios con el permiso
/// allow_validate_receipt_multi):
/// - sin validador asignado → "Asignarme como validador";
/// - el usuario es el validador → "Validar recepción", habilitado con
///   can_validate_document y sin líneas en progreso;
/// - otro usuario es el validador → solo su nombre.
class RecepcionValidarButtonWidget extends StatelessWidget {
  const RecepcionValidarButtonWidget({
    super.key,
    required this.session,
    required this.ocupado,
    required this.onAsignar,
    required this.onValidar,
  });

  final RecepcionSession session;

  /// Hay una asignación o validación en curso.
  final bool ocupado;
  final VoidCallback onAsignar;
  final VoidCallback onValidar;

  @override
  Widget build(BuildContext context) {
    final esValidador = session.currentUserIsValidator == true;
    final sinValidador = (session.validatorId ?? 0) == 0;

    if (!esValidador && !sinValidador) {
      return _Aviso(
        icon: Icons.verified_user_outlined,
        texto: 'Validador: ${session.validatorName ?? '-'}',
      );
    }

    if (sinValidador) {
      return _Accion(
        label: 'Asignarme como validador',
        icon: Icons.person_add_alt_1_outlined,
        ocupado: ocupado,
        onPressed: ocupado ? null : onAsignar,
      );
    }

    final lineas = session.linesAssigned ?? 0;
    final habilitado =
        !ocupado && session.canValidateDocument == true && lineas == 0;

    final String? aviso = lineas > 0
        ? lineas == 1
              ? 'Hay 1 línea en progreso. Espere a que la terminen o la liberen.'
              : 'Hay $lineas líneas en progreso. Espere a que las terminen o las liberen.'
        : session.canValidateDocument == true
        ? null
        : 'Todavía no se puede validar el documento.';

    return _Accion(
      label: 'Validar recepción',
      icon: Icons.fact_check_outlined,
      ocupado: ocupado,
      aviso: aviso,
      onPressed: habilitado ? onValidar : null,
    );
  }
}

class _Accion extends StatelessWidget {
  const _Accion({
    required this.label,
    required this.icon,
    required this.ocupado,
    required this.onPressed,
    this.aviso,
  });

  final String label;
  final IconData icon;
  final bool ocupado;
  final VoidCallback? onPressed;
  final String? aviso;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (aviso != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: yellow),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      aviso!,
                      style: const TextStyle(fontSize: 12, color: black),
                    ),
                  ),
                ],
              ),
            ),
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: ocupado
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: white,
                    ),
                  )
                : Icon(icon, color: white),
            label: Text(
              label,
              style: const TextStyle(color: white, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColorApp,
              disabledBackgroundColor: lightGrey,
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.icon, required this.texto});

  final IconData icon;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primaryColorApp),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 13, color: black),
            ),
          ),
        ],
      ),
    );
  }
}
