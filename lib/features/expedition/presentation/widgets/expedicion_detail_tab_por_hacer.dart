import 'package:flutter/material.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/routes/app_router.dart';
import 'package:wms_app/features/expedition/domain/entities/expedicion_detail.dart';
import 'package:wms_app/features/expedition/domain/entities/item_suelto_expedicion.dart';
import 'package:wms_app/features/expedition/domain/entities/paquete_expedicion.dart';
import 'package:wms_app/features/expedition/presentation/widgets/expedicion_item_suelto_row_widget.dart';
import 'package:wms_app/features/expedition/presentation/widgets/expedicion_paquete_row_widget.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';

/// Tab "Por hacer": paquetes e items sueltos aún no validados. Tocar uno
/// navega a scan_product_screen (validación aún solo visual, sin backend).
/// Incluye buscador (por nombre/código/barcode) y escaneo (por
/// packing_barcode en paquetes, barcode en productos sueltos) que hacen lo
/// mismo que un tap — misma funcionalidad que tab2.dart de packing.
class ExpedicionDetailTabPorHacer extends StatefulWidget {
  final ExpedicionDetail detail;

  const ExpedicionDetailTabPorHacer({super.key, required this.detail});

  @override
  State<ExpedicionDetailTabPorHacer> createState() =>
      _ExpedicionDetailTabPorHacerState();
}

class _ExpedicionDetailTabPorHacerState
    extends State<ExpedicionDetailTabPorHacer> {
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
    // Mientras el buscador está visible no le robamos el foco al campo de
    // escaneo (mismo guard que tab2.dart de packing).
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

  void _navigateToPaquete(BuildContext context, PaqueteExpedicion paquete) {
    Navigator.pushNamed(context, AppRoutes.scanProductExpedition,
        arguments: [paquete]);
  }

  void _navigateToItemSuelto(BuildContext context, ItemSueltoExpedicion item) {
    Navigator.pushNamed(context, AppRoutes.scanProductExpedition,
        arguments: [null, item]);
  }

  void _handleScan(String value, BuildContext context) {
    final scan = value.trim().toLowerCase();
    _scanController.clear();
    if (scan.isEmpty) return;

    for (final paquete in widget.detail.paquetesPendientes) {
      if (paquete.packingBarcode?.toLowerCase() == scan) {
        _navigateToPaquete(context, paquete);
        Future.microtask(() => _scanFocusNode.requestFocus());
        return;
      }
    }

    for (final item in widget.detail.itemsSueltosPendientes) {
      if (item.barcode?.toLowerCase() == scan) {
        _navigateToItemSuelto(context, item);
        Future.microtask(() => _scanFocusNode.requestFocus());
        return;
      }
    }

    _showScanError();
  }

  void _showScanError() {
    _audioService.playErrorSound();
    _vibrationService.vibrate();
    Future.microtask(() => _scanFocusNode.requestFocus());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código no encontrado en la lista')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();

    final paquetes = [...widget.detail.paquetesPendientes]
      ..sort((a, b) => (a.orderPacking ?? 0).compareTo(b.orderPacking ?? 0));
    final itemsSueltos = [...widget.detail.itemsSueltosPendientes]
      ..sort((a, b) => (a.orderPacking ?? 0).compareTo(b.orderPacking ?? 0));

    final paquetesFiltrados = query.isEmpty
        ? paquetes
        : paquetes
            .where((p) =>
                (p.packageName?.toLowerCase().contains(query) ?? false) ||
                (p.packingBarcode?.toLowerCase().contains(query) ?? false))
            .toList();

    final itemsFiltrados = query.isEmpty
        ? itemsSueltos
        : itemsSueltos
            .where((i) =>
                (i.productName?.toLowerCase().contains(query) ?? false) ||
                (i.productCode?.toLowerCase().contains(query) ?? false) ||
                (i.barcode?.toLowerCase().contains(query) ?? false))
            .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              if (_isSearchVisible)
                Expanded(
                  child: DynamicSearchBar(
                    controller: _searchController,
                    hintText: 'Buscar producto o paquete',
                    onSearchChanged: (value) =>
                        setState(() => _searchQuery = value),
                    onSearchCleared: () => setState(() => _searchQuery = ''),
                  ),
                )
              else
                const Spacer(),
              IconButton(
                icon: Icon(_isSearchVisible ? Icons.close : Icons.search,
                    color: primaryColorApp),
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
          child: paquetesFiltrados.isEmpty && itemsFiltrados.isEmpty
              ? Center(
                  child: Text(
                    query.isEmpty
                        ? 'No hay productos pendientes'
                        : 'No se encontraron resultados',
                    style: const TextStyle(color: grey, fontSize: 14),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    if (paquetesFiltrados.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        child: Text(
                          'Paquetes',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      ...paquetesFiltrados.map((p) => InkWell(
                            onTap: () => _navigateToPaquete(context, p),
                            child: ExpedicionPaqueteRowWidget(paquete: p),
                          )),
                    ],
                    if (itemsFiltrados.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        child: Text(
                          'Productos sueltos',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      ...itemsFiltrados.map((i) => InkWell(
                            onTap: () => _navigateToItemSuelto(context, i),
                            child: ExpedicionItemSueltoRowWidget(item: i),
                          )),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
