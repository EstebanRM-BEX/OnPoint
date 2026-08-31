import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/routes/app_router.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/core/utils/theme/input_decoration.dart';
import 'package:wms_app/features/inventario/domain/usecases/get_url_imagen_producto.dart';
import 'package:wms_app/features/printing/presentation/widgets/modal_printers_list.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/lote_producto.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_claim.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_session.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/usecases/finish_claim_usecase.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/widgets/recepcion_product_dropdown_widget.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/widgets/select_novedad_dialog.dart';
import 'package:wms_app/features/user/domain/entities/user_novelty.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';
import 'package:wms_app/shared/widgets/lote_scanner_widget.dart';
import 'package:wms_app/shared/widgets/scanner_product_widget.dart';
import 'package:wms_app/shared/widgets/segunda_unidad_input_widget.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/dialog_view_img_temp_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_barcodes_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';
import 'package:wms_app/src/presentation/widgets/expiration_badge_widget.dart';

/// Pantalla de recepción de un producto ya reclamado (RecepcionClaim) en una
/// sesión de recepción multiusuario. Réplica del flujo de
/// scan_product_screen.dart de recepción individual (confirmar producto,
/// lote si aplica, ubicación destino si aplica, cantidad) adaptado a los
/// campos que trae el claim.
///
/// La ubicación destino, a diferencia de recepción individual (donde el
/// operario la busca libremente si el permiso `scan_destination_location_reception`
/// es falso), acá siempre viene pre-asignada por el backend
/// (`location_dest_*` del claim) — el permiso solo decide si además hay que
/// escanearla para confirmarla o si basta con mostrarla.
///
/// El claim no trae segunda unidad ni temperatura (esos campos no existen en
/// la respuesta de POST /api/receipt/claim), así que esta pantalla no los
/// incluye.
///
/// El botón "APLICAR CANTIDAD" confirma la recepción vía
/// POST /api/receipt/claim/{claimId}/done. Si la cantidad es menor a lo
/// pendiente pide seleccionar una novedad primero (no existe el concepto de
/// backorder/split en multiusuario todavía); si es mayor, se rechaza
/// siempre — a diferencia de individual, acá no hay permiso que permita
/// exceso.
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
  // Flag de error visual (card roja) del gate de producto, independiente de
  // _productIsOk — se pone en false ante un escaneo que no matchea y vuelve
  // a true en el próximo intento (mismo patrón que isProductOk en
  // recepción individual).
  bool _productFieldOk = true;
  bool _loteIsOk = false;
  // Lote elegido/creado desde RecepcionMultiusuarioNewLoteScreen — cuando no
  // es null, reemplaza a claim.lotName como el lote "esperado" a confirmar.
  LoteProducto? _selectedLote;
  // null mientras carga: el permiso vive en tbl_configurations, no queremos
  // leerlo como "false" (modo fijo, sin gate) por falta de datos.
  bool? _scanDestinationLocationReception;
  bool _locationDestIsOk = false;
  bool _locationDestFieldOk = true;
  // Ubicación elegida desde RecepcionMultiusuarioLocationDestScreen —
  // cuando no es null, reemplaza a claim.locationDest* como la ubicación
  // "esperada" a confirmar (mismo patrón que _selectedLote).
  ResultUbicaciones? _selectedUbicacionDest;
  double _quantitySelected = 0;
  // Alterna entre escanear (producto suma 1, paquete suma su cantidad) e
  // ingresar la cantidad a mano.
  bool _viewQuantity = false;
  // null mientras carga (mismo motivo que _scanDestinationLocationReception).
  bool? _hideExpectedQty;
  bool _isSubmitting = false;
  // Se marca al validar el producto — time_line del envío final es el
  // tiempo transcurrido desde acá hasta que se confirma la recepción
  // (mismo criterio que dateInicio/time en recepción individual).
  DateTime? _productValidatedAt;

  final FocusNode _focusProduct = FocusNode();
  final FocusNode _focusLote = FocusNode();
  final FocusNode _focusLocationDest = FocusNode();
  final FocusNode _focusSegundaUnidad = FocusNode();
  final FocusNode _focusQuantity = FocusNode();
  final FocusNode _focusQuantityManual = FocusNode();

  final TextEditingController _controllerProduct = TextEditingController();
  final TextEditingController _controllerLote = TextEditingController();
  final TextEditingController _controllerLocationDest = TextEditingController();
  final TextEditingController _controllerSegundaUnidad =
      TextEditingController();
  final TextEditingController _controllerQuantity = TextEditingController();
  final TextEditingController _controllerQuantityManual =
      TextEditingController();

  bool get _manejaLote => widget.claim.manejaLote;

  bool get _manejaSegundaUnidad => widget.claim.manejaSegundaUnidad == true;

  String? get _loteNombreEsperado =>
      _selectedLote?.name ?? widget.claim.lotName;

  String? get _locationDestNombreEsperado =>
      _selectedUbicacionDest?.name ?? widget.claim.locationDestName;

  String? get _locationDestBarcodeEsperado =>
      _selectedUbicacionDest?.barcode ?? widget.claim.locationDestBarcode;

  /// true si hace falta escanear la ubicación destino para confirmarla
  /// (permiso activo y el claim trae una ubicación destino asignada).
  bool get _requiereEscanearUbicacionDestino =>
      _scanDestinationLocationReception == true &&
      widget.claim.locationDestId != null;

  double get _pendiente =>
      (widget.claim.qtyAsignada ?? 0) - (widget.claim.qtyRecibida ?? 0);

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
    // No es parte de la cadena de foco secuencial (producto → lote →
    // destino → cantidad): el operario la llena cuando quiera, y al perder
    // foco solo se reevalúa a dónde sigue el flujo.
    _focusSegundaUnidad.addListener(() {
      if (!_focusSegundaUnidad.hasFocus && mounted) {
        Future.microtask(_handleDependencies);
      }
    });
  }

  Future<void> _cargarConfiguracion() async {
    final userId = await PrefUtils.getUserId();
    final config = await DataBaseSqlite().configurationsRepository
        .getConfiguration(userId);
    if (!mounted) return;
    setState(() {
      _scanDestinationLocationReception =
          config?.result?.result?.scanDestinationLocationReception == true;
      _hideExpectedQty = config?.result?.result?.hideExpectedQty == true;
    });
    Future.microtask(_handleDependencies);
  }

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
    if (_requiereEscanearUbicacionDestino && !_locationDestIsOk) {
      FocusScope.of(context).requestFocus(_focusLocationDest);
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
    _focusLocationDest.dispose();
    _focusSegundaUnidad.dispose();
    _focusQuantity.dispose();
    _focusQuantityManual.dispose();
    _controllerProduct.dispose();
    _controllerLote.dispose();
    _controllerLocationDest.dispose();
    _controllerSegundaUnidad.dispose();
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
      setState(() {
        _productIsOk = true;
        _productFieldOk = true;
        _productValidatedAt = DateTime.now();
      });
      Future.microtask(_handleDependencies);
    } else {
      setState(() => _productFieldOk = false);
      _showScanError('El código no coincide con el producto');
      Future.microtask(() => _focusProduct.requestFocus());
    }
  }

  /// Confirma el producto sin escanear (dropdown de un solo ítem) — mismo
  /// efecto que un scan exitoso.
  void _selectProductManually() {
    setState(() {
      _productIsOk = true;
      _productFieldOk = true;
      _productValidatedAt = DateTime.now();
    });
    Future.microtask(_handleDependencies);
  }

  Future<void> _handleViewImage() async {
    final productId = widget.claim.productId;
    if (productId == null) return;

    final result = await getIt<GetUrlImagenProducto>()(
      GetUrlImagenProductoParams(productId: productId),
    );
    if (!mounted) return;

    result.fold(
      (failure) => showScrollableErrorDialog('Imagen no disponible'),
      (url) => showImageDialog(context, url),
    );
  }

  void _openBarcodesDialog() {
    final merged = [
      ...widget.claim.otherBarcodes,
      ...widget.claim.productPacking,
    ];
    showDialog(
      context: context,
      builder: (context) => DialogBarcodes(listOfBarcodes: merged),
    );
  }

  void _validateLote(String value) {
    final scan = value.trim().toLowerCase();
    _controllerLote.clear();
    final loteName = _loteNombreEsperado?.toLowerCase() ?? '';
    if (scan.isNotEmpty && loteName.isNotEmpty && scan == loteName) {
      setState(() => _loteIsOk = true);
      Future.microtask(_handleDependencies);
    } else {
      _showScanError('El lote no coincide');
      Future.microtask(() => _focusLote.requestFocus());
    }
  }

  /// Abre la pantalla de listar/crear lote; si el operario elige o crea uno,
  /// lo da por confirmado directo (mismo efecto que SelectecLoteEvent en
  /// recepción individual — no hace falta volver a escanearlo).
  Future<void> _openLoteScreen() async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.recepcionMultiusuarioNewLote,
      arguments: [widget.session, widget.claim],
    );
    if (!mounted || result is! LoteProducto) return;
    setState(() {
      _selectedLote = result;
      _loteIsOk = true;
    });
    Future.microtask(_handleDependencies);
  }

  void _validateLocationDest(String value) {
    final scan = value.trim().toLowerCase();
    _controllerLocationDest.clear();
    final esperado =
        (_locationDestBarcodeEsperado ?? _locationDestNombreEsperado)
            ?.toLowerCase() ??
        '';
    if (scan.isNotEmpty && esperado.isNotEmpty && scan == esperado) {
      setState(() {
        _locationDestIsOk = true;
        _locationDestFieldOk = true;
      });
      Future.microtask(_handleDependencies);
    } else {
      setState(() => _locationDestFieldOk = false);
      _showScanError('La ubicación no coincide');
      Future.microtask(() => _focusLocationDest.requestFocus());
    }
  }

  /// Abre la pantalla de buscar/seleccionar ubicación destino; si el
  /// operario elige una, la da por confirmada directo (mismo efecto que
  /// _openLoteScreen — no hace falta volver a escanearla). No deja entrar
  /// si el producto todavía no fue validado (mismo orden que la cadena de
  /// foco: producto → lote → destino).
  Future<void> _openLocationDestScreen() async {
    if (!_productIsOk) {
      // _showScanError('Primero debes validar el producto');
      return;
    }

    final result = await Navigator.pushNamed(
      context,
      AppRoutes.recepcionMultiusuarioLocationDest,
    );
    if (!mounted || result is! ResultUbicaciones) return;
    setState(() {
      _selectedUbicacionDest = result;
      _locationDestIsOk = true;
      _locationDestFieldOk = true;
    });
    Future.microtask(_handleDependencies);
  }

  /// true si ya se puede escanear/escribir la cantidad: producto validado,
  /// lote validado si el producto maneja lote, y ubicación destino
  /// validada si el permiso exige escanearla (modo dinámico) — si es fija
  /// (o no aplica), no hace falta.
  bool get _puedeUsarCantidad =>
      _productIsOk &&
      (!_manejaLote || _loteIsOk) &&
      (!_requiereEscanearUbicacionDestino || _locationDestIsOk);

  String get _cantidadBloqueadaMensaje {
    if (!_productIsOk) return 'Primero debes validar el producto';
    if (_manejaLote && !_loteIsOk) return 'Primero debes validar el lote';
    if (_requiereEscanearUbicacionDestino && !_locationDestIsOk) {
      return 'Primero debes validar la ubicación destino';
    }
    return 'Completa los pasos anteriores primero';
  }

  bool get _puedeAplicarCantidad =>
      _puedeUsarCantidad &&
      (!_manejaSegundaUnidad ||
          _controllerSegundaUnidad.text.trim().isNotEmpty) &&
      (_quantitySelected > 0 ||
          _controllerQuantityManual.text.trim().isNotEmpty);

  /// Escaneo del código del producto (suma 1) o de un código de paquete de
  /// otherBarcodes/productPacking (suma su cantidad predefinida) — mismo
  /// comportamiento que validateQuantity en recepción individual.
  void _validateQuantityScan(String value) {
    _controllerQuantity.clear();
    if (!_puedeUsarCantidad) {
      _showScanError(_cantidadBloqueadaMensaje);
      return;
    }

    final scan = value.trim().toLowerCase();
    if (scan.isEmpty) return;

    if (scan == widget.claim.barcode?.toLowerCase()) {
      _addQuantity(1);
      return;
    }

    double? cantidadPaquete;
    for (final barcode in [
      ...widget.claim.otherBarcodes,
      ...widget.claim.productPacking,
    ]) {
      if (barcode.barcode?.toString().toLowerCase() == scan) {
        cantidadPaquete = (barcode.cantidad as num?)?.toDouble() ?? 0;
        break;
      }
    }
    if (cantidadPaquete != null) {
      _addQuantity(cantidadPaquete);
      return;
    }

    _showScanError('El código no coincide con el producto ni un paquete');
    Future.microtask(() => _focusQuantity.requestFocus());
  }

  void _addQuantity(double delta) {
    final nueva = _quantitySelected + delta;
    if (nueva > _pendiente) {
      _showScanError('La cantidad supera lo pendiente de este producto');
    } else {
      setState(() => _quantitySelected = nueva);
    }
    Future.microtask(() => _focusQuantity.requestFocus());
  }

  /// Alterna entre escanear y escribir la cantidad a mano (ícono de lápiz),
  /// igual que en recepción individual.
  void _toggleManualQuantity() {
    if (!_viewQuantity && !_puedeUsarCantidad) {
      _showScanError(_cantidadBloqueadaMensaje);
      return;
    }
    setState(() => _viewQuantity = !_viewQuantity);
    if (_viewQuantity) {
      _controllerQuantityManual.text = _quantitySelected > 0
          ? _quantitySelected.toString()
          : '';
      Future.microtask(() => _focusQuantityManual.requestFocus());
    } else {
      _controllerQuantityManual.clear();
      Future.microtask(() => _focusQuantity.requestFocus());
    }
  }

  Future<void> _handleAplicarCantidad() async {
    FocusScope.of(context).unfocus();

    if (_manejaSegundaUnidad && _controllerSegundaUnidad.text.trim().isEmpty) {
      _showScanError(
        'Ingrese la cantidad de la segunda unidad'
        '${widget.claim.uomSegundaUnidad != null ? ' (${widget.claim.uomSegundaUnidad})' : ''}',
      );
      return;
    }

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

    String? novedad;
    if (cantidad < _pendiente) {
      novedad = await _pedirNovedad(cantidad);
      if (novedad == null) return; // canceló el diálogo, no envía nada
    }

    await _enviarRecepcion(cantidad, novedad);
  }

  /// Cantidad menor a lo pendiente: no existe backorder/split en
  /// multiusuario todavía, así que solo se pide una novedad que explique la
  /// diferencia (reemplaza al diálogo Aceptar/Dividir de individual).
  Future<String?> _pedirNovedad(double cantidad) async {
    final novedades = context.read<UserBloc>().novedades;
    final result = await showDialog<Novedad>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RecepcionSelectNovedadDialog(
        cantidad: cantidad,
        pendiente: _pendiente,
        novedades: novedades,
        mostrarCantidadPendiente: _hideExpectedQty == false,
      ),
    );
    return result?.name;
  }

  Future<void> _enviarRecepcion(double cantidad, String? novedad) async {
    setState(() => _isSubmitting = true);

    final lotId = _selectedLote?.id ?? widget.claim.lotId ?? 0;
    final ubicacionDestino =
        _selectedUbicacionDest?.id ?? widget.claim.locationDestId ?? 0;
    final timeLine = _productValidatedAt == null
        ? 0
        : DateTime.now().difference(_productValidatedAt!).inSeconds;

    final result = await getIt<FinishClaimUseCase>()(
      FinishClaimParams(
        claimId: widget.claim.id ?? 0,
        qtyDone: cantidad,
        lotId: lotId,
        ubicacionDestino: ubicacionDestino,
        timeLine: timeLine,
        observation: novedad ?? '',
      ),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold(
      (failure) => showScrollableErrorDialog(failure.message),
      (_) => Navigator.pop(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final claim = widget.claim;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.white,
        // backgroundColor: primaryColorApp,
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
        body: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(top: 2),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ubicación de origen
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: green,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Card(
                            color: Colors.green[100],
                            elevation: 5,
                            child: Container(
                              width: size.width * 0.85,
                              padding: const EdgeInsets.only(
                                left: 10,
                                right: 10,
                                top: 10,
                                bottom: 10,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Ubicación de origen',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: primaryColorApp,
                                        ),
                                      ),
                                      const Spacer(),
                                      Image.asset(
                                        "assets/icons/ubicacion.png",
                                        color: primaryColorApp,
                                        width: 20,
                                      ),
                                    ],
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      claim.locationName ?? '',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // producto
                      ProductScannerWidget(
                        isProductOk: _productFieldOk,
                        productIsOk: _productIsOk,
                        locationIsOk: true,
                        quantityIsOk: _quantitySelected > 0,
                        locationDestIsOk: false,
                        currentProductId: claim.productName ?? '',
                        barcode: claim.barcode,
                        lotId: claim.lotName,
                        expireDate: claim.fechaVencimiento,
                        size: size,
                        onValidateProduct: _validateProduct,
                        onViewImgProduct: _handleViewImage,
                        focusNode: _focusProduct,
                        controller: _controllerProduct,
                        productDropdown: RecepcionProductDropdownWidget(
                          productName: claim.productName ?? '',
                          enabled: !_productIsOk,
                          onSelected: _selectProductManually,
                        ),
                        origin: null,
                        expiryWidget: ExpirationBadgeWidget(
                          expirationDate: claim.fechaVencimiento,
                        ),
                        listOfBarcodes: [
                          ...claim.otherBarcodes,
                          ...claim.productPacking,
                        ],
                        onBarcodesDialogTap: _openBarcodesDialog,
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
                                      SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: SvgPicture.asset(
                                          color: primaryColorApp,
                                          "assets/icons/barcode.svg",
                                          height: 20,
                                          width: 20,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: _openLoteScreen,
                                        icon: Icon(
                                          Icons.arrow_forward_ios,
                                          color: primaryColorApp,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                  LoteScannerWidget(
                                    controller: _controllerLote,
                                    focusNode: _focusLote,
                                    enabled: _productIsOk && !_loteIsOk,
                                    hintText:
                                        _loteNombreEsperado?.isNotEmpty == true
                                        ? _loteNombreEsperado!
                                        : 'Esperando escaneo',
                                    onValidateLote: _validateLote,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // ubicación destino (solo si el claim trae una asignada)
                      if (widget.claim.locationDestId != null)
                        if (_scanDestinationLocationReception == false)
                          // FIJA: el backend ya la asignó y el permiso no exige
                          // escanearla — solo se muestra, informativa.
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Card(
                                  color: Colors.green[100],
                                  elevation: 5,
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        GestureDetector(
                                          onTap: () =>
                                              _openLocationDestScreen(),
                                          child: Row(
                                            children: [
                                              Text(
                                                'Ubicación destino',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: primaryColorApp,
                                                ),
                                              ),
                                              const Spacer(),
                                              SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: SvgPicture.asset(
                                                  color: primaryColorApp,
                                                  "assets/icons/packing.svg",
                                                  height: 20,
                                                  width: 20,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          _locationDestNombreEsperado ?? '',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else if (_scanDestinationLocationReception == true)
                          // DINÁMICA: hay que escanearla para confirmarla.
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: _locationDestIsOk ? green : yellow,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Card(
                                color: !_locationDestFieldOk
                                    ? Colors.red[200]
                                    : _locationDestIsOk
                                    ? Colors.green[100]
                                    : Colors.grey[300],
                                elevation: 5,
                                child: Container(
                                  width: size.width * 0.85,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        onTap: () => _openLocationDestScreen(),
                                        child: Row(
                                          children: [
                                            Text(
                                              'Ubicación destino',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: primaryColorApp,
                                              ),
                                            ),
                                            const Spacer(),
                                            Image.asset(
                                              "assets/icons/ubicacion.png",
                                              color: primaryColorApp,
                                              width: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                      BarcodeScannerField(
                                        controller: _controllerLocationDest,
                                        focusNode: _focusLocationDest,
                                        onBarcodeScanned: (value, context) =>
                                            _validateLocationDest(value),
                                      ),
                                      Text(
                                        _locationDestIsOk
                                            ? (_locationDestNombreEsperado ??
                                                  '')
                                            : 'Esperando escaneo',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: black,
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
                ),
              ),
            ),
            // segunda unidad de medida
            if (_manejaSegundaUnidad)
              SegundaUnidadInputWidget(
                controller: _controllerSegundaUnidad,
                uomLabel: widget.claim.uomSegundaUnidad ?? '',
                focusNode: _focusSegundaUnidad,
                onChanged: (_) => setState(() {}),
              ),

            // cantidad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Card(
                color: _puedeUsarCantidad ? white : Colors.grey[200],
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      if (_hideExpectedQty == false)
                        Row(
                          children: [
                            const Text(
                              'Recoger:',
                              style: TextStyle(color: black, fontSize: 14),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Text(
                                _pendiente.toString(),
                                style: TextStyle(
                                  color: primaryColorApp,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Text(
                              widget.claim.uom ?? '',
                              style: const TextStyle(
                                color: black,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      const Spacer(),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          alignment: Alignment.center,
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
                                _quantitySelected.toString(),
                                style: const TextStyle(
                                  color: black,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _toggleManualQuantity,
                        icon: Icon(
                          Icons.edit_note_rounded,
                          color: _puedeUsarCantidad ? primaryColorApp : grey,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_viewQuantity)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: SizedBox(
                  height: 40,
                  child: TextFormField(
                    focusNode: _focusQuantityManual,
                    controller: _controllerQuantityManual,
                    enabled: _puedeUsarCantidad,
                    showCursor: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecorations.authInputDecoration(
                      hintText: 'Cantidad',
                      labelText: 'Cantidad',
                      suffixIconButton: IconButton(
                        onPressed: _toggleManualQuantity,
                        icon: const Icon(Icons.clear),
                      ),
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: ElevatedButton(
                onPressed: (_puedeAplicarCantidad && !_isSubmitting)
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
                child: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'APLICAR CANTIDAD',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
