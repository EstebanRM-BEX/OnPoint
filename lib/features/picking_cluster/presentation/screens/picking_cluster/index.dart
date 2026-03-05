import 'package:get/get.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/picking_cluster/presentation/bloc/cluster_picking/cluster_picking_bloc.dart';
import 'package:wms_app/shared/widgets/custom_header_widget.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';
import 'package:wms_app/features/picking_cluster/presentation/screens/picking_cluster/widgets/picking_batch_card.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';

class PickingClusterScreen extends StatefulWidget {
  const PickingClusterScreen({super.key});

  @override
  State<PickingClusterScreen> createState() => _PickingClusterScreenState();
}

class _PickingClusterScreenState extends State<PickingClusterScreen> {
  final IAudioService _audioService = getIt<IAudioService>();
  final IVibrationService _vibrationService = getIt<IVibrationService>();
  FocusNode focusNodeBuscar = FocusNode();
  final TextEditingController _controllerToDo = TextEditingController();

  void validateBarcode(String value, BuildContext context) {}

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: BlocListener<ClusterPickingBloc, ClusterPickingState>(
        listener: (context, state) {
          if (state is PickingClustersLoading) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) =>
                  const DialogLoading(message: "Sincronizando Localmente..."),
            );
          }

          if (state is PickingClustersLoaded) {
            if (Navigator.canPop(context)) {
              Navigator.pop(context); // Cierra el loader
            }
          }

          if (state is BatchProductsLoading) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) =>
                  const DialogLoading(message: "Cargando productos..."),
            );
          }

          if (state is BatchProductsLoaded) {
            if (Navigator.canPop(context)) {
              Navigator.pop(context); // Cierra loader
            }

            final pendingProducts =
                state.products.where((p) => p.isSeparate == 0).toList();
            if (pendingProducts.isNotEmpty) {
              context
                  .read<ClusterPickingBloc>()
                  .add(LoadCurrentProductEvent(pendingProducts.first));
            }

            Navigator.pushReplacementNamed(context, 'scan-product-cluster',
                arguments: state.batch);
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
        child: Scaffold(
          backgroundColor: white,
          body: BlocBuilder<ClusterPickingBloc, ClusterPickingState>(
            builder: (context, state) {
              return Column(
                children: [
                  CustomHeaderWidget(
                    title: 'PICK CLUSTER',
                    onBack: () {
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                    onRefresh: () async {
                      context
                          .read<ClusterPickingBloc>()
                          .add(const FetchPickingClustersEvent());
                    },
                    showCalendar: false,
                  ),
                  const SizedBox(height: 10),
                  BarcodeScannerField(
                    controller: _controllerToDo,
                    focusNode: focusNodeBuscar,
                    onBarcodeScanned: (value, context) {
                      validateBarcode(value, context);
                    },
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        if (state is PickingClustersLoaded) {
                          if (state.batches.isEmpty) {
                            return const Center(
                              child: Text(
                                'No hay clusters disponibles',
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            );
                          }
                          return ListView.builder(
                            itemCount: state.batches.length,
                            itemBuilder: (context, index) {
                              final batch = state.batches[index];
                              return PickingBatchCard(
                                batch: batch,
                                onTap: () {
                                  context
                                      .read<ClusterPickingBloc>()
                                      .add(FetchBatchProductsEvent(batch));
                                },
                              );
                            },
                          );
                        } else if (state is PickingClustersLoading) {
                          return const SizedBox
                              .shrink(); // Loader handled by dialog
                        }

                        // Initial state or error fallback
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: const Center(
                            child: Text(
                              'No hay clusters disponibles, recargue la pantalla',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ),
                        );
                      },
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
}
