import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/features/packaging_types/domain/entities/packaging_type.dart';
import 'package:wms_app/features/packaging_types/presentation/bloc/packaging_type_bloc.dart';
import 'package:wms_app/features/packaging_types/presentation/bloc/packaging_type_event.dart';
import 'package:wms_app/features/packaging_types/presentation/bloc/packaging_type_state.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/dialogs/packaging_type_selector_pack.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/dialogs/weight_stepper_pack.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/shared/utils/keyboard_watchdog.dart';

/// "¿Está seguro de empacar los productos seleccionados?" con tipo de
/// empaque y peso (solo en pedidos cluster). Mismo diseño que el diálogo de
/// packing por lote.
class ConfirmarPaqueteDialog extends StatefulWidget {
  final int cantidadProductos;
  final bool certificado;
  final bool manejaPeso;
  final bool manejaTipoEmpaque;
  final void Function(PackagingType? tipo, double peso) onConfirm;

  const ConfirmarPaqueteDialog({
    super.key,
    required this.cantidadProductos,
    required this.certificado,
    required this.manejaPeso,
    required this.manejaTipoEmpaque,
    required this.onConfirm,
  });

  @override
  State<ConfirmarPaqueteDialog> createState() => _ConfirmarPaqueteDialogState();
}

class _ConfirmarPaqueteDialogState extends State<ConfirmarPaqueteDialog>
    with WidgetsBindingObserver {
  final _pesoController = TextEditingController();
  final _pesoFocus = FocusNode();
  PackagingType? _tipo;
  String? _aviso;

  /// Doble toque: onConfirm una sola vez.
  bool _confirmando = false;

  late final KeyboardWatchdog _kbWatchdog = KeyboardWatchdog(
    state: this,
    focusNode: _pesoFocus,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() => _kbWatchdog.onMetricsChanged();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _kbWatchdog.dispose();
    _pesoController.dispose();
    _pesoFocus.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (_confirmando) return;
    if (widget.manejaTipoEmpaque && _tipo == null) {
      setState(() => _aviso = 'Seleccione un tipo de empaque');
      return;
    }
    // El teclado decimal en español escribe "1,5".
    final texto = _pesoController.text.trim().replaceAll(',', '.');
    final peso = texto.isEmpty ? 0.0 : double.tryParse(texto);
    if (widget.manejaPeso && (texto.isEmpty || peso == null || peso < 0)) {
      setState(() => _aviso = 'Ingrese un peso válido');
      return;
    }
    _confirmando = true;
    Navigator.pop(context);
    widget.onConfirm(_tipo, peso ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final alto = MediaQuery.sizeOf(context).height;
    return BlocProvider(
      create: (_) =>
          getIt<PackagingTypeBloc>()..add(GetLocalPackagingTypesEvent()),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          alignment: Alignment.bottomCenter,
          insetPadding: EdgeInsets.zero,
          backgroundColor: white,
          clipBehavior: Clip.antiAlias,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: widget.manejaTipoEmpaque ? alto * 0.6 : 0,
              maxHeight: alto * 0.92,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Encabezado(cantidad: widget.cantidadProductos),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.manejaTipoEmpaque) ...[
                          _tiposEmpaque(),
                          const SizedBox(height: 16),
                        ],
                        if (widget.manejaPeso) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5E9EF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: WeightStepperPack(
                              controller: _pesoController,
                              focusNode: _pesoFocus,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_aviso != null) ...[
                          Text(
                            _aviso!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: red, fontSize: 13),
                          ),
                          const SizedBox(height: 10),
                        ],
                        _Nota(certificado: widget.certificado),
                      ],
                    ),
                  ),
                ),
                _Acciones(onConfirmar: _confirmar),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tiposEmpaque() {
    return BlocBuilder<PackagingTypeBloc, PackagingTypeState>(
      builder: (context, state) {
        if (state is PackagingTypesLoadSuccess) {
          return PackagingTypeSelectorPack(
            types: state.packagingTypes,
            selected: _tipo,
            onSelected: (t) => setState(() {
              _tipo = t;
              _aviso = null;
            }),
            onInvalidScan: () {
              getIt<IAudioService>().playErrorSound();
              getIt<IVibrationService>().vibrate();
            },
          );
        }
        if (state is PackagingTypeLoadFailure) {
          return Text(
            'Error al cargar tipos: ${state.message}',
            style: const TextStyle(color: Colors.red),
          );
        }
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

class _Encabezado extends StatelessWidget {
  final int cantidad;
  const _Encabezado({required this.cantidad});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Column(
        children: [
          Text(
            '¿Está seguro de empacar los productos seleccionados?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: primaryColorApp,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.layers_outlined, size: 14, color: primaryColorApp),
                const SizedBox(width: 6),
                Text(
                  'Total de productos: $cantidad',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Nota extends StatelessWidget {
  final bool certificado;
  const _Nota({required this.certificado});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: Color(0xFFD97706)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              certificado
                  ? 'Al confirmar, los productos seleccionados pasarán al '
                        'estado Empacado.'
                  : 'Está realizando una separación sin certificado, tampoco '
                        'se incluirá el sticker de certificación.',
              style: const TextStyle(
                fontSize: 11,
                height: 1.3,
                color: Color(0xFF78350F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Acciones extends StatelessWidget {
  final VoidCallback onConfirmar;
  const _Acciones({required this.onConfirmar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 10,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, size: 18, color: Color(0xFF94A3B8)),
              label: const Text(
                'Cancelar',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: white,
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 14,
            child: ElevatedButton.icon(
              onPressed: onConfirmar,
              icon: const Icon(Icons.check, size: 18, color: white),
              label: const Text(
                'Aceptar',
                style: TextStyle(fontWeight: FontWeight.w700, color: white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColorApp,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
