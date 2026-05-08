import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/utils/get_colors_utils.dart';
import 'package:wms_app/features/picking_cluster/presentation/bloc/cluster_picking/cluster_picking_bloc.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/pedido_validate.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/batch_product.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';

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

  /// ThemeData cacheado para evitar crear copias por cada card.
  ThemeData? _cardTheme;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cardTheme ??= Theme.of(context).copyWith(dividerColor: Colors.transparent);
    FocusScope.of(context).requestFocus(focusNodeBuscar);
  }

  @override
  void dispose() {
    focusNodeBuscar.dispose();
    _controllerToDo.dispose();
    super.dispose();
  }

  void validateBarcode(String value, BuildContext context) {
    final bloc = context.read<ClusterPickingBloc>();
    final scan = value.trim().toLowerCase();
    _controllerToDo.clear();
    debugPrint('🔎 Scan barcode: $scan');

    final pedido = bloc.pedidosValidate.firstWhere(
      (p) => p.barcodeMuelle?.toLowerCase() == scan,
      orElse: () => const PedidoValidate(),
    );

    // ✅ Pedido encontrado → despachar evento y salir
    if (pedido.idPedido != null) {
      final listIdMove = bloc.filteredProducts
          .where((p) => p.pedidoId == pedido.idPedido)
          .map((p) => p.idMove ?? 0)
          .toList();

      bloc.add(MarkPedidoAsValidatedEvent(
        batchId: pedido.batchId ?? 0,
        namePedido: pedido.namePedido ?? '',
        isValidated: true,
        listIdMove: listIdMove,
      ));
      Future.microtask(() => focusNodeBuscar.requestFocus());
      return;
    }

    // ❌ No encontrado → feedback de error
    _vibrationService.vibrate();
    _audioService.playErrorSound();
    Future.microtask(() => focusNodeBuscar.requestFocus());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código no encontrado en la lista')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      body: BlocConsumer<ClusterPickingBloc, ClusterPickingState>(
        listener: (context, state) {
          print('✅ state: $state');
          if (state is ValidatePedidoStateError) {
            Get.snackbar(
              '360 Software Informa',
              state.msg,
              backgroundColor: white,
              colorText: primaryColorApp,
              icon: const Icon(Icons.error, color: Colors.red),
              showProgressIndicator: true,
              duration: const Duration(seconds: 5),
            );
          }

          if (state is PickingClustersLoading) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) =>
                  const DialogLoading(message: "Sincronizando Localmente..."),
            );
          }

          if (state is PickingClustersLoaded) {
            Navigator.of(context).popUntil((route) => route.isFirst);
            Navigator.pushReplacementNamed(
              context,
              'picking-cluster',
            );
          }

          if (state is PickingClustersError || state is BatchProductsError) {
            if (Navigator.canPop(context)) {
              Navigator.pop(context); // Cierra el loader
            }
            Get.snackbar(
              '360 Software Informa',
              state is PickingClustersError
                  ? state.message
                  : (state as BatchProductsError).message,
              backgroundColor: white,
              colorText: primaryColorApp,
              icon: const Icon(Icons.error, color: Colors.red),
              showProgressIndicator: true,
              duration: Duration(seconds: 5),
            );
          }
        },
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
              // Barra superior
              Container(
                width: double.infinity,
                color: primaryColorApp,
                child: Column(
                  children: [
                    const WarningWidgetCubit(),
                    Padding(
                      padding: const EdgeInsets.only(top: 25),
                      child: SizedBox(
                        height: 50,
                        child: Row(
                          children: [
                            //icono para atras
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: white),
                              onPressed: () {
                                //scan-product-cluster
                                Navigator.pushReplacementNamed(
                                  context,
                                  'scan-product-cluster',
                                );
                              },
                            ),
                            const Spacer(),
                            Align(
                              alignment: Alignment.center,
                              child: Column(
                                children: [
                                  Text(
                                    bloc.currentBatch?.name ?? '',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 14),
                                  ),
                                  Card(
                                    elevation: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 2),
                                      child: Text(
                                        "Unidades separadas: ${(context.read<ClusterPickingBloc>().calcularProgresoReal())}%",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: getColorForPercentage(
                                              double.tryParse(context
                                                      .read<
                                                          ClusterPickingBloc>()
                                                      .calcularProgresoReal()) ??
                                                  0.0), // Convertir a double
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: white),
                              onSelected: (value) async {
                                switch (value) {
                                  case 'verificar':
                                    context
                                        .read<ClusterPickingBloc>()
                                        .isSearch = false;
                                    Navigator.pushReplacementNamed(
                                      context,
                                      'detail-cluster',
                                    );
                                    break;
                                  case 'salir':
                                    // Regresar al listado de batch
                                    context
                                        .read<ClusterPickingBloc>()
                                        .add(FetchPickingClustersEvent());

                                    Navigator.pushReplacementNamed(
                                      context,
                                      'picking-cluster',
                                    );
                                    break;
                                  case 'filtros':
                                    // Lógica para filtros (pendiente por definir)
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Filtros seleccionados')),
                                    );
                                    break;
                                }
                              },
                              itemBuilder: (BuildContext context) =>
                                  <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                  value: 'verificar',
                                  child: Text('Verificar unidades',
                                      style: TextStyle(
                                        fontSize: 12,
                                      )),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'salir',
                                  child: Text('Salir al listado de batch',
                                      style: TextStyle(fontSize: 12)),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'filtros',
                                  child: Text('Filtros',
                                      style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              BarcodeScannerField(
                controller: _controllerToDo,
                focusNode: focusNodeBuscar,
                onBarcodeScanned: (value, context) {
                  return validateBarcode(value, context);
                },
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: pedidos.length,
                  itemBuilder: (context, index) {
                    final pedido = pedidos[index];
                    final pedidoProducts =
                        productsByPedido[pedido.idPedido] ?? const [];

                    return _buildPedidoCard(pedido, pedidoProducts, bloc);
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                    onPressed: () {
                      //validamos que todos los pedidos esten validados
                      if (bloc.pedidosValidate
                          .every((pedido) => pedido.isValidated == true)) {
                        bloc.add(ClearFieldsEvent());
                        bloc.add(EndTimePick(
                            bloc.currentBatch?.id ?? 0, DateTime.now()));
                        bloc.add(const FetchPickingClustersEvent());
                      } else {
                        Get.snackbar("360 Software Informa",
                            "No todos los pedidos estan validados",
                            backgroundColor: white,
                            colorText: primaryColorApp,
                            icon: Icon(Icons.error, color: Colors.red));
                        return;
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                      backgroundColor: primaryColorApp,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(12),
                        ),
                      ),
                    ),
                    child: const Text("Cerrar Batch",
                        style: TextStyle(color: Colors.white))),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPedidoCard(PedidoValidate pedido, List<BatchProduct> products,
      ClusterPickingBloc bloc) {
    final bool isValidated = pedido.isValidated ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isValidated ? Colors.green[100] : Colors.grey[300],
      elevation: 2,
      child: Theme(
        data: _cardTheme!,
        child: ExpansionTile(
          backgroundColor: white,
          title: Text(
            pedido.namePedido ?? 'Sin Nombre',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: primaryColorApp,
            ),
          ),
          subtitle: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'Muelle:',
                    style: TextStyle(color: primaryColorApp, fontSize: 12),
                  ),
                  Text(
                    pedido.muelle ?? 'S',
                    maxLines: 2,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text(
                    'Barcode:',
                    style: TextStyle(color: primaryColorApp, fontSize: 12),
                  ),
                  Text(
                    pedido.barcodeMuelle ?? 'N/A',
                    maxLines: 2,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          trailing:
              // (context
              //             .read<ClusterPickingBloc>()
              //             .configurations
              //             .result
              //             ?.result
              //             ?.showButtonValidateClusterPicking ==
              //         true)
              //     ? _buildTrailing(pedido, products, bloc)
              // : null,
              _buildTrailing(pedido, products, bloc),
          children: [
            Container(
              color: white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              // Limitamos la altura al 65% de la pantalla para evitar renderizado síncrono de cientos de items
              constraints: BoxConstraints(
                maxHeight: products.length > 3
                    ? MediaQuery.of(context).size.height * 0.6
                    : double.infinity,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: products.length > 3
                    ? const ClampingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return _ProductItemWidget(product: products[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrailing(PedidoValidate pedido, List<BatchProduct> products,
      ClusterPickingBloc bloc) {
    final bool isValidated = pedido.isValidated ?? false;

    if (isValidated) {
      return const CircleAvatar(
        backgroundColor: Colors.green,
        radius: 14,
        child: Icon(Icons.check, color: Colors.white, size: 18),
      );
    }

    return ElevatedButton(
      onPressed: () {
        //dialogo de confirmacion
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            actionsAlignment: MainAxisAlignment.center,
            title: Center(
              child: const Text('360 Software Informa',
                  style: TextStyle(
                      fontSize: 16,
                      color: primaryColorApp,
                      fontWeight: FontWeight.bold)),
            ),
            content: const Text(
                '¿Está seguro de que desea validar este pedido?',
                style: TextStyle(fontSize: 14, color: black)),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: grey,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: const Size(60, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Cancelar',
                    style: TextStyle(fontSize: 14, color: white)),
              ),
              ElevatedButton(
                onPressed: () {
                  bloc.add(MarkPedidoAsValidatedEvent(
                    batchId: pedido.batchId ?? 0,
                    namePedido: pedido.namePedido ?? '',
                    isValidated: true,
                    listIdMove: products.map((p) => p.idMove ?? 0).toList(),
                  ));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColorApp,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: const Size(60, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Validar',
                    style: TextStyle(fontSize: 14, color: Colors.white)),
              ),
            ],
          ),
        );
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
      child: const Text('Validar', style: TextStyle(fontSize: 12)),
    );
  }
}

class _ProductItemWidget extends StatelessWidget {
  final BatchProduct product;

  const _ProductItemWidget({required this.product});

  @override
  Widget build(BuildContext context) {
    final qty = product.quantity ?? 0;
    final qtySeparate = product.quantitySeparate ?? 0;

    return Card(
      color: white,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productId ?? 'Producto desconocido',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (product.lote != null && product.lote!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Lote: ${product.lote}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: black,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  if (product.observation != null &&
                      product.observation!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Novedad: ${product.observation}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: black,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.add,
                        color: primaryColorApp,
                        size: 15,
                      ),
                      const SizedBox(width: 5),
                      const Text("Unidades:",
                          style: TextStyle(fontSize: 12, color: black)),
                      const SizedBox(width: 5),
                      Text(qty.toString(),
                          style: const TextStyle(
                              fontSize: 12, color: primaryColorApp)),
                      const Spacer(),
                      const Icon(
                        Icons.check,
                        color: primaryColorApp,
                        size: 15,
                      ),
                      const SizedBox(width: 5),
                      const Text("Separadas:",
                          style: TextStyle(fontSize: 12, color: black)),
                      const SizedBox(width: 5),
                      Text(qtySeparate.toString(),
                          style: const TextStyle(
                              fontSize: 12, color: primaryColorApp)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
