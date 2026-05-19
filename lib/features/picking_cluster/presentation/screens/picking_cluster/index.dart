// ignore_for_file: use_build_context_synchronously

import 'package:get/get.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/picking_batch.dart';
import 'package:wms_app/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/picking_cluster/presentation/bloc/cluster_picking/cluster_picking_bloc.dart';
import 'package:wms_app/shared/widgets/custom_header_widget.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';
import 'package:wms_app/features/picking_cluster/presentation/screens/picking_cluster/widgets/picking_batch_card.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_start_picking_widget.dart';

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
  bool _isProcessing = false;

  void validateBarcode(String value, BuildContext context) {}

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    focusNodeBuscar.unfocus();
    focusNodeBuscar.dispose();
    _controllerToDo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: BlocListener<ClusterPickingBloc, ClusterPickingState>(
        listener: (context, state) {
          print('State: $state');
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
            } else if (state.products.isNotEmpty) {
              context
                  .read<ClusterPickingBloc>()
                  .add(LoadCurrentProductEvent(state.products.last));
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
          backgroundColor: primaryColorApp,
          body: BlocBuilder<ClusterPickingBloc, ClusterPickingState>(
            builder: (context, state) {
              return SafeArea(
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      CustomHeaderWidget(
                        title: 'PICK CLUSTER',
                        onBack: () {
                          Navigator.pushReplacementNamed(context, '/home');
                        },
                        onRefresh: () async {
                          if (_isProcessing ||
                              context.read<ClusterPickingBloc>().state
                                  is PickingClustersLoading) return;

                          if (mounted) setState(() => _isProcessing = true);
                          try {
                            if (mounted) {
                              context
                                  .read<ClusterPickingBloc>()
                                  .add(const FetchPickingClustersEvent());
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isProcessing = false);
                            }
                          }
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
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 16),
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
                                      _handleBatchSelection(
                                          context, context, batch);
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
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 16),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void goBatchInfo(BuildContext context, PickingBatch batch) async {
    // 1. Mostrar Diálogo (Capturamos el contexto del diálogo)
    BuildContext? dialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx; // ✅ Capturamos el contexto del diálogo
        return const DialogLoading(
          message: 'Cargando interfaz...',
        );
      },
    );

    await Future.delayed(const Duration(milliseconds: 300));
    if (dialogContext != null) {
      Navigator.of(dialogContext!, rootNavigator: true).pop();
    }

    context.read<ClusterPickingBloc>().add(FetchBatchProductsEvent(batch));
  }

  Future<void> _handleBatchSelection(
      BuildContext context, BuildContext contextBuilder, dynamic batch) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final batchBloc = context.read<ClusterPickingBloc>();

      // 1. Mostrar diálogo de carga mientras se despachan los eventos al BLoC
      BuildContext? loadingContext;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          loadingContext = ctx;
          return const DialogLoading(message: 'Cargando batch...');
        },
      );

      await Future.delayed(const Duration(milliseconds: 400));

      // 3. Cerrar diálogo de carga
      if (loadingContext != null && Navigator.canPop(loadingContext!)) {
        Navigator.of(loadingContext!, rootNavigator: true).pop();
      }

      // 4. Definir la función de navegación
      void navigateToBatchInfo() {
        goBatchInfo(contextBuilder, batch);
      }

      // 5. Lógica para decidir si mostrar el diálogo de inicio o navegar directamente
      if (batch.startTimePick != "") {
        navigateToBatchInfo();
      } else {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => DialogStartTimeWidget(
            onAccepted: () async {
              batchBloc
                  .add(StartTimePick(batch.id ?? 0, DateTime.now(), 'batch'));
              Navigator.pop(context);
              navigateToBatchInfo();
            },
            title: 'Iniciar Picking',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
