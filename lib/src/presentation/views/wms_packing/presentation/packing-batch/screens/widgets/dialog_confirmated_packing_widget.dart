import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/src/presentation/views/wms_packing/models/lista_product_packing.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/features/packaging_types/domain/entities/packaging_type.dart';
import 'package:wms_app/features/packaging_types/presentation/bloc/packaging_type_bloc.dart';
import 'package:wms_app/features/packaging_types/presentation/bloc/packaging_type_event.dart';
import 'package:wms_app/features/packaging_types/presentation/bloc/packaging_type_state.dart';
import 'package:wms_app/shared/utils/keyboard_watchdog.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-batch/screens/widgets/others/packaging_type_selector_widget.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-batch/screens/widgets/others/weight_stepper_widget.dart';

/// Diálogo "¿Está seguro de empacar los productos seleccionados?" (rediseño
/// OnPoint: hoja inferior con tipo de empaque seleccionable y peso con
/// stepper). Lo usan packing por pedido, por lote y consolidado.
class DialogConfirmatedPacking extends StatefulWidget {
  const DialogConfirmatedPacking({
    super.key,
    required this.productos,
    required this.isCertificate,
    required this.isSticker,
    required this.onToggleSticker,
    required this.onConfirm,
    required this.manejaPeso,
    required this.manejaTipoEmpaque,
  });

  final List<ProductoPedido> productos;
  final bool isCertificate;
  final bool isSticker;
  final bool manejaPeso;
  final bool manejaTipoEmpaque;
  final void Function(bool newValue) onToggleSticker;
  final void Function(PackagingType? type, String weight) onConfirm;

  @override
  State<DialogConfirmatedPacking> createState() =>
      _DialogConfirmatedPackingState();
}

class _DialogConfirmatedPackingState extends State<DialogConfirmatedPacking>
    with WidgetsBindingObserver {
  late bool localSticker; // Estado interno del checkbox

  final TextEditingController _weightController = TextEditingController();
  final FocusNode _weightFocusNode = FocusNode();
  PackagingType? _selectedPackagingType;

  // Evita que un doble-toque (común en algunos dispositivos) dispare
  // onConfirm más de una vez antes de que Navigator.pop cierre el diálogo,
  // lo que duplicaba el paquete y el mensaje "Empaquetado exitoso".
  bool _isConfirming = false;

  // Watchdog: reabre el teclado si el IME del PDA (Zebra/Urovo/Chainway) lo
  // cierra solo mientras el campo de peso conserva el foco.
  late final KeyboardWatchdog _kbWatchdog = KeyboardWatchdog(
    state: this,
    focusNode: _weightFocusNode,
  );

  @override
  void initState() {
    super.initState();
    localSticker = widget.isSticker; // inicializamos con el valor que nos pasan
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() => _kbWatchdog.onMetricsChanged();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _kbWatchdog.dispose();
    _weightController.dispose();
    _weightFocusNode.dispose();
    super.dispose();
  }

  void _showWarning(String message) {
    Get.snackbar(
      "360 Software Informa",
      message,
      backgroundColor: white,
      colorText: primaryColorApp,
      icon: const Icon(Icons.error, color: Colors.amber),
    );
  }

  void _confirm() {
    if (_isConfirming) return;

    //validamos que se haya seleccionado un tipo de empaque
    if (_selectedPackagingType == null && widget.manejaTipoEmpaque) {
      _showWarning("Por favor seleccione un tipo de empaque");
      return;
    }

    //validamos que se haya seleccionado un peso
    if (_weightController.text.trim().isEmpty && widget.manejaPeso) {
      _showWarning("Por favor seleccione un peso");
      return;
    }

    // El teclado decimal en español escribe "1,5": se normaliza a punto y se
    // valida aquí (no hay Form), para que el llamador nunca reciba un texto
    // que no pueda convertir a número.
    final weightText = _weightController.text.trim().replaceAll(',', '.');
    if (widget.manejaPeso && (double.tryParse(weightText) ?? -1) < 0) {
      _showWarning("Ingrese un peso válido");
      return;
    }

    //si todo esta bien, llamamos a la funcion onConfirm
    _isConfirming = true;
    widget.onConfirm(_selectedPackagingType, weightText);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
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
              minHeight: MediaQuery.sizeOf(context).height * 0.6,
              maxHeight: MediaQuery.sizeOf(context).height * 0.92,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.manejaTipoEmpaque) ...[
                          _buildPackagingTypes(),
                          const SizedBox(height: 16),
                        ],
                        if (widget.manejaPeso) ...[
                          // Fondo gris claro para separar visualmente el
                          // módulo de peso del resto del diálogo.
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5E9EF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: WeightStepperField(
                              controller: _weightController,
                              focusNode: _weightFocusNode,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        _buildHint(),
                      ],
                    ),
                  ),
                ),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            top: -8,
            child: IconButton(
              tooltip: 'Cerrar',
              onPressed: () => Navigator.pop(context),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                minimumSize: const Size(36, 36),
              ),
              icon: const Icon(Icons.close, size: 18, color: Color(0xFF64748B)),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Container(
              //   width: 56,
              //   height: 56,
              //   decoration: BoxDecoration(
              //     borderRadius: BorderRadius.circular(16),
              //     gradient: LinearGradient(
              //       begin: Alignment.bottomLeft,
              //       end: Alignment.topRight,
              //       colors: [
              //         primaryColorApp.withOpacity(0.18),
              //         primaryColorApp.withOpacity(0.06),
              //       ],
              //     ),
              //   ),
              //   child: Icon(
              //     Icons.inventory_2_outlined,
              //     size: 28,
              //     color: primaryColorApp,
              //   ),
              // ),
              // const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 5, right: 12),
                child: Text(
                  '¿Está seguro de empacar los productos seleccionados?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: primaryColorApp,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.layers_outlined,
                        size: 14,
                        color: primaryColorApp,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Total de productos:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          '${widget.productos.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPackagingTypes() {
    return BlocBuilder<PackagingTypeBloc, PackagingTypeState>(
      builder: (context, state) {
        if (state is PackagingTypesLoadInProgress) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is PackagingTypesLoadSuccess) {
          return PackagingTypeSelector(
            types: state.packagingTypes,
            selected: _selectedPackagingType,
            onSelected: (type) => setState(() => _selectedPackagingType = type),
            // Código que no es de ningún tipo: solo sonido y vibración.
            onInvalidScan: () {
              getIt<IAudioService>().playErrorSound();
              getIt<IVibrationService>().vibrate();
            },
          );
        }
        if (state is PackagingTypeLoadFailure) {
          return Center(
            child: Text(
              'Error al cargar tipos: ${state.message}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildHint() {
    final text = widget.isCertificate
        ? 'Al confirmar, los productos seleccionados pasarán al estado '
              'Empacado.'
        : 'Está realizando una separación sin certificado, tampoco se '
              'incluirá el sticker de certificación.';

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
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline, size: 16, color: Color(0xFFD97706)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 10,
                height: 1.3,
                color: Color(0xFF78350F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
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
              onPressed: _confirm,
              icon: const Icon(Icons.check, size: 18, color: white),
              label: const Text(
                'Aceptar',
                style: TextStyle(fontWeight: FontWeight.w700, color: white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColorApp,
                elevation: 3,
                shadowColor: primaryColorApp.withOpacity(0.4),
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
