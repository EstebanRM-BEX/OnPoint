// ignore_for_file: use_build_context_synchronously

import 'package:get/get.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/features/picking_cluster/data/datasources/picking_cluster_local_data_source.dart';
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
  String? _selectedPropietario;
  String _currentSortKey = '';

  List<String> _getPropietarios(List<PickingBatch> list) {
    return list
        .where((b) => b.propietario != null && b.propietario!.isNotEmpty)
        .map((b) => b.propietario!)
        .toSet()
        .toList()
      ..sort();
  }

  void _showPropietarioFilter(List<PickingBatch> list) {
    final propietarios = _getPropietarios(list);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filtrar por propietario',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              RadioListTile<String?>(
                title: const Text('Todos'),
                value: null,
                groupValue: _selectedPropietario,
                onChanged: (v) {
                  setModalState(() {});
                  setState(() => _selectedPropietario = v);
                  Navigator.pop(ctx);
                },
              ),
              ...propietarios.map((p) => RadioListTile<String?>(
                    title: Text(p),
                    value: p,
                    groupValue: _selectedPropietario,
                    onChanged: (v) {
                      setModalState(() {});
                      setState(() => _selectedPropietario = v);
                      Navigator.pop(ctx);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  List<PickingBatch> _sortList(List<PickingBatch> list) {
    final sorted = List<PickingBatch>.from(list);
    switch (_currentSortKey) {
      case 'date_asc':
        sorted.sort((a, b) =>
            (a.scheduledDate ?? '').compareTo(b.scheduledDate ?? ''));
        break;
      case 'date_desc':
        sorted.sort((a, b) =>
            (b.scheduledDate ?? '').compareTo(a.scheduledDate ?? ''));
        break;
      case 'name_asc':
        sorted.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
        break;
      case 'name_desc':
        sorted.sort((a, b) => (b.name ?? '').compareTo(a.name ?? ''));
        break;
    }
    return sorted;
  }

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
                                  is PickingClustersLoading) {
                            return;
                          }

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
                        popupMenu: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          onSelected: (value) {
                            if (value == 'filter_propietario') {
                              if (state is PickingClustersLoaded) {
                                _showPropietarioFilter(state.batches);
                              }
                            } else {
                              setState(() => _currentSortKey = value);
                            }
                          },
                          itemBuilder: (ctx) {
                            final activeColor = primaryColorApp;
                            final inactiveColor = Colors.black;

                            TextStyle getStyle(String key) => TextStyle(
                                  fontSize: 13,
                                  fontWeight: _currentSortKey == key
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: _currentSortKey == key
                                      ? activeColor
                                      : inactiveColor,
                                );
                            Color getIconColor(String key) =>
                                _currentSortKey == key
                                    ? activeColor
                                    : Colors.grey;

                            return <PopupMenuEntry<String>>[
                              // --- FECHA ---
                              const PopupMenuItem<String>(
                                enabled: false,
                                height: 30,
                                child: Text('FECHA',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Colors.grey)),
                              ),
                              PopupMenuItem<String>(
                                value: 'date_asc',
                                height: 40,
                                child: Row(children: [
                                  Icon(Icons.calendar_month_outlined,
                                      size: 16,
                                      color: getIconColor('date_asc')),
                                  const SizedBox(width: 8),
                                  Text('Más Antiguas',
                                      style: getStyle('date_asc')),
                                  if (_currentSortKey == 'date_asc') ...[
                                    const Spacer(),
                                    Icon(Icons.check,
                                        size: 15, color: activeColor),
                                  ],
                                ]),
                              ),
                              PopupMenuItem<String>(
                                value: 'date_desc',
                                height: 40,
                                child: Row(children: [
                                  Icon(Icons.calendar_month_outlined,
                                      size: 16,
                                      color: getIconColor('date_desc')),
                                  const SizedBox(width: 8),
                                  Text('Más Recientes',
                                      style: getStyle('date_desc')),
                                  if (_currentSortKey == 'date_desc') ...[
                                    const Spacer(),
                                    Icon(Icons.check,
                                        size: 15, color: activeColor),
                                  ],
                                ]),
                              ),
                              const PopupMenuDivider(),

                              // --- CONSECUTIVO ---
                              const PopupMenuItem<String>(
                                enabled: false,
                                height: 30,
                                child: Text('CONSECUTIVO',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Colors.grey)),
                              ),
                              PopupMenuItem<String>(
                                value: 'name_asc',
                                height: 40,
                                child: Row(children: [
                                  Icon(Icons.arrow_upward,
                                      size: 16,
                                      color: getIconColor('name_asc')),
                                  const SizedBox(width: 8),
                                  Text('Consecutivo (A-Z)',
                                      style: getStyle('name_asc')),
                                  if (_currentSortKey == 'name_asc') ...[
                                    const Spacer(),
                                    Icon(Icons.check,
                                        size: 15, color: activeColor),
                                  ],
                                ]),
                              ),
                              PopupMenuItem<String>(
                                value: 'name_desc',
                                height: 40,
                                child: Row(children: [
                                  Icon(Icons.arrow_downward,
                                      size: 16,
                                      color: getIconColor('name_desc')),
                                  const SizedBox(width: 8),
                                  Text('Consecutivo (Z-A)',
                                      style: getStyle('name_desc')),
                                  if (_currentSortKey == 'name_desc') ...[
                                    const Spacer(),
                                    Icon(Icons.check,
                                        size: 15, color: activeColor),
                                  ],
                                ]),
                              ),
                              const PopupMenuDivider(),

                              // --- PROPIETARIO ---
                              const PopupMenuItem<String>(
                                enabled: false,
                                height: 30,
                                child: Text('PROPIETARIO',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Colors.grey)),
                              ),
                              PopupMenuItem<String>(
                                value: 'filter_propietario',
                                height: 40,
                                child: Row(children: [
                                  Icon(Icons.person_search_outlined,
                                      size: 16,
                                      color: _selectedPropietario != null
                                          ? Colors.amber
                                          : Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedPropietario ??
                                          'Filtrar propietario',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _selectedPropietario != null
                                            ? Colors.amber
                                            : Colors.black,
                                        fontWeight: _selectedPropietario != null
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (_selectedPropietario != null)
                                    const Icon(Icons.check,
                                        size: 15, color: Colors.amber),
                                ]),
                              ),
                            ];
                          },
                        ),
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
                              final listToShow = _sortList(
                                state.batches
                                    .where((b) =>
                                        _selectedPropietario == null ||
                                        b.propietario == _selectedPropietario)
                                    .toList(),
                              );
                              if (listToShow.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No hay clusters disponibles',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 16),
                                  ),
                                );
                              }
                              return ListView.builder(
                                itemCount: listToShow.length,
                                itemBuilder: (context, index) {
                                  final batch = listToShow[index];
                                  return PickingBatchCard(
                                    batch: batch,
                                    onTap: () {
                                      print('🔎 batch seleccionado:'
                                          '\n  id: ${batch.id}'
                                          '\n  name: ${batch.name}'
                                          '\n  propietario: ${batch.propietario}'
                                          '\n  manejoPropietario: ${batch.manejoPropietario}'
                                          '\n  zonaEntrega: ${batch.zonaEntrega}'
                                          '\n  userName: ${batch.userName}'
                                          '\n  state: ${batch.state}'
                                          '\n  startTimePick: ${batch.startTimePick}');
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
