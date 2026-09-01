import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/usecases/undo_claim_usecase.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/bloc/detail/recepcion_multiusuario_pool_bloc.dart';
import 'package:wms_app/features/user/domain/entities/user_novelty.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/injection_container.dart';

/// Confirmación para "deshacer" una recepción ya terminada (tab
/// "Terminados") vía POST /api/receipt/claim/{claimId}/undo. Requiere
/// elegir una novedad (misma lista de UserBloc.novedades, cargada de la
/// BD local, que ya usa RecepcionSelectNovedadDialog en scan_product_screen).
class DialogDeshacerRecepcionWidget extends StatefulWidget {
  const DialogDeshacerRecepcionWidget({
    super.key,
    required this.productName,
    required this.claimId,
    required this.sessionId,
  });

  final String productName;
  final int? claimId;
  final int? sessionId;

  @override
  State<DialogDeshacerRecepcionWidget> createState() =>
      _DialogDeshacerRecepcionWidgetState();
}

class _DialogDeshacerRecepcionWidgetState
    extends State<DialogDeshacerRecepcionWidget> {
  Novedad? _selected;
  bool _isSubmitting = false;
  String? _error;

  Future<void> _confirmar() async {
    final claimId = widget.claimId;
    if (_selected == null || claimId == null) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final result = await getIt<UndoClaimUseCase>()(
      UndoClaimParams(claimId: claimId, observacion: _selected!.name),
    );

    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _isSubmitting = false;
        _error = failure.message;
      }),
      (_) {
        final sessionId = widget.sessionId;
        if (sessionId != null) {
          // Deshacer afecta las dos vistas: el producto vuelve a estar
          // disponible ("Por hacer") y desaparece de "Terminados".
          context.read<RecepcionMultiusuarioPoolBloc>().add(
            FetchRecepcionPoolEvent(sessionId, verification: false),
          );
          context.read<RecepcionMultiusuarioPoolBloc>().add(
            FetchRecepcionPoolEvent(sessionId, verification: true),
          );
        }
        Navigator.pop(context, true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final novedades = context.read<UserBloc>().novedades;

    return AlertDialog(
      title: Center(
        child: Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 40),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '¿Deshacer la recepción de "${widget.productName}"?\n\n'
              'Esto libera la cantidad ya recibida para que pueda volver a '
              'asignarse. Seleccione una novedad que explique el motivo.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: black),
            ),
            const SizedBox(height: 10),
            Card(
              color: white,
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButton<Novedad>(
                  underline: Container(height: 0),
                  borderRadius: BorderRadius.circular(10),
                  focusColor: white,
                  isExpanded: true,
                  isDense: true,
                  hint: const Text(
                    'Seleccionar novedad',
                    style: TextStyle(fontSize: 14, color: black),
                  ),
                  value: _selected,
                  alignment: Alignment.centerLeft,
                  style: const TextStyle(color: black, fontSize: 14),
                  items: novedades
                      .map(
                        (novedad) => DropdownMenuItem<Novedad>(
                          value: novedad,
                          child: Text(novedad.name),
                        ),
                      )
                      .toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) => setState(() => _selected = value),
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: red, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: Text('CANCELAR', style: TextStyle(color: grey)),
        ),
        ElevatedButton(
          onPressed: (_selected == null || _isSubmitting) ? null : _confirmar,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColorApp,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('DESHACER', style: TextStyle(color: white)),
        ),
      ],
    );
  }
}
