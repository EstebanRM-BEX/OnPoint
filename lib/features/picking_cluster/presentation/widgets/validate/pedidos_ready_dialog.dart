import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/batch_product.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/pedido_validate.dart';
import 'package:wms_app/features/picking_cluster/presentation/bloc/validate_cluster/validate_cluster_bloc.dart';
import 'package:wms_app/features/picking_cluster/presentation/widgets/cluster_palette.dart';
import 'package:wms_app/features/picking_cluster/presentation/widgets/validate/pedido_validate_card.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';

/// Diálogo que ofrece validar los pedidos cuyos productos ya se enviaron.
///
/// Cada pedido es un [PedidoValidateCard] desplegable (muelle, avance y sus
/// productos). Se valida escaneando el barcode del muelle —el lector escucha
/// siempre, con tarjetas abiertas o cerradas— o, con [allowTapValidate]
/// (permiso `showButtonValidateClusterPicking`), con el botón "Validar".
/// La validación la hace [ValidateClusterBloc] (reenvío de pendientes +
/// backend + BD local).
class PedidosReadyDialog extends StatefulWidget {
  final List<PedidoValidate> pedidos;
  final List<BatchProduct> products;
  final bool allowTapValidate;

  const PedidosReadyDialog({
    super.key,
    required this.pedidos,
    required this.products,
    required this.allowTapValidate,
  });

  @override
  State<PedidosReadyDialog> createState() => _PedidosReadyDialogState();
}

class _PedidosReadyDialogState extends State<PedidosReadyDialog> {
  final IAudioService _audioService = getIt<IAudioService>();
  final IVibrationService _vibrationService = getIt<IVibrationService>();
  final FocusNode _scanFocus = FocusNode();
  final TextEditingController _scanController = TextEditingController();

  final Set<int> _validated = {};
  int? _validatingId;
  String? _error;

  bool _isValidated(PedidoValidate p) =>
      p.isValidated == true || _validated.contains(p.idPedido);

  bool get _allValidated => widget.pedidos.every(_isValidated);

  @override
  void initState() {
    super.initState();
    // Escuchamos el foco global, no solo el del lector: la pantalla de
    // escaneo de fondo pide foco para sus campos (algunos con retraso de 1 s)
    // justo al cambiar de producto, y puede quitárselo al lector antes de
    // que alguna vez lo tenga — un listener sobre _scanFocus no se enteraría.
    FocusManager.instance.addListener(_keepScannerFocus);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scanFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_keepScannerFocus);
    _scanFocus.dispose();
    _scanController.dispose();
    super.dispose();
  }

  // Mientras el diálogo sea la ruta activa, el foco se queda en el lector,
  // esté o no desplegada alguna tarjeta.
  void _keepScannerFocus() {
    if (_scanFocus.hasFocus) return;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted &&
          !_scanFocus.hasFocus &&
          ModalRoute.of(context)?.isCurrent == true) {
        _scanFocus.requestFocus();
      }
    });
  }

  // Desplegar/cerrar una tarjeta no apaga el lector: solo devuelve el foco.
  void _onExpansionChanged() => _scanFocus.requestFocus();

  void _onScan(String value) {
    if (_validatingId != null) return;
    final code = value.trim().toLowerCase();
    final matches = widget.pedidos
        .where((p) => (p.barcodeMuelle ?? '').trim().toLowerCase() == code)
        .toList();
    if (matches.isEmpty) {
      _fail('El código $value no corresponde a ningún muelle de esta lista');
      return;
    }
    // Varios pedidos pueden compartir muelle: se valida el primero pendiente.
    final pedido = matches.where((p) => !_isValidated(p)).firstOrNull;
    if (pedido == null) {
      _fail(
        matches.length == 1
            ? 'El pedido ${matches.first.namePedido ?? ''} ya está validado'
            : 'Los pedidos del muelle ${matches.first.muelle ?? value} ya están validados',
      );
      return;
    }
    _validate(pedido);
  }

  void _validate(PedidoValidate pedido) {
    setState(() {
      _validatingId = pedido.idPedido;
      _error = null;
    });
    context.read<ValidateClusterBloc>().add(
      TapMarkPedidoEvent(
        batchId: pedido.batchId ?? 0,
        namePedido: pedido.namePedido ?? '',
        listIdMove: widget.products
            .where((p) => p.pedidoId == pedido.idPedido)
            .map((p) => p.idMove ?? 0)
            .toList(),
      ),
    );
  }

  void _fail(String message) {
    _audioService.playErrorSound();
    _vibrationService.vibrate();
    setState(() {
      _validatingId = null;
      _error = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ValidateClusterBloc, ValidateClusterState>(
      listener: (context, state) {
        if (_validatingId == null) return;
        if (state is MarkPedidoValidatedSuccessState) {
          setState(() {
            _validated.add(_validatingId!);
            _validatingId = null;
          });
        } else if (state is ValidatePedidoErrorState) {
          _fail(state.msg);
        }
      },
      child: Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.8,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                _buildHiddenScanner(),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  _ErrorBanner(message: _error!),
                ],
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: widget.pedidos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _buildPedidoCard(widget.pedidos[i]),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _validatingId != null
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(
                      _allValidated ? 'Continuar' : 'Ahora no',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final count = widget.pedidos.length;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.fact_check_outlined,
            color: Color(0xFF059669),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count == 1 ? 'Pedido completado' : 'Pedidos completados',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ClusterPalette.slate900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                count == 1
                    ? 'Todos sus productos ya fueron enviados. ¿Deseas validarlo?'
                    : 'Estos $count pedidos ya tienen todos sus productos enviados. ¿Deseas validarlos?',
                style: const TextStyle(
                  fontSize: 12,
                  color: ClusterPalette.slate500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Campo invisible del lector (keyboard-wedge): no ocupa espacio.
  Widget _buildHiddenScanner() {
    return SizedBox(
      height: 12,
      child: OverflowBox(
        alignment: Alignment.topCenter,
        maxHeight: 40,
        child: Opacity(
          opacity: 0,
          child: IgnorePointer(
            child: BarcodeScannerField(
              controller: _scanController,
              focusNode: _scanFocus,
              autofocus: false,
              clearOnScan: true,
              refocusOnScan: false,
              onBarcodeScanned: (value, _) => _onScan(value),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPedidoCard(PedidoValidate pedido) {
    final validated = _validated.contains(pedido.idPedido);
    return PedidoValidateCard(
      key: ValueKey(pedido.idPedido),
      pedido: validated
          ? PedidoValidate(
              batchId: pedido.batchId,
              namePedido: pedido.namePedido,
              idPicking: pedido.idPicking,
              idPedido: pedido.idPedido,
              muelle: pedido.muelle,
              idMuelle: pedido.idMuelle,
              barcodeMuelle: pedido.barcodeMuelle,
              isValidated: true,
            )
          : pedido,
      products: widget.products
          .where((p) => p.pedidoId == pedido.idPedido)
          .toList(),
      isValidating: _validatingId == pedido.idPedido,
      onValidate: widget.allowTapValidate && _validatingId == null
          ? () => _validate(pedido)
          : null,
      onExpansionChanged: (_) => _onExpansionChanged(),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: Color(0xFFB91C1C)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
            ),
          ),
        ],
      ),
    );
  }
}
