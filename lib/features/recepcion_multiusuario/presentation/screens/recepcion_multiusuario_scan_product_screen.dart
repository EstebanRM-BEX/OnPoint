import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/utils/theme/input_decoration.dart';
import 'package:wms_app/features/printing/presentation/widgets/modal_printers_list.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_claim.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_session.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';
import 'package:wms_app/shared/widgets/lote_scanner_widget.dart';

/// Pantalla de recepción de un producto ya reclamado (RecepcionClaim) en una
/// sesión de recepción multiusuario. Réplica del flujo de
/// scan_product_screen.dart de recepción individual (confirmar producto,
/// lote si aplica, cantidad) adaptado a los campos que trae el claim.
///
/// El claim no trae ubicación destino, segunda unidad ni temperatura (esos
/// campos no existen en la respuesta de POST /api/receipt/claim), así que
/// esta pantalla no los incluye.
///
/// El botón "APLICAR CANTIDAD" valida todo localmente pero TODAVÍA NO envía
/// nada al backend: falta que se defina el endpoint para confirmar la
/// cantidad recibida de un claim. Mientras tanto solo avisa que la acción no
/// está disponible.
class RecepcionMultiusuarioScanProductScreen extends StatefulWidget {
  const RecepcionMultiusuarioScanProductScreen({
    super.key,
    required this.session,
    required this.claim,
  });

  final RecepcionSession session;
  final RecepcionClaim claim;

  @override
  State<RecepcionMultiusuarioScanProductScreen> createState() =>
      _RecepcionMultiusuarioScanProductScreenState();
}

class _RecepcionMultiusuarioScanProductScreenState
    extends State<RecepcionMultiusuarioScanProductScreen> {
  final IAudioService _audioService = getIt<IAudioService>();
  final IVibrationService _vibrationService = getIt<IVibrationService>();

  bool _productIsOk = false;
  bool _loteIsOk = false;
  double _quantitySelected = 0;
  bool _viewQuantity = false;

  final FocusNode _focusProduct = FocusNode();
  final FocusNode _focusLote = FocusNode();
  final FocusNode _focusQuantity = FocusNode();
  final FocusNode _focusQuantityManual = FocusNode();

  final TextEditingController _controllerProduct = TextEditingController();
  final TextEditingController _controllerLote = TextEditingController();
  final TextEditingController _controllerQuantity = TextEditingController();
  final TextEditingController _controllerQuantityManual =
      TextEditingController();

  bool get _manejaLote => widget.claim.manejaLote;

  double get _pendiente =>
      (widget.claim.qtyAsignada ?? 0) - (widget.claim.qtyRecibida ?? 0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handleDependencies();
  }

  void _handleDependencies() {
    // No robar foco si hay un dialog o modal (ej. el de impresión) encima.
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) return;

    if (!_productIsOk) {
      FocusScope.of(context).requestFocus(_focusProduct);
      return;
    }
    if (_manejaLote && !_loteIsOk) {
      FocusScope.of(context).requestFocus(_focusLote);
      return;
    }
    if (!_viewQuantity) {
      FocusScope.of(context).requestFocus(_focusQuantity);
    }
  }

  @override
  void dispose() {
    _focusProduct.dispose();
    _focusLote.dispose();
    _focusQuantity.dispose();
    _focusQuantityManual.dispose();
    _controllerProduct.dispose();
    _controllerLote.dispose();
    _controllerQuantity.dispose();
    _controllerQuantityManual.dispose();
    super.dispose();
  }

  void _showScanError(String message) {
    _audioService.playErrorSound();
    _vibrationService.vibrate();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _validateProduct(String value) {
    final scan = value.trim().toLowerCase();
    _controllerProduct.clear();
    if (scan.isNotEmpty && scan == widget.claim.barcode?.toLowerCase()) {
      setState(() => _productIsOk = true);
      Future.microtask(_handleDependencies);
    } else {
      _showScanError('El código no coincide con el producto');
      Future.microtask(() => _focusProduct.requestFocus());
    }
  }

  void _validateLote(String value) {
    final scan = value.trim().toLowerCase();
    _controllerLote.clear();
    final loteName = widget.claim.lotName?.toLowerCase() ?? '';
    if (scan.isNotEmpty && loteName.isNotEmpty && scan == loteName) {
      setState(() => _loteIsOk = true);
      Future.microtask(_handleDependencies);
    } else {
      _showScanError('El lote no coincide');
      Future.microtask(() => _focusLote.requestFocus());
    }
  }

  void _validateQuantityScan(String value) {
    final scan = value.trim().toLowerCase();
    _controllerQuantity.clear();
    if (scan.isEmpty || scan != widget.claim.barcode?.toLowerCase()) {
      _showScanError('El código no coincide con el producto');
      Future.microtask(() => _focusQuantity.requestFocus());
      return;
    }
    if (_quantitySelected + 1 > _pendiente) {
      _showScanError('Ya alcanzó la cantidad pendiente de este producto');
      Future.microtask(() => _focusQuantity.requestFocus());
      return;
    }
    setState(() => _quantitySelected += 1);
    Future.microtask(() => _focusQuantity.requestFocus());
  }

  void _toggleManualQuantity() {
    setState(() => _viewQuantity = !_viewQuantity);
    if (_viewQuantity) {
      _controllerQuantityManual.text =
          _quantitySelected == _quantitySelected.roundToDouble()
          ? _quantitySelected.toStringAsFixed(0)
          : _quantitySelected.toString();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        FocusScope.of(context).requestFocus(_focusQuantityManual);
      });
    } else {
      _controllerQuantityManual.clear();
      Future.microtask(_handleDependencies);
    }
  }

  bool get _puedeAplicarCantidad =>
      _productIsOk && (!_manejaLote || _loteIsOk) && _quantitySelected > 0;

  void _handleAplicarCantidad() {
    FocusScope.of(context).unfocus();

    String input = _controllerQuantityManual.text.trim().isEmpty
        ? _quantitySelected.toString()
        : _controllerQuantityManual.text.trim();
    input = input.replaceAll(',', '.');

    final cantidad = double.tryParse(input);
    if (cantidad == null || cantidad <= 0) {
      _showScanError('Cantidad inválida');
      return;
    }
    if (cantidad > _pendiente) {
      _showScanError('La cantidad supera lo pendiente de este producto');
      return;
    }

    setState(() => _quantitySelected = cantidad);

    // TODO: acá falta el endpoint para confirmar/enviar la cantidad recibida
    // de este claim (POST .../api/receipt/... aún no definido). Por ahora
    // solo se valida localmente, no se envía nada al backend.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Cantidad validada. Falta conectar el endpoint para confirmar '
          'la recepción — pendiente de definir.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final claim = widget.claim;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: primaryColorApp,
        appBar: AppBar(
          backgroundColor: primaryColorApp,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.session.name ?? 'RECEPCIÓN',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.print, color: Colors.white),
              onPressed: claim.productId == null
                  ? null
                  : () => ModalPrintersList.show(
                      context,
                      resIds: [claim.productId],
                      companyId: widget.session.warehouseId ?? 1,
                    ),
            ),
          ],
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),
        body: SafeArea(
          child: Container(
            color: Colors.white,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // producto
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Card(
                      color: _productIsOk
                          ? Colors.green[100]
                          : Colors.grey[200],
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Producto',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: primaryColorApp,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  _productIsOk
                                      ? Icons.check_circle
                                      : Icons.qr_code_scanner,
                                  color: _productIsOk ? green : primaryColorApp,
                                  size: 20,
                                ),
                              ],
                            ),
                            Text(
                              claim.productName ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                color: black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            BarcodeScannerField(
                              controller: _controllerProduct,
                              focusNode: _focusProduct,
                              onBarcodeScanned: (value, context) =>
                                  _validateProduct(value),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // lote (solo si el producto maneja lote)
                  if (_manejaLote)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Card(
                        color: !_productIsOk
                            ? Colors.grey[200]
                            : _loteIsOk
                            ? Colors.green[100]
                            : Colors.grey[300],
                        elevation: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Lote del producto',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: primaryColorApp,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    _loteIsOk
                                        ? Icons.check_circle
                                        : Icons.qr_code_scanner,
                                    color: _loteIsOk ? green : primaryColorApp,
                                    size: 20,
                                  ),
                                ],
                              ),
                              LoteScannerWidget(
                                controller: _controllerLote,
                                focusNode: _focusLote,
                                enabled: _productIsOk && !_loteIsOk,
                                hintText: claim.lotName?.isNotEmpty == true
                                    ? claim.lotName!
                                    : 'Esperando escaneo',
                                onValidateLote: _validateLote,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // cantidad
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Card(
                      color: white,
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cantidad',
                              style: TextStyle(
                                fontSize: 14,
                                color: primaryColorApp,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Asignada: ${claim.qtyAsignada ?? 0} ${claim.uom ?? ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: black,
                              ),
                            ),
                            Text(
                              'Ya recibida: ${claim.qtyRecibida ?? 0} ${claim.uom ?? ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: black,
                              ),
                            ),
                            Text(
                              'Pendiente: $_pendiente ${claim.uom ?? ''}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: primaryColorApp,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: BarcodeScannerField(
                                          controller: _controllerQuantity,
                                          focusNode: _focusQuantity,
                                          onBarcodeScanned: (value, context) =>
                                              _validateQuantityScan(value),
                                        ),
                                      ),
                                      Text(
                                        _quantitySelected == 0
                                            ? 'Esperando escaneo'
                                            : _quantitySelected.toString(),
                                        style: const TextStyle(
                                          color: black,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed:
                                      _productIsOk &&
                                          (!_manejaLote || _loteIsOk)
                                      ? _toggleManualQuantity
                                      : null,
                                  icon: Icon(
                                    Icons.edit_note_rounded,
                                    color: primaryColorApp,
                                    size: 30,
                                  ),
                                ),
                              ],
                            ),
                            if (_viewQuantity)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: TextFormField(
                                  focusNode: _focusQuantityManual,
                                  controller: _controllerQuantityManual,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9.]'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    final parsed = double.tryParse(
                                      value.replaceAll(',', '.'),
                                    );
                                    if (parsed != null) {
                                      setState(
                                        () => _quantitySelected = parsed,
                                      );
                                    }
                                  },
                                  decoration:
                                      InputDecorations.authInputDecoration(
                                        hintText: 'Cantidad',
                                        labelText: 'Cantidad',
                                        suffixIconButton: IconButton(
                                          onPressed: _toggleManualQuantity,
                                          icon: const Icon(Icons.clear),
                                        ),
                                      ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: ElevatedButton(
                      onPressed: _puedeAplicarCantidad
                          ? _handleAplicarCantidad
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColorApp,
                        disabledBackgroundColor: grey,
                        minimumSize: Size(size.width * 0.93, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'APLICAR CANTIDAD',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
