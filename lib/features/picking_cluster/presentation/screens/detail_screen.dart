import 'dart:ui';
import 'package:wms_app/shared/utils/app_navigation.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/batch_product.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/pedido_validate.dart';
import 'package:wms_app/features/picking_cluster/presentation/bloc/cluster_picking/cluster_picking_bloc.dart';
import 'package:wms_app/features/picking_cluster/presentation/utils/pedidos_ready_to_validate.dart';
import 'package:wms_app/features/picking_cluster/presentation/widgets/cluster_action_footer.dart';
import 'package:wms_app/features/picking_cluster/presentation/widgets/cluster_palette.dart';
import 'package:wms_app/features/picking_cluster/presentation/widgets/detail/detail_batch_header.dart';
import 'package:wms_app/features/picking_cluster/presentation/widgets/detail/detail_product_card.dart';
import 'package:wms_app/features/picking_cluster/presentation/bloc/detail_cluster/detail_cluster_bloc.dart';
import 'package:wms_app/features/printing/presentation/widgets/modal_printers_list.dart';
import 'package:wms_app/features/user/presentation/widgets/dialog_info_widget.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/widgets/others/dialog_view_img_temp_widget.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';
import 'package:wms_app/shared/widgets/dialog_confirm_product_load_widget.dart';
import 'package:wms_app/shared/widgets/loading_dialog_mixin.dart';

import 'picking_cluster/widgets/dialog_edit_product_widget.dart';

class DetailClusterScreen extends StatefulWidget {
  const DetailClusterScreen({super.key});

  @override
  State<DetailClusterScreen> createState() => _DetailClusterScreenState();
}

class _DetailClusterScreenState extends State<DetailClusterScreen>
    with LoadingDialogMixin {
  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Listener propio de esta pantalla: imagen del producto
        BlocListener<DetailClusterBloc, DetailClusterState>(
          listener: (context, state) {
            if (state is ImageDetailLoading) {
              showLoadingDialog('Cargando imagen...');
            } else if (state is ImageDetailSuccess) {
              hideLoadingDialog();
              showImageDialog(context, state.url);
            } else if (state is ImageDetailFailure) {
              hideLoadingDialog();
              showScrollableErrorDialog(state.error);
            }
          },
        ),
        // Listener del BLoC compartido: edición de producto y sync offline
        BlocListener<ClusterPickingBloc, ClusterPickingState>(
          listener: (context, state) {
            if (state is LoadingSendProductEdit) {
              showLoadingDialog('Enviando producto...');
            } else if (state is SendProductEditOdooStateSuccess) {
              hideLoadingDialog();
              Get.snackbar(
                '360 Software Informa',
                'Cantidad de producto ajustada correctamente',
                backgroundColor: white,
                colorText: primaryColorApp,
                icon: const Icon(Icons.check, color: Colors.green),
                showProgressIndicator: true,
                duration: const Duration(seconds: 2),
              );
            } else if (state is SendProductEditOdooStateError) {
              hideLoadingDialog();
              showScrollableErrorDialog(state.msg);
            }

            if (state is SyncPendingClusterSuccess) {
              Get.snackbar(
                '360 Software Informa',
                'Se enviaron ${state.enviados} de ${state.total} producto(s) pendiente(s)',
                backgroundColor: white,
                colorText: primaryColorApp,
                icon: Icon(
                  state.enviados == state.total
                      ? Icons.check_circle
                      : Icons.error,
                  color: state.enviados == state.total
                      ? Colors.green
                      : Colors.amber,
                ),
                duration: const Duration(seconds: 4),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<ClusterPickingBloc, ClusterPickingState>(
        builder: (context, state) {
          final bloc = context.read<ClusterPickingBloc>();
          final products = bloc.filteredProducts;
          final showOrigin =
              bloc.configurations.result?.result?.showNextLocationsInDetails ==
              true;
          final pedidosById = {
            for (final p in bloc.pedidosValidate)
              if (p.idPedido != null) p.idPedido!: p,
          };
          return WillPopScope(
            onWillPop: () async => false,
            child: Scaffold(
              backgroundColor: ClusterPalette.slate50,
              body: Column(
                children: [
                  DetailBatchHeader(
                    batchName: bloc.currentBatch?.name ?? '',
                    progress: bloc.calcularProgresoReal(),
                    onBack: () => goToScreen(context, 'scan-product-cluster'),
                    onPrint: () => ModalPrintersList.show(
                      context,
                      resIds: [bloc.currentBatch?.id],
                      companyId: 1,
                    ),
                    onProgressInfo: _showProgressInfo,
                  ),
                  Expanded(
                    child: products.isEmpty
                        ? const _EmptyProducts()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
                            itemCount: products.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) => _buildProductCard(
                              bloc,
                              products[index],
                              showOrigin,
                              pedidosById[products[index].pedidoId],
                            ),
                          ),
                  ),
                  ClusterActionFooter(
                    label: 'Validar pedidos',
                    icon: Icons.fact_check_outlined,
                    badgeCount: pedidosReadyToValidate(
                      bloc.pedidosValidate,
                      products,
                    ).length,
                    onPressed: () => goToScreen(context, 'validate-cluster'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(
    ClusterPickingBloc bloc,
    BatchProduct product,
    bool showOrigin,
    PedidoValidate? pedido,
  ) {
    final qty = DetailProductCard.toNum(product.quantity);
    final separated = DetailProductCard.toNum(product.quantitySeparate);
    final canEdit = !bloc.isSearch && separated < qty;
    final canStart = product.isSendOdoo != 1 && product.isSeparate != 1;

    return DetailProductCard(
      product: product,
      showOriginLocation: showOrigin,
      pedidoName:
          pedido?.namePedido ??
          (product.pedido == null ? null : '${product.pedido}'),
      pedidoMuelle: pedido?.muelle,
      pedidoValidated: pedido?.isValidated == true,
      separationTime: product.isSeparate == 1
          ? bloc.formatSecondsToHHMMSS(
              DetailProductCard.toNum(product.timeSeparate).toDouble(),
            )
          : null,
      onViewImage: () => context.read<DetailClusterBloc>().add(
        ViewProductImageDetailEvent(product.idProduct ?? 0),
      ),
      onPrint: () => ModalPrintersList.show(
        context,
        resIds: [product.idMove],
        companyId: 1,
      ),
      onPendingInfo: () => showDialog(
        context: context,
        builder: (_) => const DialogInfo(
          title: 'Producto pendiente',
          body: 'Este producto fue enviado al final de la lista de picking. ',
        ),
      ),
      onEdit: canEdit
          ? () => showDialog(
              context: context,
              builder: (_) {
                bloc.editProductController.text = '';
                return DialogEditProductWidget(productsBatch: product);
              },
            )
          : null,
      onStart: canStart
          ? () => showDialog(
              context: context,
              builder: (_) => DialogConfirmProductLoadWidget(
                productsBatch: product,
                onAccept: () {
                  bloc.add(LoadSelectedProductEvent(product, 'cluster'));
                  goToScreen(context, 'scan-product-cluster');
                },
              ),
            )
          : null,
      onSync: product.isSendOdoo == 0
          ? () => bloc.add(const SyncPendingClusterProductsEvent())
          : null,
    );
  }

  void _showProgressInfo() {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          actionsAlignment: MainAxisAlignment.center,
          title: Center(
            child: Text(
              'Información',
              style: TextStyle(color: primaryColorApp, fontSize: 20),
            ),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'El porcentaje de unidades separadas se calcula de la siguiente manera:',
              ),
              SizedBox(height: 5),
              Text(
                'Porcentaje de unidades separadas = (Unidades separadas / Unidades totales) * 100',
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar', style: TextStyle(color: white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'No hay productos en la lista',
            style: TextStyle(fontSize: 13, color: ClusterPalette.brand600),
          ),
          SizedBox(height: 2),
          Text(
            'Intenta con otra búsqueda',
            style: TextStyle(fontSize: 12, color: ClusterPalette.slate400),
          ),
        ],
      ),
    );
  }
}
