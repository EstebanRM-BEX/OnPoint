import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_catalogos.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/paquete_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/packages/packing_packages_bloc.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/lista_vacia_pack.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/pack_search_dock.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/packages/paquete_pack_card.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';

/// Pestaña "Paquetes". El lector reconoce cajas (las selecciona) y
/// ubicaciones de muelle (se asignan a las seleccionadas o a la abierta).
class PaquetesTab extends StatefulWidget {
  final bool activo;
  final bool editable;

  /// Pedidos cluster muestran el botón de asignar ubicación.
  final bool esCluster;
  final ValueChanged<List<int>> onImprimir;
  final ValueChanged<PaquetePacking> onEliminar;
  final void Function(PaquetePacking paquete, ProductoPacking producto)
  onDesempacar;
  final ValueChanged<UbicacionMuelle?> onAsignarUbicacion;

  const PaquetesTab({
    super.key,
    required this.activo,
    required this.editable,
    required this.esCluster,
    required this.onImprimir,
    required this.onEliminar,
    required this.onDesempacar,
    required this.onAsignarUbicacion,
  });

  @override
  State<PaquetesTab> createState() => _PaquetesTabState();
}

class _PaquetesTabState extends State<PaquetesTab> with WidgetsBindingObserver {
  final _scanController = TextEditingController();
  final _scanFocus = FocusNode();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  bool _modoScanner = true;
  Timer? _focusRetryTimer;
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchFocus.addListener(_onSearchFocusChanged);
    _scanFocus.addListener(_onScanFocusChanged);
    context.read<PackingPackagesBloc>().add(
      const UbicacionesMuellePackCargadas(),
    );
    if (widget.activo) {
      _enfocarLector();
    }
  }

  @override
  void didUpdateWidget(covariant PaquetesTab old) {
    super.didUpdateWidget(old);
    if (widget.activo && (!old.activo || _modoScanner) && !_searchFocus.hasFocus) {
      _enfocarLector();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (widget.activo && _modoScanner && !_searchFocus.hasFocus) {
        _reconectarLector();
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
      if (_searchController.text.trim().isEmpty && !_modoScanner) {
        setState(() => _modoScanner = true);
        _enfocarLector();
      }
    }
  }

  void _onScanFocusChanged() {
    if (!mounted) return;
    if (_appActiva &&
        _modoScanner &&
        !_scanFocus.hasFocus &&
        !_searchFocus.hasFocus &&
        widget.activo &&
        (ModalRoute.of(context)?.isCurrent ?? true)) {
      _enfocarLector();
    }
  }

  /// Con la pantalla apagada o la app en segundo plano no se pide el foco:
  /// Android cierra la conexión del lector y abrirla en ese estado no sirve.
  /// Al volver, [didChangeAppLifecycleState] la reconecta.
  bool get _appActiva {
    final s = WidgetsBinding.instance.lifecycleState;
    return s == null || s == AppLifecycleState.resumed;
  }

  /// En Android Flutter no toca el foco al bloquear el equipo: el nodo del
  /// lector sigue "enfocado" pero la conexión de entrada quedó muerta, y
  /// `requestFocus()` sobre un nodo que ya tiene el foco no hace nada. Se
  /// suelta y se vuelve a pedir para que el campo abra una conexión nueva.
  void _reconectarLector() {
    if (_scanFocus.hasFocus) _scanFocus.unfocus();
    _enfocarLector();
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

    _focusRetryTimer?.cancel();
    _focusRetryTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted &&
          _appActiva &&
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
    setState(() => _filtro = '');
    _activarLector();
  }

  void _onSearchChanged(String valor) {
    setState(() => _filtro = valor.trim().toLowerCase());
  }

  void _onSearchSubmitted(String valor) {
    final v = valor.trim();
    if (v.isEmpty) return;
    _onEscaneo(v);
  }

  void _onEscaneo(String valor) {
    final bloc = context.read<PackingPackagesBloc>();
    final s = bloc.state;
    if (s.paquetes.any((p) => p.coincideCon(valor))) {
      bloc.add(PaquetePackEscaneado(valor));
      return;
    }
    final v = valor.trim().toLowerCase();
    final ubicacion = s.ubicaciones
        .where((u) => u.barcode.toLowerCase() == v || u.name.toLowerCase() == v)
        .firstOrNull;
    if (ubicacion != null && widget.editable) {
      widget.onAsignarUbicacion(ubicacion);
      return;
    }
    getIt<IAudioService>().playErrorSound();
    getIt<IVibrationService>().vibrate();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Paquete o ubicación no encontrado')),
      );
  }

  bool _coincidePaquete(PaquetePacking p, String q) {
    if (q.isEmpty) return true;
    if (p.name.toLowerCase().contains(q)) return true;
    if (p.packingBarcode.toLowerCase().contains(q)) return true;
    if (p.consecutivo.toLowerCase().contains(q)) return true;
    if (p.locationDestName.toLowerCase().contains(q)) return true;
    if (p.locationDestBarcode.toLowerCase().contains(q)) return true;
    return p.productos.any(
      (prod) =>
          prod.productName.toLowerCase().contains(q) ||
          prod.productCode.toLowerCase().contains(q) ||
          prod.barcode.toLowerCase().contains(q),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PackingPackagesBloc, PackingPackagesState>(
      builder: (context, state) {
        final bloc = context.read<PackingPackagesBloc>();
        final paquetes = state.paquetes;
        final paquetesFiltrados = paquetes
            .where((p) => _coincidePaquete(p, _filtro))
            .toList();
        final seleccion = state.seleccionados;
        final listaSeleccion = _filtro.isEmpty ? paquetes : paquetesFiltrados;
        final todos = listaSeleccion.isNotEmpty &&
            listaSeleccion.every((p) => seleccion.contains(p.id));
        final hayDestino = state.paquetesDestino.isNotEmpty;

        return Scaffold(
          backgroundColor: white,
          floatingActionButton: seleccion.length > 1
              ? FloatingActionButton.extended(
                  heroTag: 'fab-pack-paquetes',
                  backgroundColor: primaryColorApp,
                  onPressed: () => widget.onImprimir(seleccion.toList()),
                  icon: const Icon(Icons.print, color: white),
                  label: Text(
                    '(${seleccion.length})',
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
                hintText: 'Escanear o buscar caja o muelle...',
                onChanged: _onSearchChanged,
                onCleared: _limpiarBusqueda,
                onActivateScanner: _activarLector,
                onSubmitted: _onSearchSubmitted,
                action: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (paquetes.isNotEmpty)
                      Tooltip(
                        message: todos
                            ? 'Deseleccionar todos'
                            : 'Seleccionar todos',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            if (todos) {
                              final idsRestantes = seleccion.difference(
                                listaSeleccion.map((p) => p.id).toSet(),
                              );
                              bloc.add(
                                SeleccionPaquetesPackReemplazada(idsRestantes),
                              );
                            } else {
                              final nuevosIds = {
                                ...seleccion,
                                ...listaSeleccion.map((p) => p.id),
                              };
                              bloc.add(
                                SeleccionPaquetesPackReemplazada(nuevosIds),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              todos
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: todos ? primaryColorApp : grey,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    if (widget.esCluster && widget.editable) ...[
                      const SizedBox(width: 4),
                      Tooltip(
                        message: 'Asignar ubicación de destino',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: hayDestino
                              ? () => widget.onAsignarUbicacion(null)
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.add_location_alt,
                              color: hayDestino
                                  ? primaryColorApp
                                  : grey.withOpacity(0.5),
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                scanner: BarcodeScannerField(
                  controller: _scanController,
                  focusNode: _scanFocus,
                  autofocus: false,
                  clearOnScan: true,
                  refocusOnScan: true,
                  onBarcodeScanned: (v, _) => _onEscaneo(v),
                ),
              ),
              Expanded(
                child: paquetes.isEmpty
                    ? const ListaVaciaPack(
                        titulo: 'No hay paquetes',
                        subtitulo: 'Empaque productos para crear cajas',
                      )
                    : paquetesFiltrados.isEmpty
                        ? const ListaVaciaPack(
                            titulo: 'No se encontraron paquetes',
                            subtitulo: 'Intenta con otro término o código',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 4, bottom: 90),
                            itemCount: paquetesFiltrados.length,
                            itemBuilder: (_, i) {
                              final p = paquetesFiltrados[i];
                              return PaquetePackCard(
                                paquete: p,
                                esCluster: widget.esCluster,
                                onAsignarUbicacion: () =>
                                    widget.onAsignarUbicacion(null),
                                seleccionado: seleccion.contains(p.id),
                                expandido: state.expandido == p.id,
                                editable: widget.editable,
                                onSeleccionar: (v) => bloc.add(
                                  PaquetePackSeleccionado(p.id, seleccionado: v),
                                ),
                                onExpandir: () =>
                                    bloc.add(PaquetePackExpandido(p.id)),
                                onImprimir: () => widget.onImprimir([p.id]),
                                onEliminar: () => widget.onEliminar(p),
                                onDesempacar: (prod) =>
                                    widget.onDesempacar(p, prod),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
