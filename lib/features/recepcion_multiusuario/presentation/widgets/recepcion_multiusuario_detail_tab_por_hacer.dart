import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/routes/app_router.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_claim.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_pool_item.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_session.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/bloc/detail/recepcion_multiusuario_my_claims_bloc.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/bloc/detail/recepcion_multiusuario_pool_bloc.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/bloc/scan/recepcion_multiusuario_scan_bloc.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/widgets/recepcion_pool_item_card_widget.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';

/// Tab 2 — pool de productos libres/disponibles en vivo
/// (RecepcionMultiusuarioPoolBloc, ya cargado al entrar al detalle).
/// Incluye buscador (por nombre/código/barcode) y escaneo (filtran la
/// lista) — misma funcionalidad que expedicion_detail_tab_por_hacer.dart.
///
/// Tocar una card reclama el producto (POST /api/receipt/claim) vía
/// RecepcionMultiusuarioScanBloc: si el backend confirma que sigue libre,
/// navega a la pantalla de recepción del producto; si ya lo tomó otro
/// operario, muestra el mensaje y se queda en la lista.
class RecepcionMultiusuarioDetailTabPorHacer extends StatefulWidget {
  const RecepcionMultiusuarioDetailTabPorHacer({
    super.key,
    required this.session,
  });

  final RecepcionSession session;

  @override
  State<RecepcionMultiusuarioDetailTabPorHacer> createState() =>
      _RecepcionMultiusuarioDetailTabPorHacerState();
}

class _RecepcionMultiusuarioDetailTabPorHacerState
    extends State<RecepcionMultiusuarioDetailTabPorHacer> {
  final IAudioService _audioService = getIt<IAudioService>();
  final IVibrationService _vibrationService = getIt<IVibrationService>();

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _scanFocusNode = FocusNode();
  final TextEditingController _scanController = TextEditingController();

  bool _isSearchVisible = false;
  String _searchQuery = '';

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
    context.read<RecepcionMultiusuarioPoolBloc>().add(
      FetchRecepcionPoolEvent(sessionId),
    );
  }

  void _handleClaimTap(BuildContext context, RecepcionPoolItem item) {
    final sessionId = widget.session.sessionId;
    final productId = item.productId;
    if (sessionId == null || productId == null) return;
    context.read<RecepcionMultiusuarioScanBloc>().add(
      ClaimProductEvent(sessionId: sessionId, productId: productId),
    );
  }

  Future<void> _openScanProduct(
    BuildContext context,
    RecepcionClaim claim,
  ) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.recepcionMultiusuarioScanProduct,
      arguments: [widget.session, claim],
    );
    if (!context.mounted) return;
    // El claim ya cambió el pool en el backend (el producto quedó
    // bloqueado); refrescamos al volver, haya terminado o no la recepción.
    // También refrescamos "Mis asignados": el producto recién reclamado
    // debe aparecer ahí.
    _retry(context);
    final sessionId = widget.session.sessionId;
    if (sessionId != null) {
      context.read<RecepcionMultiusuarioMyClaimsBloc>().add(
        FetchMyClaimsEvent(sessionId),
      );
    }
  }

  void _handleScan(String value, BuildContext context) {
    final scan = value.trim().toLowerCase();
    _scanController.clear();
    if (scan.isEmpty) return;

    final state = context.read<RecepcionMultiusuarioPoolBloc>().state;
    final items = state is RecepcionPoolLoaded
        ? state.items
        : const <RecepcionPoolItem>[];

    final match = items.any(
      (i) =>
          (i.barcode?.toLowerCase() ?? '') == scan ||
          (i.defaultCode?.toLowerCase() ?? '') == scan,
    );

    if (match) {
      setState(() {
        _searchQuery = value.trim();
        _searchController.text = value.trim();
      });
      Future.microtask(() => _scanFocusNode.requestFocus());
    } else {
      _showScanError();
    }
  }

  void _showScanError() {
    _audioService.playErrorSound();
    _vibrationService.vibrate();
    Future.microtask(() => _scanFocusNode.requestFocus());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Producto no encontrado en el pool')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();

    return BlocListener<
      RecepcionMultiusuarioScanBloc,
      RecepcionMultiusuarioScanState
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
          _openScanProduct(context, state.claim);
        }
        if (state is ClaimProductError) {
          Navigator.pop(context); // cierra el diálogo de carga
          _audioService.playErrorSound();
          _vibrationService.vibrate();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
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
                  RecepcionMultiusuarioPoolBloc,
                  RecepcionMultiusuarioPoolState
                >(
                  builder: (context, state) {
                    if (state is RecepcionMultiusuarioPoolLoading ||
                        state is RecepcionMultiusuarioPoolDbLoading ||
                        state is RecepcionMultiusuarioPoolInitial) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is RecepcionMultiusuarioPoolError) {
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

                    final items = state is RecepcionPoolLoaded
                        ? state.items
                        : const <RecepcionPoolItem>[];

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
                          child: RecepcionPoolItemCardWidget(
                            item: item,
                            companyId: widget.session.warehouseId,
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
