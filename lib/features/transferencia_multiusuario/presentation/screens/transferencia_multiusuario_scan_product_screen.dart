import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/routes/app_router.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/core/usecases/usecase.dart';
import 'package:wms_app/core/services/configuracion_cache_service.dart';
import 'package:wms_app/core/services/ubicaciones_cache_service.dart';
import 'package:wms_app/core/utils/theme/input_decoration.dart';
import 'package:wms_app/features/inventario/domain/usecases/get_url_imagen_producto.dart';
import 'package:wms_app/features/printing/presentation/widgets/modal_printers_list.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_claim.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_lote_producto.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_session.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/usecases/fetch_transferencia_lotes_producto_usecase.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/usecases/finish_transferencia_claim_usecase.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/usecases/heartbeat_transferencia_claim_usecase.dart';
import 'package:wms_app/features/transferencia_multiusuario/presentation/widgets/transferencia_location_origen_dropdown_widget.dart';
import 'package:wms_app/features/transferencia_multiusuario/presentation/widgets/transferencia_product_dropdown_widget.dart';
import 'package:wms_app/features/transferencia_multiusuario/presentation/widgets/transferencia_select_novedad_dialog.dart';
import 'package:wms_app/features/user/domain/entities/user_novelty.dart';
import 'package:wms_app/features/user/domain/usecases/get_user_novelties.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';
import 'package:wms_app/shared/widgets/lote_scanner_widget.dart';
import 'package:wms_app/shared/widgets/scanner_location_widget.dart';
import 'package:wms_app/shared/widgets/scanner_product_widget.dart';
import 'package:wms_app/shared/widgets/segunda_unidad_input_widget.dart';
import 'package:wms_app/shared/utils/keyboard_watchdog.dart';
import 'package:wms_app/src/presentation/models/response_ubicaciones_model.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/dialog_view_img_temp_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_barcodes_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';
import 'package:wms_app/src/presentation/widgets/expiration_badge_widget.dart';

/// Pantalla de transferencia de un producto ya reclamado (TransferenciaClaim)
/// en una sesión de transferencia multiusuario. Espejo de
/// RecepcionMultiusuarioScanProductScreen con un paso extra al inicio: acá
/// SÍ hay que validar la ubicación de ORIGEN (en recepción es solo
/// informativa) — se valida por escaneo contra `claim.locationBarcode`
/// (sin catálogo, a diferencia de destino), o de forma manual (dropdown de
/// un solo ítem) si el permiso `manualSourceLocationTransfer` está activo —
/// mismo permiso que usa el módulo legacy de transferencia interna.
///
/// Cadena de validación: origen → producto → lote (si aplica) → destino
/// (si el permiso exige escanearla) → cantidad.
///
/// El botón "APLICAR CANTIDAD" confirma la transferencia vía
/// POST /api/transfer/claim/{claimId}/done. Si la cantidad es menor a lo
/// pendiente pide seleccionar una novedad primero (no existe backorder/split
/// en multiusuario); si es mayor, se rechaza siempre.
class TransferenciaMultiusuarioScanProductScreen extends StatefulWidget {
  const TransferenciaMultiusuarioScanProductScreen({
    super.key,
    required this.session,
    required this.claim,
    this.initialOrigenValidated = false,
    this.initialProductValidated = false,
    this.initialOrigenValidadoAt,
    this.initialLote,
    this.initialUbicacionDest,
  });

  final TransferenciaSession session;
  final TransferenciaClaim claim;

  // Estado a restaurar al volver de TransferenciaMultiusuarioNewLoteScreen /
  // TransferenciaMultiusuarioLocationDestScreen — como esas pantallas
  // vuelven acá con pushReplacementNamed (ya no Navigator.pop, esta misma
  // pantalla se reemplazó al abrir la otra), se reconstruye de cero y
  // necesita este estado de vuelta para no reobligar a re-escanear
  // origen/producto ni perder el lote/ubicación ya elegidos.
  final bool initialOrigenValidated;
  final bool initialProductValidated;
  final DateTime? initialOrigenValidadoAt;
  final TransferenciaLoteProducto? initialLote;
  final ResultUbicaciones? initialUbicacionDest;

  @override
  State<TransferenciaMultiusuarioScanProductScreen> createState() =>
      _TransferenciaMultiusuarioScanProductScreenState();
}

class _TransferenciaMultiusuarioScanProductScreenState
    extends State<TransferenciaMultiusuarioScanProductScreen>
    with WidgetsBindingObserver {
  final IAudioService _audioService = getIt<IAudioService>();
  final IVibrationService _vibrationService = getIt<IVibrationService>();

  // Ubicación de origen: paso nuevo que no existe en recepción. Se valida
  // por escaneo contra claim.locationBarcode únicamente (sin catálogo ni
  // pantalla de búsqueda manual).
  bool _origenIsOk = false;
  bool _origenFieldOk = true;
  // Permiso manualSourceLocationTransfer (tbl_configurations) — mismo que
  // usa LocationDropdownTransferWidget en el módulo legacy de transferencia
  // interna: si está activo, además de escanear se puede confirmar el
  // origen con un dropdown (sin escáner). null mientras carga.
  bool? _manualSourceLocationTransfer;

  bool _productIsOk = false;
  // Flag de error visual (card roja) del gate de producto, independiente de
  // _productIsOk — se pone en false ante un escaneo que no matchea y vuelve
  // a true en el próximo intento.
  bool _productFieldOk = true;
  bool _loteIsOk = false;
  bool _loteFieldOk = true;
  // Lote elegido/creado desde TransferenciaMultiusuarioNewLoteScreen —
  // cuando no es null, reemplaza a claim.lotName como el lote "esperado".
  TransferenciaLoteProducto? _selectedLote;
  // Lotes existentes del producto (GET /api/lotes/{productId}), cargados si
  // el producto maneja lote.
  List<TransferenciaLoteProducto> _lotesDisponibles = [];
  // Catálogo maestro de ubicaciones (tbl_ubicaciones) — solo para destino.
  List<ResultUbicaciones> _ubicacionesDisponibles = [];
  bool? _scanDestinationLocationReception;
  bool _locationDestIsOk = false;
  bool _locationDestFieldOk = true;
  ResultUbicaciones? _selectedUbicacionDest;
  double _quantitySelected = 0;
  bool _viewQuantity = false;
  bool? _hideExpectedQty;
  bool _isSubmitting = false;
  // Se marca al validar el origen — time_line del envío final es el tiempo
  // transcurrido desde acá hasta que se confirma la transferencia.
  DateTime? _origenValidadoAt;
  // Renueva bloqueado_hasta del claim mientras el operario sigue en esta
  // pantalla, para que no expire (claim_ttl_minutes de la sesión) a mitad
  // del proceso. Sin loading/errores visibles: es un ping en background.
  Timer? _heartbeatTimer;

  final FocusNode _focusOrigen = FocusNode();
  final FocusNode _focusProduct = FocusNode();
  final FocusNode _focusLote = FocusNode();
  final FocusNode _focusLocationDest = FocusNode();
  final FocusNode _focusSegundaUnidad = FocusNode();
  final FocusNode _focusQuantity = FocusNode();
  final FocusNode _focusQuantityManual = FocusNode();

  // Watchdog: reabre el teclado si el IME del PDA (Zebra/Urovo/Chainway) lo
  // cierra solo mientras el campo de cantidad manual conserva el foco.
  late final KeyboardWatchdog _kbWatchdogQuantityManual = KeyboardWatchdog(
    state: this,
    focusNode: _focusQuantityManual,
  );

  final TextEditingController _controllerOrigen = TextEditingController();
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

  /// true si hace falta escanear la ubicación destino para confirmarla
  /// (permiso activo y el claim trae una ubicación destino asignada).
  bool get _requiereEscanearUbicacionDestino =>
      _scanDestinationLocationReception == true &&
      widget.claim.locationDestId != null;

  double get _pendiente =>
      (widget.claim.qtyAsignada ?? 0) - (widget.claim.qtyAlmacenada ?? 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Si el claim no trae un barcode de origen (caso borde), no hay nada
    // que validar — se da por confirmado para no trabar la cadena.
    if ((widget.claim.locationBarcode ?? '').isEmpty) {
      _origenIsOk = true;
      _origenValidadoAt = DateTime.now();
    } else if (widget.initialOrigenValidated) {
      _origenIsOk = true;
      _origenValidadoAt = widget.initialOrigenValidadoAt;
    }
    _productIsOk = widget.initialProductValidated;
    if (widget.initialLote != null) {
      _selectedLote = widget.initialLote;
      _loteIsOk = true;
    }
    if (widget.initialUbicacionDest != null) {
      _selectedUbicacionDest = widget.initialUbicacionDest;
      _locationDestIsOk = true;
      _locationDestFieldOk = true;
    }
    _cargarConfiguracion();
    _cargarLotesProducto();
    _cargarUbicaciones();
    _iniciarHeartbeat();
    // Es un paso más de la cadena de foco secuencial (origen → producto →
    // lote → destino → segunda unidad → cantidad): al perder foco (el
    // operario terminó de escribirla) se reevalúa a dónde sigue el flujo.
    _focusSegundaUnidad.addListener(() {
      if (!_focusSegundaUnidad.hasFocus && mounted) {
        // addPostFrameCallback (no microtask): el campo que sigue en la
        // cadena recién queda "enabled" tras el rebuild de este setState —
        // pedirle el foco antes de que ese rebuild ocurra no toma efecto y
        // el escaneo siguiente se pierde.
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _handleDependencies(),
        );
      }
    });
  }

  @override
  void didChangeMetrics() => _kbWatchdogQuantityManual.onMetricsChanged();

  /// POST /api/transfer/claim/{claimId}/heartbeat cada cierto intervalo,
  /// menor a claim_ttl_minutes de la sesión, para que bloqueado_hasta no
  /// expire mientras el operario sigue trabajando el claim acá. Sin params
  /// confirmados (se asume `{}`, igual que /release). Si falla, no se
  /// interrumpe al operario — se reintenta solo en el próximo tick.
  void _iniciarHeartbeat() {
    final claimId = widget.claim.id;
    if (claimId == null) return;

    final ttlMinutes = widget.session.claimTtlMinutes;
    // Sin TTL confirmado, 5 min es un intervalo conservador (menor al TTL
    // típico de 15 min que se ha visto en los ejemplos reales).
    final intervalMinutes = (ttlMinutes != null && ttlMinutes > 1)
        ? (ttlMinutes / 2).floor().clamp(1, 30)
        : 5;

    _heartbeatTimer = Timer.periodic(Duration(minutes: intervalMinutes), (_) {
      getIt<HeartbeatTransferenciaClaimUseCase>()(
        HeartbeatTransferenciaClaimParams(claimId: claimId),
      );
    });
  }

  Future<void> _cargarConfiguracion() async {
    final userId = await PrefUtils.getUserId();
    final config = await getIt<ConfiguracionCacheService>()
        .getConfiguration(userId);
    if (!mounted) return;
    setState(() {
      _scanDestinationLocationReception =
          config?.result?.result?.scanDestinationLocationReception == true;
      _hideExpectedQty = config?.result?.result?.hideExpectedQty == true;
      _manualSourceLocationTransfer =
          config?.result?.result?.manualSourceLocationTransfer == true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleDependencies());
  }

  /// Trae los lotes existentes del producto (GET /api/lotes/{productId})
  /// para poder validar el escaneo de lote contra cualquiera de ellos. Solo
  /// aplica si el producto maneja lote; falla en silencio.
  Future<void> _cargarLotesProducto() async {
    final productId = widget.claim.productId;
    if (!_manejaLote || productId == null) return;

    final result = await getIt<FetchTransferenciaLotesProductoUseCase>()(
      FetchTransferenciaLotesProductoParams(productId: productId),
    );
    if (!mounted) return;
    result.fold(
      (failure) {},
      (lotes) => setState(() => _lotesDisponibles = lotes),
    );
  }

  /// Catálogo maestro de ubicaciones (tbl_ubicaciones), ya sincronizado
  /// localmente — solo se usa para validar destino (origen valida contra
  /// claim.locationBarcode, no contra este catálogo).
  Future<void> _cargarUbicaciones() async {
    try {
      final ubicaciones = await getIt<UbicacionesCacheService>().getAll();
      if (!mounted) return;
      setState(() => _ubicacionesDisponibles = ubicaciones);
    } catch (_) {}
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

    if (!_origenIsOk) {
      FocusScope.of(context).requestFocus(_focusOrigen);
      return;
    }
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
    if (_manejaSegundaUnidad && !_segundaUnidadIsOk) {
      FocusScope.of(context).requestFocus(_focusSegundaUnidad);
      return;
    }
    if (!_viewQuantity) {
      FocusScope.of(context).requestFocus(_focusQuantity);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _heartbeatTimer?.cancel();
    _kbWatchdogQuantityManual.dispose();
    _focusOrigen.dispose();
    _focusProduct.dispose();
    _focusLote.dispose();
    _focusLocationDest.dispose();
    _focusSegundaUnidad.dispose();
    _focusQuantity.dispose();
    _focusQuantityManual.dispose();
    _controllerOrigen.dispose();
    _controllerProduct.dispose();
    _controllerLote.dispose();
    _controllerLocationDest.dispose();
    _controllerSegundaUnidad.dispose();
    _controllerQuantity.dispose();
    _controllerQuantityManual.dispose();
    super.dispose();
  }

  void _showScanError(String message) {
    _scanFeedback();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Solo sonido + vibración, sin SnackBar — para errores que ocurren
  /// durante el escaneo continuo, donde un mensaje en pantalla interrumpe
  /// más de lo que ayuda.
  void _scanFeedback() {
    _audioService.playErrorSound();
    _vibrationService.vibrate();
  }

  /// Único valor válido: `claim.locationBarcode`. Sin catálogo ni búsqueda
  /// manual — la validación de origen es solo por escaneo.
  void _validateOrigen(String value) {
    final scan = value.trim().toLowerCase();
    _controllerOrigen.clear();
    if (scan.isEmpty) return;

    if (scan == widget.claim.locationBarcode?.toLowerCase()) {
      setState(() {
        _origenIsOk = true;
        _origenFieldOk = true;
        _origenValidadoAt = DateTime.now();
      });
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _handleDependencies(),
      );
    } else {
      setState(() => _origenFieldOk = false);
      _scanFeedback();
      Future.microtask(() => _focusOrigen.requestFocus());
    }
  }

  /// Valida contra el código principal (claim.barcode) o cualquiera de los
  /// códigos de paquete de `claim.productPacking`.
  void _validateProduct(String value) {
    final scan = value.trim().toLowerCase();
    _controllerProduct.clear();
    final coincideBarcodePrincipal =
        scan == widget.claim.barcode?.toLowerCase();
    final coincidePaquete = widget.claim.productPacking.any(
      (p) => p.barcode?.toString().toLowerCase() == scan,
    );

    if (scan.isNotEmpty && (coincideBarcodePrincipal || coincidePaquete)) {
      setState(() {
        _productIsOk = true;
        _productFieldOk = true;
      });
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _handleDependencies(),
      );
    } else {
      setState(() => _productFieldOk = false);
      _scanFeedback();
      Future.microtask(() => _focusProduct.requestFocus());
    }
  }

  /// Confirma el origen sin escanear (dropdown de un solo ítem) — solo
  /// disponible si `manualSourceLocationTransfer` está activo. Mismo efecto
  /// que un scan exitoso.
  void _selectOrigenManually() {
    setState(() {
      _origenIsOk = true;
      _origenFieldOk = true;
      _origenValidadoAt = DateTime.now();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleDependencies());
  }

  /// Confirma el producto sin escanear (dropdown de un solo ítem) — mismo
  /// efecto que un scan exitoso.
  void _selectProductManually() {
    setState(() {
      _productIsOk = true;
      _productFieldOk = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleDependencies());
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

  /// Valida contra el lote preasignado del claim o, si no hay o no
  /// coincide, contra cualquiera de [_lotesDisponibles].
  void _validateLote(String value) {
    final scan = value.trim().toLowerCase();
    _controllerLote.clear();
    if (scan.isEmpty) return;

    final loteName = _loteNombreEsperado?.toLowerCase() ?? '';
    if (loteName.isNotEmpty && scan == loteName) {
      setState(() {
        _loteIsOk = true;
        _loteFieldOk = true;
      });
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _handleDependencies(),
      );
      return;
    }

    TransferenciaLoteProducto? match;
    for (final lote in _lotesDisponibles) {
      if ((lote.name ?? '').toLowerCase() == scan) {
        match = lote;
        break;
      }
    }

    if (match != null) {
      setState(() {
        _selectedLote = match;
        _loteIsOk = true;
        _loteFieldOk = true;
      });
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _handleDependencies(),
      );
    } else {
      setState(() => _loteFieldOk = false);
      _scanFeedback();
      Future.microtask(() => _focusLote.requestFocus());
    }
  }

  /// Abre la pantalla de listar/crear lote — reemplaza esta pantalla;
  /// NewLoteScreen vuelve acá con pushReplacementNamed pasando el lote
  /// elegido, o el mismo estado sin cambios si el operario cancela.
  void _openLoteScreen() {
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.transferenciaMultiusuarioNewLote,
      arguments: [
        widget.session,
        widget.claim,
        _origenValidadoAt,
        _selectedUbicacionDest,
      ],
    );
  }

  /// No valida contra una ubicación destino preasignada: acepta cualquier
  /// código que matchee alguna ubicación del catálogo maestro.
  void _validateLocationDest(String value) {
    final scan = value.trim().toLowerCase();
    _controllerLocationDest.clear();
    if (scan.isEmpty) return;

    ResultUbicaciones? match;
    for (final ubicacion in _ubicacionesDisponibles) {
      if ((ubicacion.barcode ?? '').toLowerCase() == scan) {
        match = ubicacion;
        break;
      }
    }

    if (match != null) {
      setState(() {
        _selectedUbicacionDest = match;
        _locationDestIsOk = true;
        _locationDestFieldOk = true;
      });
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _handleDependencies(),
      );
    } else {
      setState(() => _locationDestFieldOk = false);
      _scanFeedback();
      Future.microtask(() => _focusLocationDest.requestFocus());
    }
  }

  /// Abre la pantalla de buscar/seleccionar ubicación destino — reemplaza
  /// esta pantalla; LocationDestScreen vuelve acá con pushReplacementNamed
  /// pasando la ubicación elegida, o el mismo estado sin cambios si el
  /// operario cancela. No deja entrar si el origen/producto todavía no
  /// fueron validados.
  void _openLocationDestScreen() {
    if (!_origenIsOk || !_productIsOk) {
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.transferenciaMultiusuarioLocationDest,
      arguments: [
        widget.session,
        widget.claim,
        _origenValidadoAt,
        _selectedLote,
      ],
    );
  }

  /// true si la segunda unidad ya está resuelta: no aplica, o el operario
  /// ya la escribió. Paso 4 de la cadena (origen → producto → lote →
  /// destino → segunda unidad → cantidad), antes de poder usar cantidad.
  bool get _segundaUnidadIsOk =>
      !_manejaSegundaUnidad || _controllerSegundaUnidad.text.trim().isNotEmpty;

  /// true si ya se puede escanear/escribir la cantidad.
  bool get _puedeUsarCantidad =>
      _origenIsOk &&
      _productIsOk &&
      (!_manejaLote || _loteIsOk) &&
      (!_requiereEscanearUbicacionDestino || _locationDestIsOk) &&
      _segundaUnidadIsOk;

  String get _cantidadBloqueadaMensaje {
    if (!_origenIsOk) return 'Primero debes validar la ubicación de origen';
    if (!_productIsOk) return 'Primero debes validar el producto';
    if (_manejaLote && !_loteIsOk) return 'Primero debes validar el lote';
    if (_requiereEscanearUbicacionDestino && !_locationDestIsOk) {
      return 'Primero debes validar la ubicación destino';
    }
    if (!_segundaUnidadIsOk) {
      return 'Primero debes ingresar la segunda unidad'
          '${widget.claim.uomSegundaUnidad != null ? ' (${widget.claim.uomSegundaUnidad})' : ''}';
    }
    return 'Completa los pasos anteriores primero';
  }

  bool get _puedeAplicarCantidad =>
      _puedeUsarCantidad &&
      (_quantitySelected > 0 ||
          _controllerQuantityManual.text.trim().isNotEmpty);

  /// Escaneo del código del producto (suma 1) o de un código de paquete de
  /// otherBarcodes/productPacking (suma su cantidad predefinida).
  void _validateQuantityScan(String value) {
    _controllerQuantity.clear();
    if (!_puedeUsarCantidad) {
      _scanFeedback();
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

    _scanFeedback();
    Future.microtask(() => _focusQuantity.requestFocus());
  }

  void _addQuantity(double delta) {
    final nueva = _quantitySelected + delta;
    if (nueva > _pendiente) {
      _scanFeedback();
      Future.microtask(() => _focusQuantity.requestFocus());
      return;
    }

    setState(() => _quantitySelected = nueva);

    // Al completar exactamente lo pendiente se envía solo, sin esperar a
    // que el operario toque "APLICAR CANTIDAD".
    if (nueva == _pendiente) {
      _handleAplicarCantidad();
      return;
    }

    Future.microtask(() => _focusQuantity.requestFocus());
  }

  /// Alterna entre escanear y escribir la cantidad a mano (ícono de lápiz).
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

    await _enviarTransferencia(cantidad, novedad);
  }

  /// Cantidad menor a lo pendiente: no existe backorder/split en
  /// multiusuario todavía. "CONFIRMAR" pide elegir una novedad; "DIVIDIR"
  /// se la salta y envía directo con observación fija "Sin novedad".
  Future<String?> _pedirNovedad(double cantidad) async {
    final novedades = await _obtenerNovedades();
    if (!mounted) return null;
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TransferenciaSelectNovedadDialog(
        cantidad: cantidad,
        pendiente: _pendiente,
        novedades: novedades,
        mostrarCantidadPendiente: _hideExpectedQty == false,
      ),
    );
  }

  /// UserBloc.novedades depende de que ya haya corrido
  /// DownloadNoveltiesEvent (post-login, fire-and-forget) o el botón
  /// "Descargar novedades y ubicaciones" del perfil — en una sesión vieja o
  /// si esa descarga en background todavía no terminó, la lista puede
  /// llegar vacía acá. En vez de mostrar el diálogo de novedad sin
  /// opciones, se pide directo (GET picking_novelties) y se guarda en el
  /// bloc para no repetirlo la próxima vez.
  Future<List<Novedad>> _obtenerNovedades() async {
    final userBloc = context.read<UserBloc>();
    if (userBloc.novedades.isNotEmpty) return userBloc.novedades;

    final result = await getIt<GetUserNovelties>()(NoParams());
    return result.fold((failure) => <Novedad>[], (data) {
      userBloc.novelties = data;
      return data;
    });
  }

  Future<void> _enviarTransferencia(double cantidad, String? novedad) async {
    setState(() => _isSubmitting = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const DialogLoading(message: 'Enviando transferencia...'),
    );

    final lotId = _selectedLote?.id ?? widget.claim.lotId ?? 0;
    final locationDestId =
        _selectedUbicacionDest?.id ?? widget.claim.locationDestId ?? 0;
    final timeLine = _origenValidadoAt == null
        ? 0
        : DateTime.now().difference(_origenValidadoAt!).inSeconds;
    final quantitySegundaUnidad =
        double.tryParse(
          _controllerSegundaUnidad.text.trim().replaceAll(',', '.'),
        ) ??
        0.0;

    final result = await getIt<FinishTransferenciaClaimUseCase>()(
      FinishTransferenciaClaimParams(
        claimId: widget.claim.id ?? 0,
        qtyDone: cantidad,
        lotId: lotId,
        locationDestId: locationDestId,
        timeLine: timeLine,
        // null acá significa que se envió la cantidad completa (no pasó
        // por el diálogo de novedad) — igual se manda una observación fija
        // en vez de vacía.
        observation: novedad ?? 'Sin novedad',
        quantitySegundaUnidad: quantitySegundaUnidad,
      ),
    );

    if (!mounted) return;
    Navigator.pop(context); // cierra el diálogo de carga
    setState(() => _isSubmitting = false);

    result.fold(
      (failure) => showScrollableErrorDialog(failure.message),
      (_) => Navigator.pushReplacementNamed(
        context,
        AppRoutes.transferenciaMultiusuarioDetail,
        arguments: [widget.session],
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
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: primaryColorApp,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pushReplacementNamed(
              context,
              AppRoutes.transferenciaMultiusuarioDetail,
              arguments: [widget.session],
            ),
          ),
          title: Text(
            widget.session.name ?? 'TRANSFERENCIA',
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
                      // ubicación de origen — a diferencia de recepción, acá
                      // SÍ se valida (escaneo contra claim.locationBarcode) —
                      // mismo widget que usa la ubicación de origen en el
                      // módulo legacy de transferencia interna.
                      LocationScannerWidget(
                        isLocationOk: _origenFieldOk,
                        locationIsOk: _origenIsOk,
                        productIsOk: _productIsOk,
                        quantityIsOk: _quantitySelected > 0,
                        locationDestIsOk: _locationDestIsOk,
                        currentLocationId: claim.locationName ?? '',
                        onValidateLocation: _validateOrigen,
                        focusNode: _focusOrigen,
                        controller: _controllerOrigen,
                        locationDropdown:
                            TransferenciaLocationOrigenDropdownWidget(
                              locationName: claim.locationName ?? '',
                              // Permiso manualSourceLocationTransfer: además de
                              // escanear, se puede confirmar sin escáner — mismo
                              // criterio que LocationDropdownTransferWidget en
                              // el módulo legacy de transferencia interna.
                              enabled:
                                  _manualSourceLocationTransfer == true &&
                                  !_origenIsOk,
                              onSelected: _selectOrigenManually,
                            ),
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
                        // El lote y su caducidad ya se muestran en su propia
                        // card más abajo — repetirlos acá es redundante.
                        lotId: '',
                        expireDate: claim.fechaVencimiento,
                        size: size,
                        onValidateProduct: _validateProduct,
                        onViewImgProduct: _handleViewImage,
                        focusNode: _focusProduct,
                        controller: _controllerProduct,
                        productDropdown: TransferenciaProductDropdownWidget(
                          productName: claim.productName ?? '',
                          enabled: _origenIsOk && !_productIsOk,
                          onSelected: _selectProductManually,
                        ),
                        origin: null,
                        expiryWidget: const SizedBox.shrink(),
                        listOfBarcodes: [
                          ...claim.otherBarcodes,
                          ...claim.productPacking,
                        ],
                        onBarcodesDialogTap: _openBarcodesDialog,
                      ),

                      // lote (solo si el producto maneja lote)
                      if (_manejaLote)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: _loteIsOk ? green : yellow,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Card(
                                color: !_loteFieldOk
                                    ? Colors.red[200]
                                    : !_productIsOk
                                    ? Colors.grey[200]
                                    : _loteIsOk
                                    ? Colors.green[100]
                                    : Colors.grey[300],
                                elevation: 5,
                                child: Container(
                                  width: size.width * 0.85,
                                  padding: const EdgeInsets.only(
                                    left: 10,
                                    right: 10,
                                    bottom: 5,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
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
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          LoteScannerWidget(
                                            controller: _controllerLote,
                                            focusNode: _focusLote,
                                            enabled: _productIsOk && !_loteIsOk,
                                            hintText:
                                                _loteNombreEsperado
                                                        ?.isNotEmpty ==
                                                    true
                                                ? _loteNombreEsperado!
                                                : 'Esperando escaneo',
                                            onValidateLote: _validateLote,
                                          ),
                                          ExpirationBadgeWidget(
                                            expirationDate: _loteIsOk
                                                ? (_selectedLote
                                                          ?.expirationDate ??
                                                      widget
                                                          .claim
                                                          .fechaVencimiento)
                                                : null,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
