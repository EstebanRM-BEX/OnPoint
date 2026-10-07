import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/detail/packing_pedido_detail_bloc.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/lista_vacia_pack.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/pack_search_dock.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/tabs/producto_por_hacer_card.dart';
import 'package:wms_app/features/printing/presentation/widgets/modal_printers_list.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';

/// Pestaña "Por hacer": escanear un producto lo abre directo en cantidad;
/// tocarlo abre el escaneo completo. Con permiso `scanProduct` se puede
/// seleccionar y empacar sin certificar.
class PorHacerTab extends StatefulWidget {
  final PackingPedidoDetailState state;

  /// La pestaña está a la vista: el lector toma el foco.
  final bool activo;
  final void Function(ProductoPacking producto, bool escaneado) onAbrir;
  final VoidCallback onEmpacar;

  const PorHacerTab({
    super.key,
    required this.state,
    required this.activo,
    required this.onAbrir,
    required this.onEmpacar,
  });

  @override
  State<PorHacerTab> createState() => _PorHacerTabState();
}

class _PorHacerTabState extends State<PorHacerTab> with WidgetsBindingObserver {
  final _scanController = TextEditingController();
  final _scanFocus = FocusNode();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  bool _modoScanner = true;
  Timer? _focusRetryTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchFocus.addListener(_onSearchFocusChanged);
    _scanFocus.addListener(_onScanFocusChanged);
    if (widget.activo) {
      _enfocarLector();
    }
  }

  @override
  void didUpdateWidget(covariant PorHacerTab old) {
    super.didUpdateWidget(old);
    // Solo cuando la pestaña está a la vista y el modo escáner está activo
    if (widget.activo && (!old.activo || _modoScanner) && !_searchFocus.hasFocus) {
      _enfocarLector();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Al despertar el dispositivo del estado de reposo (screen sleep / lock)
    if (state == AppLifecycleState.resumed) {
      if (widget.activo && _modoScanner && !_searchFocus.hasFocus) {
        _enfocarLector();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusRetryTimer?.cancel();
    _searchFocus.removeListener(_onSearchFocusChanged);
    _scanFocus.removeListener(_onScanFocusChanged);
    _scanController.dispose();
    _scanFocus.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchFocusChanged() {
    if (!mounted) return;
    if (_searchFocus.hasFocus) {
      if (_modoScanner) {
        setState(() => _modoScanner = false);
      }
    } else {
      // Si la búsqueda perdió el foco y no hay texto buscado,
      // volvemos a poner el lector como activo automáticamente.
      if (_searchController.text.trim().isEmpty && !_modoScanner) {
        setState(() => _modoScanner = true);
        _enfocarLector();
      }
    }
  }

  void _onScanFocusChanged() {
    if (!mounted) return;
    // El foco debe estar SIEMPRE presente cuando el modo scan está activo.
    // Si se perdió (ej: reposo, toque exterior) y no estamos en búsqueda, lo retomamos.
    if (_modoScanner &&
        !_scanFocus.hasFocus &&
        !_searchFocus.hasFocus &&
        widget.activo &&
        (ModalRoute.of(context)?.isCurrent ?? true)) {
      _enfocarLector();
    }
  }

  void _enfocarLector() {
    if (!mounted || !_modoScanner || _searchFocus.hasFocus) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _modoScanner &&
          !_searchFocus.hasFocus &&
          (ModalRoute.of(context)?.isCurrent ?? true)) {
        _scanFocus.requestFocus();
      }
    });

    // Reintento de seguridad para despertar de reposo en Android (donde el
    // window manager puede tardar unos milisegundos en habilitar el foco).
    _focusRetryTimer?.cancel();
    _focusRetryTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted &&
          _modoScanner &&
          !_searchFocus.hasFocus &&
          !_scanFocus.hasFocus &&
          widget.activo &&
          (ModalRoute.of(context)?.isCurrent ?? true)) {
        _scanFocus.requestFocus();
      }
    });
  }

  void _activarLector() {
    _searchFocus.unfocus();
    if (!_modoScanner) {
      setState(() => _modoScanner = true);
    }
    _enfocarLector();
  }

  void _limpiarBusqueda() {
    _searchController.clear();
    _bloc.add(const BusquedaProductoPackCambiada(''));
    _activarLector();
  }

  void _onSearchSubmitted(String valor) {
    final v = valor.trim();
    if (v.isEmpty) return;
    final p = widget.state.detalle?.porHacerConCodigo(v);
    if (p != null) {
      widget.onAbrir(p, false);
    }
  }

  PackingPedidoDetailBloc get _bloc => context.read<PackingPedidoDetailBloc>();

  void _onEscaneo(String valor) {
    final p = widget.state.detalle?.porHacerConCodigo(valor);
    if (p == null) {
      getIt<IAudioService>().playErrorSound();
      getIt<IVibrationService>().vibrate();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Código no encontrado en por hacer')),
        );
      return;
    }
    widget.onAbrir(p, true);
  }

  Widget _buildSelectAllButton({
    required bool todosSeleccionados,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: todosSeleccionados ? 'Quitar selección' : 'Seleccionar todos',
      child: Material(
        color: todosSeleccionados ? primaryColorApp : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        elevation: todosSeleccionados ? 2 : 0,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox.square(
            dimension: 44,
            child: Icon(
              todosSeleccionados ? Icons.checklist_rtl : Icons.checklist,
              color: todosSeleccionados ? Colors.white : primaryColorApp,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final productos = s.porHacerVisibles;
    final puedeEmpacar = s.config.scanProduct && !s.pedidoTerminado;
    final seleccion = s.seleccionadosPorHacer;
    final todos =
        productos.isNotEmpty &&
        productos.every((p) => s.seleccionados.contains(p.id));

    return Scaffold(
      backgroundColor: white,
      floatingActionButton: puedeEmpacar && seleccion.isNotEmpty
          ? FloatingActionButton.extended(
              heroTag: 'fab-pack-por-hacer',
              backgroundColor: primaryColorApp,
              onPressed: widget.onEmpacar,
              icon: const Icon(Icons.inventory_2, color: white),
              label: Text(
                'Empacar (${seleccion.length})',
                style: const TextStyle(color: white),
              ),
            )
          : null,
      body: Column(
        children: [
          PackSearchDock(
            controller: _searchController,
            searchFocusNode: _searchFocus,
            scannerFocusNode: _scanFocus,
            isScannerActive: _modoScanner,
            hintText: 'Escanear o buscar producto...',
            scanner: BarcodeScannerField(
              controller: _scanController,
              focusNode: _scanFocus,
              autofocus: false,
              clearOnScan: true,
              refocusOnScan: true,
              onBarcodeScanned: (v, _) => _onEscaneo(v),
            ),
            onChanged: (v) => _bloc.add(BusquedaProductoPackCambiada(v)),
            onCleared: _limpiarBusqueda,
            onActivateScanner: _activarLector,
            onSubmitted: _onSearchSubmitted,
            action: puedeEmpacar
                ? _buildSelectAllButton(
                    todosSeleccionados: todos,
                    onPressed: () => _bloc.add(
                      SeleccionPackReemplazada(
                        todos ? const [] : productos.map((p) => p.id),
                      ),
                    ),
                  )
                : null,
          ),
          Expanded(
            child: productos.isEmpty
                ? const ListaVaciaPack(
                    titulo: 'No hay productos por hacer',
                    subtitulo: 'Todo está separado o empacado',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 90),
                    itemCount: productos.length,
                    itemBuilder: (_, i) {
                      final p = productos[i];
                      return ProductoPorHacerCard(
                        producto: p,
                        seleccionado: puedeEmpacar
                            ? s.seleccionados.contains(p.id)
                            : null,
                        onSeleccionar: (v) => _bloc.add(
                          ProductoPackSeleccionado(p.id, seleccionado: v),
                        ),
                        onTap: s.pedidoTerminado
                            ? null
                            : () => widget.onAbrir(p, false),
                        // Mismo destino que el módulo anterior: la línea
                        // (id_move) con la compañía 1.
                        onImprimir: () => ModalPrintersList.show(
                          context,
                          resIds: [p.idMove],
                          companyId: 1,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
