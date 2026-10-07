import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/detail/packing_pedido_detail_bloc.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/lista_vacia_pack.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/producto_pack_card.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/barra_lector_pack.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';

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

class _PorHacerTabState extends State<PorHacerTab> {
  final _scanController = TextEditingController();
  final _scanFocus = FocusNode();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  bool _buscando = false;

  @override
  void initState() {
    super.initState();
    if (widget.activo) _enfocarLector();
  }

  @override
  void didUpdateWidget(covariant PorHacerTab old) {
    super.didUpdateWidget(old);
    // Solo al volver a la pestaña; no en cada rebuild (robaba el foco).
    if (widget.activo && !old.activo && !_buscando) _enfocarLector();
  }

  @override
  void dispose() {
    _scanController.dispose();
    _scanFocus.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _enfocarLector() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && !_buscando) _scanFocus.requestFocus();
  });

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

  void _alternarBusqueda() {
    setState(() => _buscando = !_buscando);
    if (!_buscando) {
      _searchController.clear();
      _bloc.add(const BusquedaProductoPackCambiada(''));
      _enfocarLector();
    }
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
          BarraLectorPack(
            lector: BarcodeScannerField(
              controller: _scanController,
              focusNode: _scanFocus,
              autofocus: false,
              clearOnScan: true,
              refocusOnScan: true,
              onBarcodeScanned: (v, _) => _onEscaneo(v),
            ),
            texto: 'Escanee un producto',
            buscando: _buscando,
            onBuscar: _alternarBusqueda,
            seleccionTodos: puedeEmpacar && !_buscando
                ? (todos
                      ? () => _bloc.add(const SeleccionPackReemplazada([]))
                      : () => _bloc.add(
                          SeleccionPackReemplazada(productos.map((p) => p.id)),
                        ))
                : null,
            todosSeleccionados: todos,
          ),
          if (_buscando)
            DynamicSearchBar(
              controller: _searchController,
              focusNode: _searchFocus,
              hintText: 'Buscar producto',
              closeKeyboardOnClear: false,
              persistentKeyboard: true,
              onSearchChanged: (v) =>
                  _bloc.add(BusquedaProductoPackCambiada(v)),
              onSearchCleared: () =>
                  _bloc.add(const BusquedaProductoPackCambiada('')),
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
                      return ProductoPackCard(
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
