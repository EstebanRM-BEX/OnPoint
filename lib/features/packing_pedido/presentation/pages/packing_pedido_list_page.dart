import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/features/expedition/presentation/widgets/expedicion_list_header_widget.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/pedido_pack.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/list/packing_pedido_list_bloc.dart';
import 'package:wms_app/features/packing_pedido/presentation/pages/packing_pedido_detail_page.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/lista_vacia_pack.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/packing_operacion_listener.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/list/filtro_propietario_sheet.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/list/orden_pedidos_pack_menu.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/list/pedido_pack_card.dart';
import 'package:wms_app/features/picking_cluster/presentation/screens/picking_cluster/widgets/cluster_search_dock.dart';
import 'package:wms_app/features/picking_cluster/presentation/widgets/cluster_palette.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/shared/utils/app_navigation.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/dialog_start_picking_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_start_picking_widget.dart';

/// Lista de pedidos de packing (feature nuevo, aislado del módulo legacy).
class PackingPedidoListPage extends StatelessWidget {
  const PackingPedidoListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<PackingPedidoListBloc>()..add(const ListaPackIniciada()),
      child: const _PackingPedidoListView(),
    );
  }
}

class _PackingPedidoListView extends StatefulWidget {
  const _PackingPedidoListView();

  @override
  State<_PackingPedidoListView> createState() => _PackingPedidoListViewState();
}

class _PackingPedidoListViewState extends State<_PackingPedidoListView> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _scanController = TextEditingController();
  final _scanFocus = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _scanController.dispose();
    _scanFocus.dispose();
    super.dispose();
  }

  PackingPedidoListBloc get _bloc => context.read<PackingPedidoListBloc>();

  void _onEscaneo(String valor) {
    final pedido = _bloc.state.visibles
        .where((p) => p.coincideConEscaneo(valor))
        .firstOrNull;
    if (pedido == null) {
      getIt<IAudioService>().playErrorSound();
      getIt<IVibrationService>().vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido no encontrado en la lista')),
      );
      return;
    }
    _onTapPedido(pedido);
  }

  /// Sin responsable → confirmar y asignar; sin inicio → confirmar inicio;
  /// si no, se abre directo.
  void _onTapPedido(PedidoPack pedido) {
    if (!pedido.tieneResponsable) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => DialogAsignUserWidget(
          title:
              'Esta seguro de tomar este pedido de packing, una vez aceptado no '
              'podrá ser cancelada desde la app, una vez asignada se registrará '
              'el tiempo de inicio de la operación.',
          onCancel: () {
            Navigator.pop(dialogContext);
            _scanFocus.requestFocus();
          },
          onAccepted: () {
            Navigator.pop(dialogContext);
            _bloc.add(ResponsablePackAsignado(pedido.id));
          },
        ),
      );
      return;
    }
    if (!pedido.iniciado) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => DialogStartTimeWidget(
          title: 'Iniciar Packing',
          onAccepted: () {
            Navigator.pop(dialogContext);
            _bloc.add(InicioPedidoPackRegistrado(pedido));
          },
        ),
      );
      return;
    }
    _abrir(pedido);
  }

  Future<void> _abrir(PedidoPack pedido) async {
    _searchController.clear();
    _bloc.add(const BusquedaPedidoPackCambiada(''));
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PackingPedidoDetailPage(pedidoId: pedido.id),
      ),
    );
    if (!mounted) return;
    // Al volver: lo local cambió (paquetes, validado, etc.).
    _bloc.add(const ListaPackIniciada());
    _scanFocus.requestFocus();
  }

  /// Siempre a Home limpiando el stack: a esta lista se entra con
  /// `pushReplacementNamed` desde Home, así que lo que haya debajo no es
  /// Home sino lo que sobró de antes (p. ej. 'enterprice' del login), y un
  /// `pop()` lo dejaba a la vista con la sesión todavía abierta.
  void _volver() => goHome(context);

  @override
  Widget build(BuildContext context) {
    return PackingOperacionListener<
      PackingPedidoListBloc,
      PackingPedidoListState
    >(
      operacion: (s) => s.operacion,
      exitosSilenciosos: const {'sincronizar', 'abrir'},
      onExito: (context, state, op) {
        if (op.accion == 'sincronizar' && state.needUpdateVersion) {
          Get.snackbar(
            '360 Software Informa',
            'Hay una nueva versión disponible. Actualiza desde la '
                'configuración de la app, pulsando el nombre de usuario en el '
                'Home',
            backgroundColor: white,
            colorText: primaryColorApp,
            icon: const Icon(Icons.error, color: Colors.amber),
            duration: const Duration(seconds: 5),
          );
        }
        if (op.accion == 'abrir' && state.pedidoAbierto != null) {
          _abrir(state.pedidoAbierto!);
        }
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _volver();
        },
        child: Scaffold(
          backgroundColor: ClusterPalette.surface,
          body: BlocBuilder<PackingPedidoListBloc, PackingPedidoListState>(
            builder: (context, state) {
              final pedidos = state.visibles;
              return Column(
                children: [
                  ExpedicionListHeaderWidget(
                    title: 'PACKING PEDIDOS',
                    onBack: _volver,
                    onRefresh: () {
                      if (state.sincronizando) return;
                      _bloc.add(const ListaPackSincronizada());
                    },
                    onPropietarioActivoTap: state.propietario == null
                        ? null
                        : () => _filtrarPropietario(state),
                    menu: OrdenPedidosPackMenu(
                      orden: state.orden,
                      ascendente: state.ascendente,
                      propietario: state.propietario,
                      soloMios: state.soloMios,
                      onOrden: (o, asc) => _bloc.add(
                        OrdenPedidosPackCambiado(o, ascendente: asc),
                      ),
                      onFiltrarPropietario: () => _filtrarPropietario(state),
                      onSoloMios: () => _bloc.add(
                        SoloMisPedidosPackCambiado(!state.soloMios),
                      ),
                    ),
                  ),
                  ClusterSearchDock(
                    controller: _searchController,
                    searchFocusNode: _searchFocus,
                    scannerFocusNode: _scanFocus,
                    hintText: 'Buscar pedido',
                    scanner: BarcodeScannerField(
                      controller: _scanController,
                      focusNode: _scanFocus,
                      clearOnScan: true,
                      refocusOnScan: true,
                      onBarcodeScanned: (value, _) => _onEscaneo(value),
                    ),
                    onChanged: (v) => _bloc.add(BusquedaPedidoPackCambiada(v)),
                    onCleared: () {
                      _searchController.clear();
                      _bloc.add(const BusquedaPedidoPackCambiada(''));
                      _scanFocus.requestFocus();
                    },
                    onActivateScanner: () => _scanFocus.requestFocus(),
                  ),
                  if (state.sincronizando) const LinearProgressIndicator(),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async =>
                          _bloc.add(const ListaPackSincronizada()),
                      child: pedidos.isEmpty
                          ? ListaVaciaPack(
                              titulo: 'No se encontraron resultados',
                              subtitulo:
                                  'Intenta con otra búsqueda o actualiza',
                              cargando:
                                  state.status == ListaPackStatus.cargando,
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: pedidos.length,
                              itemBuilder: (_, i) => PedidoPackCard(
                                pedido: pedidos[i],
                                onTap: () => _onTapPedido(pedidos[i]),
                              ),
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _filtrarPropietario(PackingPedidoListState state) {
    showFiltroPropietarioSheet(
      context,
      propietarios: state.propietarios,
      actual: state.propietario,
      onElegido: (p) => _bloc.add(PropietarioPackFiltrado(p)),
    );
  }
}
