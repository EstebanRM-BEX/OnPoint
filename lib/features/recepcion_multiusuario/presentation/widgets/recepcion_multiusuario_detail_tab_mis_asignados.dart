import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/routes/app_router.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_claim.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_session.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/bloc/detail/recepcion_multiusuario_my_claims_bloc.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/bloc/detail/recepcion_multiusuario_pool_bloc.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/widgets/dialog_liberar_asignacion_widget.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/widgets/recepcion_claim_card_widget.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';

/// Tab "Mis asignados" — productos que el usuario actual ya reclamó y sigue
/// trabajando (RecepcionMultiusuarioMyClaimsBloc). Muy parecido al tab "Por
/// hacer": buscador + escaneo que filtran la lista. A diferencia de ese tab,
/// acá tocar una card NO reclama nada (ya está reclamado) — navega directo a
/// scan_product_screen para continuar la recepción. Cada card además tiene
/// la opción de liberar la asignación (POST /api/receipt/claim/{id}/release),
/// con diálogo de confirmación.
class RecepcionMultiusuarioDetailTabMisAsignados extends StatefulWidget {
  const RecepcionMultiusuarioDetailTabMisAsignados({
    super.key,
    required this.session,
  });

  final RecepcionSession session;

  @override
  State<RecepcionMultiusuarioDetailTabMisAsignados> createState() =>
      _RecepcionMultiusuarioDetailTabMisAsignadosState();
}

class _RecepcionMultiusuarioDetailTabMisAsignadosState
    extends State<RecepcionMultiusuarioDetailTabMisAsignados> {
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
    context.read<RecepcionMultiusuarioMyClaimsBloc>().add(
      FetchMyClaimsEvent(sessionId),
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
    _retry(context);
  }

  void _confirmRelease(BuildContext context, RecepcionClaim claim) {
    final claimId = claim.id;
    final sessionId = widget.session.sessionId;
    if (claimId == null || sessionId == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => DialogLiberarAsignacionWidget(
        productName: claim.productName ?? 'este producto',
        onCancel: () => Navigator.pop(dialogContext),
        onAccepted: () {
          Navigator.pop(dialogContext);
          context.read<RecepcionMultiusuarioMyClaimsBloc>().add(
            ReleaseClaimEvent(claimId: claimId, sessionId: sessionId),
          );
        },
      ),
    );
  }

  void _handleScan(String value, BuildContext context) {
    final scan = value.trim().toLowerCase();
    _scanController.clear();
    if (scan.isEmpty) return;

    final state = context.read<RecepcionMultiusuarioMyClaimsBloc>().state;
    final claims = state is RecepcionMyClaimsLoaded
        ? state.claims
        : const <RecepcionClaim>[];

    final match = claims.any((c) => (c.barcode?.toLowerCase() ?? '') == scan);

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
      const SnackBar(content: Text('Producto no encontrado en mis asignados')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();

    return BlocListener<
      RecepcionMultiusuarioMyClaimsBloc,
      RecepcionMultiusuarioMyClaimsState
    >(
      listener: (context, state) {
        if (state is ClaimReleaseLoading) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                const DialogLoading(message: 'Liberando asignación...'),
          );
        }
        if (state is ClaimReleaseSuccess) {
          Navigator.pop(context); // cierra el diálogo de carga
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Asignación liberada')));
          // El producto vuelve a estar libre: refrescamos también el pool.
          final sessionId = widget.session.sessionId;
          if (sessionId != null) {
            context.read<RecepcionMultiusuarioPoolBloc>().add(
              FetchRecepcionPoolEvent(sessionId),
            );
          }
        }
        if (state is ClaimReleaseError) {
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
                  RecepcionMultiusuarioMyClaimsBloc,
                  RecepcionMultiusuarioMyClaimsState
                >(
                  builder: (context, state) {
                    if (state is RecepcionMultiusuarioMyClaimsLoading ||
                        state is RecepcionMultiusuarioMyClaimsInitial) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is RecepcionMultiusuarioMyClaimsError) {
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

                    // Estados transitorios de release (loading/success/error)
                    // no traen su propio listado: seguimos mostrando el
                    // último cargado en vez de vaciar la lista.
                    final claims = state is RecepcionMyClaimsLoaded
                        ? state.claims
                        : context
                              .read<RecepcionMultiusuarioMyClaimsBloc>()
                              .currentClaims;

                    final filteredClaims = query.isEmpty
                        ? claims
                        : claims.where((c) {
                            final name = c.productName?.toLowerCase() ?? '';
                            final barcode = c.barcode?.toLowerCase() ?? '';
                            return name.contains(query) ||
                                barcode.contains(query);
                          }).toList();

                    if (filteredClaims.isEmpty) {
                      return Center(
                        child: Text(
                          query.isEmpty
                              ? 'No tienes productos asignados en este momento'
                              : 'No se encontraron resultados',
                          style: const TextStyle(fontSize: 13, color: grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 4),
                      itemCount: filteredClaims.length,
                      itemBuilder: (context, index) {
                        final claim = filteredClaims[index];
                        return InkWell(
                          onTap: () => _openScanProduct(context, claim),
                          child: RecepcionClaimCardWidget(
                            claim: claim,
                            companyId: widget.session.warehouseId,
                            onRelease: () => _confirmRelease(context, claim),
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
