import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/routes/app_router.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_claim.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_pool_item.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_session.dart';
import 'package:wms_app/features/transferencia_multiusuario/presentation/bloc/detail/transferencia_multiusuario_my_claims_bloc.dart';
import 'package:wms_app/features/transferencia_multiusuario/presentation/bloc/detail/transferencia_multiusuario_pool_bloc.dart';
import 'package:wms_app/features/transferencia_multiusuario/presentation/bloc/scan/transferencia_multiusuario_scan_bloc.dart';
import 'package:wms_app/features/transferencia_multiusuario/presentation/widgets/dialog_confirmar_tomar_producto_widget.dart';
import 'package:wms_app/features/transferencia_multiusuario/presentation/widgets/transferencia_pool_item_card_widget.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';
import 'package:wms_app/core/services/configuracion_cache_service.dart';
import 'package:wms_app/shared/widgets/shimmer_list_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';

/// Tab "Por hacer" — pool de productos libres/disponibles en vivo
/// (TransferenciaMultiusuarioPoolBloc). Espejo de
/// RecepcionMultiusuarioDetailTabPorHacer: buscador (por nombre/código/
/// barcode) + escaneo, ambos filtran/ubican en la lista.
///
/// Tocar una card reclama el producto (POST /api/transfer/claim) vía
/// TransferenciaMultiusuarioScanBloc: si el backend confirma que sigue
/// libre, refresca el pool (el producto ya reclamado desaparece de "Por
/// hacer"); si ya lo tomó otro operario, muestra el mensaje y se queda en
/// la lista. Todavía no navega a ninguna pantalla de procesar el producto
/// — no existe aún esa pantalla para transferencias.
class TransferenciaMultiusuarioDetailTabPorHacer extends StatefulWidget {
  const TransferenciaMultiusuarioDetailTabPorHacer({
    super.key,
    required this.session,
  });

  final TransferenciaSession session;

  @override
  State<TransferenciaMultiusuarioDetailTabPorHacer> createState() =>
      _TransferenciaMultiusuarioDetailTabPorHacerState();
}

class _TransferenciaMultiusuarioDetailTabPorHacerState
    extends State<TransferenciaMultiusuarioDetailTabPorHacer> {
  final IAudioService _audioService = getIt<IAudioService>();
  final IVibrationService _vibrationService = getIt<IVibrationService>();

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _scanFocusNode = FocusNode();
  final TextEditingController _scanController = TextEditingController();

  bool _isSearchVisible = false;
  String _searchQuery = '';

  // null mientras carga: el permiso vive en tbl_configurations, no queremos
  // mostrar cantidades como si estuviera activo por falta de datos.
  bool? _hideExpectedQty;

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  Future<void> _cargarConfiguracion() async {
    final userId = await PrefUtils.getUserId();
    final config = await getIt<ConfiguracionCacheService>()
        .getConfiguration(userId);
    if (!mounted) return;
    setState(() {
      _hideExpectedQty = config?.result?.result?.hideExpectedQty == true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // No robar foco si hay un diálogo o modal (p. ej. el de impresión)
    // encima de este tab.
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) return;
    if (_isSearchVisible) return;
    FocusScope.of(context).requestFocus(_scanFocusNode);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scanController.dispose();
    _scanFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() => _isSearchVisible = !_isSearchVisible);
    if (!_isSearchVisible) {
      _searchController.clear();
      setState(() => _searchQuery = '');
      Future.microtask(() => _scanFocusNode.requestFocus());
    }
  }

  void _retry(BuildContext context) {
    final sessionId = widget.session.sessionId;
    if (sessionId == null) return;
    context.read<TransferenciaMultiusuarioPoolBloc>().add(
      // false: solo lo realmente disponible para reclamar — con
      // verification: true el backend también trae tareas agotadas, que
      // acá no tienen nada que hacer.
      FetchTransferenciaPoolEvent(sessionId, verification: false),
    );
  }

  /// Pide confirmación antes de reclamar — un toque accidental en la lista
  /// no debe dejar un producto asignado sin querer.
  void _handleClaimTap(BuildContext context, TransferenciaPoolItem item) {
    final sessionId = widget.session.sessionId;
    final productId = item.productId;

    if (sessionId == null || productId == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => DialogConfirmarTomarProductoWidget(
        productName: item.productName ?? 'este producto',
        onCancel: () => Navigator.pop(dialogContext),
        onAccepted: () {
          Navigator.pop(dialogContext);
          context.read<TransferenciaMultiusuarioScanBloc>().add(
            ClaimProductEvent(sessionId: sessionId, productId: productId),
          );
        },
      ),
    );
  }

  /// A diferencia de la búsqueda manual (que solo filtra la lista), un
  /// escaneo entra directo al primer producto del pool cuyo barcode o
  /// código coincida.
  void _handleScan(String value, BuildContext context) {
    final scan = value.trim().toLowerCase();
    _scanController.clear();
    if (scan.isEmpty) return;

    final items = context.read<TransferenciaMultiusuarioPoolBloc>().poolItems;

    TransferenciaPoolItem? match;
    for (final item in items) {
      if ((item.barcode?.toLowerCase() ?? '') == scan ||
          (item.defaultCode?.toLowerCase() ?? '') == scan) {
        match = item;
        break;
      }
    }

    if (match != null) {
      _handleClaimTap(context, match);
    } else {
      _showScanError();
    }
  }

  void _showScanError() {
    _audioService.playErrorSound();
    _vibrationService.vibrate();
    Future.microtask(() => _scanFocusNode.requestFocus());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Producto no encontrado o no disponible')),
    );
  }

  Future<void> _handleClaimSuccess(
    BuildContext context,
    TransferenciaClaim claim,
  ) async {
    // El claim ya cambió el pool en el backend (el producto quedó
    // bloqueado); refrescamos para que desaparezca de "Por hacer".
    _retry(context);
    // Ya existe la pantalla de procesar el producto: navega directo, igual
    // que RecepcionMultiusuarioDetailTabPorHacer — se espera el regreso
    // para refrescar de nuevo (haya terminado o no la transferencia) y
    // también "Asignados", donde el producto recién reclamado debe
    // aparecer.
    await Navigator.pushNamed(
      context,
      AppRoutes.transferenciaMultiusuarioScanProduct,
      arguments: [widget.session, claim],
    );
    if (!context.mounted) return;
    _retry(context);
    final sessionId = widget.session.sessionId;
    if (sessionId != null) {
      context.read<TransferenciaMultiusuarioMyClaimsBloc>().add(
        FetchMyClaimsEvent(sessionId),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();

    return BlocListener<
      TransferenciaMultiusuarioScanBloc,
      TransferenciaMultiusuarioScanState
    >(
      listener: (context, state) {
        if (state is ClaimProductLoading) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                const DialogLoading(message: 'Reclamando producto...'),
          );
        }
        if (state is ClaimProductSuccess) {
          Navigator.pop(context); // cierra el diálogo de carga
          _handleClaimSuccess(context, state.claim);
        }
        if (state is ClaimProductError) {
          Navigator.pop(context); // cierra el diálogo de carga
          _audioService.playErrorSound();
          _vibrationService.vibrate();
          // Si el rechazo fue porque otro operario ya lo tomó, el pool
          // quedó desactualizado — se refresca al cerrar el diálogo.
          showScrollableErrorDialog(state.message).then((_) {
            if (context.mounted) _retry(context);
          });
        }
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                if (_isSearchVisible)
                  Expanded(
                    child: DynamicSearchBar(
                      controller: _searchController,
                      hintText: 'Buscar producto',
                      // watchdog: reabre el teclado si el IME del PDA
                      // (Zebra/Urovo/Chainway) lo cierra solo.
                      persistentKeyboard: true,
                      onSearchChanged: (value) =>
                          setState(() => _searchQuery = value),
                      onSearchCleared: () => setState(() => _searchQuery = ''),
                    ),
                  )
                else
                  const Spacer(),
                if (!_isSearchVisible)
                  IconButton(
                    icon: Icon(Icons.refresh, color: primaryColorApp),
                    tooltip: 'Actualizar productos disponibles',
                    onPressed: () => _retry(context),
                  ),
                IconButton(
                  icon: Icon(
                    _isSearchVisible ? Icons.close : Icons.search,
                    color: primaryColorApp,
                  ),
                  onPressed: _toggleSearch,
                ),
              ],
            ),
          ),
          BarcodeScannerField(
            controller: _scanController,
            focusNode: _scanFocusNode,
            onBarcodeScanned: (value, context) => _handleScan(value, context),
          ),
          Expanded(
            child:
                BlocBuilder<
                  TransferenciaMultiusuarioPoolBloc,
                  TransferenciaMultiusuarioPoolState
                >(
                  builder: (context, state) {
                    // Solo reacciona a loading/error de SU propio fetch
                    // (verification: false) — un refresco de "Terminados"
                    // (verification: true) no debe mostrar spinner acá.
                    if (state is TransferenciaMultiusuarioPoolInitial ||
                        (state is TransferenciaMultiusuarioPoolLoading &&
                            !state.verification)) {
                      return const ShimmerListWidget();
                    }

                    if (state is TransferenciaMultiusuarioPoolError &&
                        !state.verification) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: red,
                                size: 40,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                state.message,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: grey,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () => _retry(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColorApp,
                                ),
                                child: const Text(
                                  'Reintentar',
                                  style: TextStyle(color: white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final items = context
                        .read<TransferenciaMultiusuarioPoolBloc>()
                        .poolItems;

                    final filteredItems = query.isEmpty
                        ? items
                        : items.where((i) {
                            final name = i.productName?.toLowerCase() ?? '';
                            final code = i.defaultCode?.toLowerCase() ?? '';
                            final barcode = i.barcode?.toLowerCase() ?? '';
                            return name.contains(query) ||
                                code.contains(query) ||
                                barcode.contains(query);
                          }).toList();

                    if (filteredItems.isEmpty) {
                      return Center(
                        child: Text(
                          query.isEmpty
                              ? 'No hay productos disponibles en este momento'
                              : 'No se encontraron resultados',
                          style: const TextStyle(fontSize: 13, color: grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 4),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return InkWell(
                          onTap: () => _handleClaimTap(context, item),
                          child: TransferenciaPoolItemCardWidget(
                            item: item,
                            companyId: widget.session.warehouseId,
                            mostrarCantidad: _hideExpectedQty == false,
                          ),
                        );
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
