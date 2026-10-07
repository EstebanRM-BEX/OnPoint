import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/inventario/domain/usecases/get_url_imagen_producto.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/packing_catalogos.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/paquete_packing.dart';
import 'package:wms_app/features/packing_pedido/domain/entities/producto_packing.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/confirm/packing_confirm_bloc.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/detail/packing_pedido_detail_bloc.dart';
import 'package:wms_app/features/packing_pedido/presentation/bloc/packages/packing_packages_bloc.dart';
import 'package:wms_app/features/packing_pedido/presentation/pages/packing_scan_page.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/common/packing_operacion_listener.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/detail/detalle_pack_header.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/dialogs/backorder_pack_dialog.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/dialogs/confirmar_accion_pack_dialog.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/dialogs/confirmar_paquete_dialog.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/dialogs/ubicacion_muelle_sheet.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/tabs/detalle_pedido_tab.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/tabs/empacados_tab.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/tabs/paquetes_tab.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/tabs/por_hacer_tab.dart';
import 'package:wms_app/features/packing_pedido/presentation/widgets/tabs/preparados_tab.dart';
import 'package:wms_app/features/printing/presentation/widgets/modal_printers_list.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/dialog_view_img_temp_widget.dart';

/// Detalle de un pedido con sus 5 pestañas.
class PackingPedidoDetailPage extends StatelessWidget {
  final int pedidoId;
  final int tabInicial;

  const PackingPedidoDetailPage({
    super.key,
    required this.pedidoId,
    this.tabInicial = 0,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              getIt<PackingPedidoDetailBloc>()
                ..add(DetallePackIniciado(pedidoId)),
        ),
        BlocProvider(create: (_) => getIt<PackingPackagesBloc>()),
        BlocProvider(create: (_) => getIt<PackingConfirmBloc>()),
      ],
      child: _DetailView(tabInicial: tabInicial),
    );
  }
}

class _DetailView extends StatefulWidget {
  final int tabInicial;
  const _DetailView({required this.tabInicial});

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs =
      TabController(length: 5, vsync: this, initialIndex: widget.tabInicial)
        ..addListener(() {
          if (!_tabs.indexIsChanging) setState(() {});
        });

  static const _tabPorHacer = 1;
  static const _tabPaquetes = 4;

  PackingPedidoDetailBloc get _detail =>
      context.read<PackingPedidoDetailBloc>();
  PackingPackagesBloc get _packages => context.read<PackingPackagesBloc>();

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ── Acciones ──────────────────────────────────────────────────────────────

  Future<void> _abrirProducto(ProductoPacking p, bool escaneado) async {
    final separado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            PackingScanPage(producto: p, productoEscaneado: escaneado),
      ),
    );
    if (!mounted) return;
    _detail.add(const DetallePackRecargado());
    // Tras separar se queda (o vuelve) en "Por hacer" para seguir.
    if (separado == true && _tabs.index != _tabPorHacer) {
      _tabs.animateTo(_tabPorHacer);
    }
  }

  void _empacar({required bool certificado}) {
    final s = _detail.state;
    final pedido = s.detalle?.pedido;
    if (pedido == null) return;
    // "Preparado" empaca todos (como el módulo anterior): se seleccionan
    // todos los listos sin tocar lo elegido en "Por hacer".
    final listos = s.detalle?.listos ?? const <ProductoPacking>[];
    if (certificado) {
      _detail.add(
        SeleccionPackReemplazada({
          ...s.seleccionadosPorHacer.map((p) => p.id),
          ...listos.map((p) => p.id),
        }),
      );
    }
    final cantidad = certificado
        ? listos.length
        : s.seleccionadosPorHacer.length;
    showDialog(
      context: context,
      builder: (_) => ConfirmarPaqueteDialog(
        cantidadProductos: cantidad,
        certificado: certificado,
        manejaPeso: pedido.esCluster,
        manejaTipoEmpaque: pedido.esCluster,
        onConfirm: (tipo, peso) => _detail.add(
          PaquetePackCreado(
            certificado: certificado,
            peso: peso,
            tipoEmpaque: tipo,
          ),
        ),
      ),
    );
  }

  Future<void> _verImagenProducto(int idProduct) async {
    final r = await getIt<GetUrlImagenProducto>()(
      GetUrlImagenProductoParams(productId: idProduct),
    );
    if (!mounted) return;
    r.fold(
      (_) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Imagen no disponible'))),
      (url) => showImageDialog(context, url),
    );
  }

  Future<void> _deshacer(ProductoPacking p) async {
    final ok = await confirmarAccionPack(
      context,
      titulo: 'Devolver a por hacer',
      mensaje: '¿Devolver ${p.productName} a por hacer?',
    );
    if (ok && mounted) _detail.add(SeparacionPackDeshecha(p));
  }

  void _imprimir(List<int> ids, {dynamic companyId = 1}) {
    ModalPrintersList.show(context, resIds: ids, companyId: companyId);
  }

  Future<void> _eliminarPaquete(PaquetePacking p) async {
    final ok = await confirmarAccionPack(
      context,
      titulo: 'Eliminar paquete',
      mensaje: '¿Eliminar ${p.name}? Sus productos vuelven a por hacer.',
      aceptar: 'Eliminar',
      destructiva: true,
    );
    if (ok && mounted) _packages.add(PaquetePackEliminado(p));
  }

  Future<void> _desempacar(PaquetePacking paquete, ProductoPacking p) async {
    final ok = await confirmarAccionPack(
      context,
      titulo: 'Desempacar',
      mensaje: '¿Sacar ${p.productName} de ${paquete.name}?',
      aceptar: 'Desempacar',
      destructiva: true,
    );
    if (ok && mounted) _packages.add(ProductoPackDesempacado(paquete, p));
  }

  Future<void> _asignarUbicacion(UbicacionMuelle? escaneada) async {
    final ubicacion =
        escaneada ?? await showUbicacionMuelleSheet(context, _packages);
    if (ubicacion == null || !mounted) return;
    final destino = _packages.state.paquetesDestino;
    if (destino.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione o abra un paquete')),
      );
      return;
    }
    final ok = await confirmarAccionPack(
      context,
      titulo: 'Confirmación',
      mensaje: destino.length == 1
          ? '¿Asignar la ubicación ${ubicacion.name} a ${destino.first.name}?'
          : '¿Asignar la ubicación ${ubicacion.name} a ${destino.length} '
                'paquetes?',
    );
    if (!ok || !mounted) return;
    _packages
      ..add(UbicacionMuellePackElegida(ubicacion))
      ..add(const UbicacionPaquetesPackAsignada());
  }

  Future<void> _confirmarPedido() async {
    final detalle = _detail.state.detalle;
    if (detalle == null) return;
    final crearBackorder = await showBackorderPackDialog(
      context,
      progresoEmpacado: detalle.progresoEmpacado,
      hayPendientes: detalle.porHacer.isNotEmpty,
      createBackorder: detalle.pedido.createBackorder,
      onImprimir: () => _imprimir([
        detalle.pedido.id,
      ], companyId: detalle.pedido.warehouseId ?? 1),
    );
    if (crearBackorder == null || !mounted) return;
    context.read<PackingConfirmBloc>().add(
      ValidacionPackSolicitada(detalle, crearBackorder: crearBackorder),
    );
  }

  Future<void> _preguntarVencidos(String mensaje) async {
    final confirm = context.read<PackingConfirmBloc>();
    final ok = await confirmarAccionPack(
      context,
      titulo: '360 Software Informa',
      mensaje:
          'Algunos productos tienen fecha de caducidad alcanzada.\n'
          '¿Desea continuar con la confirmación aceptando los productos '
          'vencidos?',
      aceptar: 'Continuar',
    );
    confirm.add(
      ok ? const VencidosPackAceptados() : const VencidosPackRechazados(),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Los paquetes salen del detalle.
        BlocListener<PackingPedidoDetailBloc, PackingPedidoDetailState>(
          listenWhen: (a, b) => a.detalle != b.detalle && b.detalle != null,
          listener: (_, s) => _packages.add(
            PaquetesPackActualizados(s.detalle!.pedido, s.detalle!.paquetes),
          ),
        ),
        // Cambios confirmados en paquetes → recargar el detalle.
        BlocListener<PackingPackagesBloc, PackingPackagesState>(
          listenWhen: (a, b) => a.cambios != b.cambios,
          listener: (_, __) => _detail.add(const DetallePackRecargado()),
        ),
        BlocListener<PackingConfirmBloc, PackingConfirmState>(
          listenWhen: (a, b) =>
              a.vencidosPendientes == null && b.vencidosPendientes != null,
          listener: (_, s) => _preguntarVencidos(s.operacion.mensaje),
        ),
      ],
      child:
          PackingOperacionListener<
            PackingPedidoDetailBloc,
            PackingPedidoDetailState
          >(
            operacion: (s) => s.operacion,
            child:
                PackingOperacionListener<
                  PackingPackagesBloc,
                  PackingPackagesState
                >(
                  operacion: (s) => s.operacion,
                  child:
                      PackingOperacionListener<
                        PackingConfirmBloc,
                        PackingConfirmState
                      >(
                        operacion: (s) => s.operacion,
                        onExito: (context, state, op) {
                          if (op.accion == 'validar' && state.validado) {
                            Navigator.of(context).pop();
                          }
                        },
                        child:
                            BlocBuilder<
                              PackingPedidoDetailBloc,
                              PackingPedidoDetailState
                            >(
                              builder: (context, state) =>
                                  _buildScaffold(state),
                            ),
                      ),
                ),
          ),
    );
  }

  Widget _buildScaffold(PackingPedidoDetailState state) {
    final detalle = state.detalle;
    final pedido = detalle?.pedido;
    final editable = !(pedido?.isTerminate ?? true);

    return Scaffold(
      backgroundColor: white,
      body: Column(
        children: [
          DetallePackHeader(
            titulo: pedido?.name ?? 'PACKING',
            onBack: () => Navigator.of(context).pop(),
            onImprimir: pedido == null
                ? null
                : () => _imprimir([
                    pedido.id,
                  ], companyId: pedido.warehouseId ?? 1),
            controller: _tabs,
            tabs: [
              const TabContadorPack('Detalles', Icons.details, -1, red),
              TabContadorPack(
                'Por hacer',
                Icons.pending_actions,
                detalle?.porHacer.length ?? 0,
                Colors.red,
              ),
              TabContadorPack(
                'Preparado',
                Icons.star,
                detalle?.listos.length ?? 0,
                yellow,
              ),
              TabContadorPack(
                'Listo',
                Icons.done,
                detalle?.empacados.length ?? 0,
                green,
              ),
              TabContadorPack(
                'Paquetes',
                Icons.inventory_2_outlined,
                detalle?.paquetes.length ?? 0,
                green,
              ),
            ],
          ),
          Expanded(
            child: detalle == null
                ? Center(
                    child: state.status == DetallePackStatus.error
                        ? const Text('No se pudo cargar el pedido')
                        : const CircularProgressIndicator(),
                  )
                : TabBarView(
                    controller: _tabs,
                    children: [
                      DetallePedidoTab(
                        detalle: detalle,
                        onConfirmar:
                            editable && !state.config.hideValidatePacking
                            ? _confirmarPedido
                            : null,
                      ),
                      PorHacerTab(
                        state: state,
                        activo: _tabs.index == _tabPorHacer,
                        onAbrir: _abrirProducto,
                        onEmpacar: () => _empacar(certificado: false),
                      ),
                      PreparadosTab(
                        state: state,
                        onEmpacar: () => _empacar(certificado: true),
                        onDeshacer: _deshacer,
                      ),
                      EmpacadosTab(
                        empacados: detalle.empacados,
                        onVerImagenProducto: _verImagenProducto,
                      ),
                      PaquetesTab(
                        activo: _tabs.index == _tabPaquetes,
                        editable: editable,
                        esCluster: detalle.pedido.esCluster,
                        onImprimir: _imprimir,
                        onEliminar: _eliminarPaquete,
                        onDesempacar: _desempacar,
                        onAsignarUbicacion: _asignarUbicacion,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
