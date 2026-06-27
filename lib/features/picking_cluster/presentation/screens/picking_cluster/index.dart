// ignore_for_file: use_build_context_synchronously

import 'package:get/get.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/picking_batch.dart';
import 'package:wms_app/features/picking_cluster/presentation/bloc/picking_cluster_list/picking_cluster_list_bloc.dart';
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
  FocusNode focusNodeBuscar = FocusNode();
  final TextEditingController _controllerToDo = TextEditingController();
  String? _selectedPropietario;
  String _currentSortKey = '';

  @override
  void initState() {
    super.initState();
    // Carga local inmediata al entrar a la pantalla.
    // Si el usuario quiere datos frescos de red usa el botón de refresh.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context
            .read<PickingClusterListBloc>()
            .add(const LoadLocalClustersEvent());
      }
    });
  }

  @override
  void dispose() {
    focusNodeBuscar.unfocus();
    focusNodeBuscar.dispose();
    _controllerToDo.dispose();
    super.dispose();
  }

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

  void _onBatchTapped(PickingBatch batch) {
    final listBloc = context.read<PickingClusterListBloc>();
    if (batch.startTimePick != "") {
      listBloc.add(SelectBatchEvent(batch));
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => DialogStartTimeWidget(
          onAccepted: () async {
            Navigator.pop(ctx);
            listBloc.add(SelectBatchEvent(batch, startTime: DateTime.now()));
          },
          title: 'Iniciar Picking',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: MultiBlocListener(
        listeners: [
          // Listener del BLoC de lista: carga de clusters y errores
          BlocListener<PickingClusterListBloc, PickingClusterListState>(
            listener: (context, state) {
              if (state is ClustersLoadingState) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const DialogLoading(message: "Sincronizando Localmente..."),
                );
              }

              if (state is ClustersLoadedState) {
                if (Navigator.canPop(context)) Navigator.pop(context);
              }

              if (state is ClustersErrorState) {
                if (Navigator.canPop(context)) Navigator.pop(context);
                Get.snackbar(
                  '360 Software Informa',
                  state.message,
                  backgroundColor: white,
                  colorText: primaryColorApp,
                  icon: const Icon(Icons.error, color: Colors.red),
                  showProgressIndicator: true,
                  duration: const Duration(seconds: 5),
                );
              }

              if (state is BatchStartTimeErrorState) {
                Get.snackbar(
                  '360 Software Informa',
                  state.message,
                  backgroundColor: white,
                  colorText: primaryColorApp,
                  icon: const Icon(Icons.error, color: Colors.red),
                  duration: const Duration(seconds: 4),
                );
              }
            },
          ),

          // Listener del BLoC compartido: carga de productos y navegación
          BlocListener<ClusterPickingBloc, ClusterPickingState>(
            listener: (context, state) {
              if (state is BatchProductsLoading) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const DialogLoading(message: "Cargando productos..."),
                );
              }

              if (state is BatchProductsLoaded) {
                if (Navigator.canPop(context)) Navigator.pop(context);

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

                Navigator.pushReplacementNamed(
                  context,
                  'scan-product-cluster',
                  arguments: state.batch,
                );
              }

              if (state is BatchProductsError) {
                if (Navigator.canPop(context)) Navigator.pop(context);
                Get.snackbar(
                  '360 Software Informa',
                  state.message,
                  backgroundColor: white,
                  colorText: primaryColorApp,
                  icon: const Icon(Icons.error, color: Colors.red),
                  showProgressIndicator: true,
                  duration: const Duration(seconds: 5),
                );
              }
            },
          ),
        ],
        child: Scaffold(
          backgroundColor: primaryColorApp,
          body: BlocBuilder<PickingClusterListBloc, PickingClusterListState>(
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
                          final listBloc =
                              context.read<PickingClusterListBloc>();
                          if (listBloc.state is ClustersLoadingState) return;
                          listBloc.add(const FetchClustersEvent());
                        },
                        showCalendar: false,
                        popupMenu: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          onSelected: (value) {
                            if (value == 'filter_propietario') {
                              if (state is ClustersLoadedState) {
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
                        onBarcodeScanned: (value, context) {},
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            if (state is ClustersLoadedState) {
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
                                    onTap: () => _onBatchTapped(batch),
                                  );
                                },
                              );
                            }

                            if (state is ClustersLoadingState) {
                              return const SizedBox.shrink();
                            }

                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Center(
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
}
