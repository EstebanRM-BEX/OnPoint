// ignore_for_file: use_build_context_synchronously

import 'package:get/get.dart';
import 'package:wms_app/shared/utils/app_navigation.dart';
import 'package:wms_app/features/picking_cluster/domain/entities/picking_batch.dart';
import 'package:wms_app/features/picking_cluster/presentation/bloc/picking_cluster_list/picking_cluster_list_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/features/picking_cluster/presentation/bloc/cluster_picking/cluster_picking_bloc.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';
import 'package:wms_app/features/picking_cluster/presentation/widgets/cluster_palette.dart';
import 'package:wms_app/features/picking_cluster/presentation/screens/picking_cluster/widgets/cluster_search_dock.dart';
import 'package:wms_app/features/picking_cluster/presentation/screens/picking_cluster/widgets/cluster_sort_menu.dart';
import 'package:wms_app/features/picking_cluster/presentation/screens/picking_cluster/widgets/cluster_summary_banner.dart';
import 'package:wms_app/features/picking_cluster/presentation/screens/picking_cluster/widgets/pick_cluster_header.dart';
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
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedPropietario;
  String _currentSortKey = '';

  @override
  void initState() {
    super.initState();
    // Carga local inmediata al entrar a la pantalla.
    // Si el usuario quiere datos frescos de red usa el botón de refresh.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PickingClusterListBloc>().add(
          const LoadLocalClustersEvent(),
        );
      }
    });
  }

  @override
  void dispose() {
    focusNodeBuscar.unfocus();
    focusNodeBuscar.dispose();
    _controllerToDo.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<PickingBatch> _visibleBatches(List<PickingBatch> batches) {
    final query = _searchQuery.trim().toLowerCase();
    return _sortList(
      batches.where((b) {
        if (_selectedPropietario != null &&
            b.propietario != _selectedPropietario) {
          return false;
        }
        if (query.isEmpty) return true;
        return (b.name ?? '').toLowerCase().contains(query) ||
            (b.zonaEntrega ?? '').toLowerCase().contains(query);
      }).toList(),
    );
  }

  /// Bodega común a todos los batches (prefijo de "Bodega: Operación").
  String? _sharedWarehouse(List<PickingBatch> batches) {
    final warehouses = batches
        .map((b) => (b.pickingTypeId ?? '').split(':').first.trim())
        .where((w) => w.isNotEmpty)
        .toSet();
    return warehouses.length == 1 ? warehouses.first : null;
  }

  void _onBarcodeScanned(String value) {
    final state = context.read<PickingClusterListBloc>().state;
    if (state is! ClustersLoadedState) return;
    final code = value.toLowerCase();
    final match = state.batches
        .where((b) => (b.name ?? '').toLowerCase() == code)
        .firstOrNull;
    if (match != null) {
      _onBatchTapped(match);
      return;
    }
    // Sin coincidencia exacta: el código queda como filtro visible.
    _searchController.text = value;
    setState(() => _searchQuery = value);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
    focusNodeBuscar.requestFocus();
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
              ...propietarios.map(
                (p) => RadioListTile<String?>(
                  title: Text(p),
                  value: p,
                  groupValue: _selectedPropietario,
                  onChanged: (v) {
                    setModalState(() {});
                    setState(() => _selectedPropietario = v);
                    Navigator.pop(ctx);
                  },
                ),
              ),
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
        sorted.sort(
          (a, b) => (a.scheduledDate ?? '').compareTo(b.scheduledDate ?? ''),
        );
        break;
      case 'date_desc':
        sorted.sort(
          (a, b) => (b.scheduledDate ?? '').compareTo(a.scheduledDate ?? ''),
        );
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
                  builder: (_) => const DialogLoading(
                    message: "Sincronizando Localmente...",
                  ),
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

                final pendingProducts = state.products
                    .where((p) => p.isSeparate == 0)
                    .toList();
                if (pendingProducts.isNotEmpty) {
                  context.read<ClusterPickingBloc>().add(
                    LoadCurrentProductEvent(pendingProducts.first),
                  );
                } else if (state.products.isNotEmpty) {
                  context.read<ClusterPickingBloc>().add(
                    LoadCurrentProductEvent(state.products.last),
                  );
                }

                goToScreen(
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
          backgroundColor: ClusterPalette.surface,
          body: BlocBuilder<PickingClusterListBloc, PickingClusterListState>(
            builder: (context, state) {
              final visible = state is ClustersLoadedState
                  ? _visibleBatches(state.batches)
                  : const <PickingBatch>[];
              return Column(
                children: [
                  PickClusterHeader(
                    onBack: () => goToScreen(context, '/home'),
                    onRefresh: () {
                      final listBloc = context.read<PickingClusterListBloc>();
                      if (listBloc.state is ClustersLoadingState) return;
                      listBloc.add(const FetchClustersEvent());
                    },
                    menu: ClusterSortMenu(
                      currentSortKey: _currentSortKey,
                      selectedPropietario: _selectedPropietario,
                      onSelected: (value) {
                        if (value == 'filter_propietario') {
                          if (state is ClustersLoadedState) {
                            _showPropietarioFilter(state.batches);
                          }
                        } else {
                          setState(() => _currentSortKey = value);
                        }
                      },
                    ),
                  ),
                  ClusterSummaryBanner(
                    count: visible.length,
                    warehouse: _sharedWarehouse(visible),
                  ),
                  ClusterSearchDock(
                    controller: _searchController,
                    searchFocusNode: _searchFocusNode,
                    scannerFocusNode: focusNodeBuscar,
                    scanner: BarcodeScannerField(
                      controller: _controllerToDo,
                      focusNode: focusNodeBuscar,
                      clearOnScan: true,
                      refocusOnScan: true,
                      onBarcodeScanned: (value, _) => _onBarcodeScanned(value),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                    onCleared: _clearSearch,
                    onActivateScanner: () => focusNodeBuscar.requestFocus(),
                  ),
                  Expanded(child: _buildList(state, visible)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildList(PickingClusterListState state, List<PickingBatch> visible) {
    if (state is ClustersLoadingState) return const SizedBox.shrink();

    if (state is! ClustersLoadedState) {
      return const _EmptyMessage(
        'No hay clusters disponibles, recargue la pantalla',
      );
    }

    if (visible.isEmpty) {
      return _EmptyMessage(
        _searchQuery.isNotEmpty
            ? 'Ningún batch coincide con "$_searchQuery"'
            : 'No hay clusters disponibles',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      itemCount: visible.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final batch = visible[index];
        return PickingBatchCard(
          batch: batch,
          onTap: () => _onBatchTapped(batch),
        );
      },
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final String message;

  const _EmptyMessage(this.message);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: ClusterPalette.slate400, fontSize: 15),
        ),
      ),
    );
  }
}
