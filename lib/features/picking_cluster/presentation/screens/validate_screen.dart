import 'package:flutter/material.dart';
import 'package:wms_app/shared/utils/app_navigation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/features/picking_cluster/presentation/bloc/cluster_picking/cluster_picking_bloc.dart';
import 'package:wms_app/features/picking_cluster/presentation/bloc/validate_cluster/validate_cluster_bloc.dart';
import 'package:wms_app/features/picking_cluster/presentation/bloc/picking_cluster_list/picking_cluster_list_bloc.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/pedido_validate.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/batch_product.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';
import 'package:wms_app/features/picking_cluster/presentation/widgets/cluster_palette.dart';
import 'package:wms_app/features/picking_cluster/presentation/widgets/cluster_action_footer.dart';
import 'package:wms_app/features/picking_cluster/presentation/widgets/validate/pedido_validate_card.dart';
import 'package:wms_app/features/picking_cluster/presentation/widgets/validate/validate_batch_header.dart';
import 'package:wms_app/features/picking_cluster/presentation/widgets/validate/validate_batch_menu.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';

class ValidateScreen extends StatefulWidget {
  const ValidateScreen({super.key});

  @override
  State<ValidateScreen> createState() => _ValidateScreenState();
}

class _ValidateScreenState extends State<ValidateScreen> {
  final IAudioService _audioService = getIt<IAudioService>();
  final IVibrationService _vibrationService = getIt<IVibrationService>();

  final FocusNode focusNodeBuscar = FocusNode();
  final TextEditingController _controllerToDo = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Escuchamos el foco GLOBAL, no solo el del lector: si otro nodo lo toma
    // antes de que el lector lo tenga alguna vez (pantalla anterior con
    // requestFocus retrasados, el unfocus del Enter, el menú), un listener
    // sobre focusNodeBuscar nunca se entera y el escaneo se pierde.
    // Mismo patrón que PedidosReadyDialog.
    FocusManager.instance.addListener(_keepScannerFocus);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) focusNodeBuscar.requestFocus();
    });
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_keepScannerFocus);
    focusNodeBuscar.dispose();
    _controllerToDo.dispose();
    super.dispose();
  }

  // Mientras esta pantalla sea la ruta activa, el foco vuelve al lector.
  void _keepScannerFocus() {
    if (focusNodeBuscar.hasFocus) return;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted &&
          !focusNodeBuscar.hasFocus &&
          ModalRoute.of(context)?.isCurrent == true) {
        focusNodeBuscar.requestFocus();
      }
    });
  }

  /// Errores en el diálogo estándar de la app, no en snackbar: el operario
  /// debe leerlo y aceptarlo. Al cerrarlo el foco vuelve al lector.
  Future<void> _showError(String message) async {
    _vibrationService.vibrate();
    _audioService.playErrorSound();
    await showScrollableErrorDialog(message);
    if (mounted) focusNodeBuscar.requestFocus();
  }

  void validateBarcode(String value, BuildContext context) {
    _controllerToDo.clear();
    debugPrint('🔎 Scan barcode: ${value.trim()}');
    context.read<ValidateClusterBloc>().add(ScanBarcodeValidateEvent(value));
    Future.microtask(() {
      if (mounted) focusNodeBuscar.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClusterPalette.slate50,
      body: MultiBlocListener(
        listeners: [
          // Listener propio: todo el feedback de esta pantalla viene de ValidateClusterBloc
          BlocListener<ValidateClusterBloc, ValidateClusterState>(
            listener: (context, state) {
              if (state is BarcodeValidateNotFoundState) {
                _showError('Código no encontrado en la lista');
              }

              if (state is MarkPedidoValidatedSuccessState) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pedido validado'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }

              if (state is ValidatePedidoErrorState) {
                _showError(state.msg);
              }

              if (state is BatchNotAllValidatedState) {
                _showError(state.message);
              }

              if (state is BatchCloseLoadingState) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const DialogLoading(message: "Cerrando Batch..."),
                );
              }

              if (state is BatchClosedSuccessState) {
                if (Navigator.canPop(context)) Navigator.pop(context);
                context.read<PickingClusterListBloc>().add(
                  const FetchClustersEvent(),
                );
                Navigator.of(context).popUntil((route) => route.isFirst);
                goToScreen(context, 'picking-cluster');
              }

              if (state is BatchCloseErrorState) {
                if (Navigator.canPop(context)) Navigator.pop(context);
                _showError(state.message);
              }
            },
          ),
          // Listener del BLoC compartido: solo sync offline
          BlocListener<ClusterPickingBloc, ClusterPickingState>(
            listener: (context, state) {
              if (state is SyncPendingClusterLoading) {
                // sync en background — sin dialog para no bloquear la pantalla
              }
            },
          ),
        ],
        child: BlocBuilder<ClusterPickingBloc, ClusterPickingState>(
          builder: (context, state) {
            final bloc = context.read<ClusterPickingBloc>();
            final pedidos = bloc.pedidosValidate;
            final products = bloc.filteredProducts;

            if (pedidos.isEmpty) {
              return const Center(
                child: Text(
                  'No hay pedidos para validar',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              );
            }

            // Pre-computar mapa de productos por pedidoId → O(n) en vez de O(n²)
            final productsByPedido = <int?, List<BatchProduct>>{};
            for (final p in products) {
              (productsByPedido[p.pedidoId] ??= []).add(p);
            }

            return Column(
              children: [
                ValidateBatchHeader(
                  batchName: bloc.currentBatch?.name ?? '',
                  progress: bloc.calcularProgresoReal(),
                  onBack: () => goToScreen(context, 'scan-product-cluster'),
                  menu: ValidateBatchMenu(
                    onSelected: (value) => _onMenuSelected(value, bloc),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      // Campo invisible del escáner: conserva el foco sin
                      // ocupar espacio en el layout.
                      Positioned(
                        left: 0,
                        top: 0,
                        right: 0,
                        child: Opacity(
                          opacity: 0,
                          child: IgnorePointer(
                            child: BarcodeScannerField(
                              controller: _controllerToDo,
                              focusNode: focusNodeBuscar,
                              onBarcodeScanned: validateBarcode,
                            ),
                          ),
                        ),
                      ),
                      ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: pedidos.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final pedido = pedidos[index];
                          final pedidoProducts =
                              productsByPedido[pedido.idPedido] ?? const [];
                          return _buildPedidoCard(pedido, pedidoProducts, bloc);
                        },
                      ),
                    ],
                  ),
                ),
                ClusterActionFooter(
                  label: 'Cerrar Batch',
                  icon: Icons.verified_user_outlined,
                  onPressed: () => context.read<ValidateClusterBloc>().add(
                    CloseBatchEvent(bloc.currentBatch?.id ?? 0),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _onMenuSelected(String value, ClusterPickingBloc bloc) {
    switch (value) {
      case 'verificar':
        bloc.isSearch = false;
        goToScreen(context, 'detail-cluster');
        break;
      case 'salir':
        // Regresar al listado de batch
        bloc.add(FetchPickingClustersEvent());
        goToScreen(context, 'picking-cluster');
        break;
      case 'filtros':
        // Lógica para filtros (pendiente por definir)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Filtros seleccionados')));
        break;
    }
  }

  Widget _buildPedidoCard(
    PedidoValidate pedido,
    List<BatchProduct> products,
    ClusterPickingBloc bloc,
  ) {
    final showValidate =
        bloc.configurations.result?.result?.showButtonValidateClusterPicking ==
        true;
    return PedidoValidateCard(
      key: ValueKey(pedido.idPedido),
      pedido: pedido,
      products: products,
      onValidate: showValidate
          ? () => _confirmValidatePedido(pedido, products)
          : null,
    );
  }

  void _confirmValidatePedido(
    PedidoValidate pedido,
    List<BatchProduct> products,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        actionsAlignment: MainAxisAlignment.center,
        title: Center(
          child: const Text(
            '360 Software Informa',
            style: TextStyle(
              fontSize: 16,
              color: primaryColorApp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        content: const Text(
          '¿Está seguro de que desea validar este pedido?',
          style: TextStyle(fontSize: 14, color: black),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Future.microtask(() {
                if (mounted) focusNodeBuscar.requestFocus();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: grey,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: const Size(60, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontSize: 14, color: white),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ValidateClusterBloc>().add(
                TapMarkPedidoEvent(
                  batchId: pedido.batchId ?? 0,
                  namePedido: pedido.namePedido ?? '',
                  listIdMove: products.map((p) => p.idMove ?? 0).toList(),
                ),
              );
              Navigator.pop(context);
              Future.microtask(() {
                if (mounted) focusNodeBuscar.requestFocus();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColorApp,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: const Size(60, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Validar',
              style: TextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
