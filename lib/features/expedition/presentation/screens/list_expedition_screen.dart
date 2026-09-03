import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/interfaces/i_audio_service.dart';
import 'package:wms_app/core/interfaces/i_vibration_service.dart';
import 'package:wms_app/core/routes/app_router.dart';
import 'package:wms_app/features/expedition/data/services/expedition_sync_coordinator.dart';
import 'package:wms_app/features/expedition/domain/entities/expedicion_pedido.dart';
import 'package:wms_app/features/expedition/presentation/bloc/assignment/expedicion_assignment_bloc.dart';
import 'package:wms_app/features/expedition/presentation/bloc/list/expedition_list_bloc.dart';
import 'package:wms_app/features/expedition/presentation/widgets/dialog_asignar_expedicion_widget.dart';
import 'package:wms_app/features/expedition/presentation/widgets/expedicion_card_widget.dart';
import 'package:wms_app/features/expedition/presentation/widgets/expedicion_propietario_filter_sheet.dart';
import 'package:wms_app/features/expedition/presentation/widgets/expedicion_sort_menu_widget.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/shared/widgets/barcode_scanner_widget.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/shared/widgets/loading_dialog_mixin.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';

class ListExpeditionScreen extends StatefulWidget {
  const ListExpeditionScreen({super.key});

  @override
  State<ListExpeditionScreen> createState() => _ListExpeditionScreenState();
}

class _ListExpeditionScreenState extends State<ListExpeditionScreen>
    with LoadingDialogMixin {
  final IAudioService _audioService = getIt<IAudioService>();
  final IVibrationService _vibrationService = getIt<IVibrationService>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _scanController = TextEditingController();
  final FocusNode _scanFocusNode = FocusNode();
  String? _selectedPropietario;
  StreamSubscription<void>? _syncedSub;

  @override
  void initState() {
    super.initState();
    context.read<ExpedicionListBloc>().add(
      const FetchExpedicionesFromDbEvent(),
    );

    // Al sincronizar validaciones offline, relee la lista desde SQLite para
    // reflejar el estado actualizado de las expediciones preservadas.
    _syncedSub = getIt<ExpeditionSyncCoordinator>().onSynced.listen((_) {
      if (!mounted) return;
      context.read<ExpedicionListBloc>().add(
        const FetchExpedicionesFromDbEvent(),
      );
    });
    // Los permisos (hide_validate_expedition, hide_validate_item_expedition,
    // etc.) viven en tbl_configurations, pero esa tabla solo se llena cuando
    // el usuario entra manualmente a "información del usuario" en Home — acá
    // forzamos la carga (fetch remoto + persistencia local) para que ya
    // estén disponibles al entrar al detalle/scan de una expedición.
    context.read<UserBloc>().add(LoadUserInfoEvent());
  }

  @override
  void dispose() {
    _syncedSub?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scanController.dispose();
    _scanFocusNode.dispose();
    super.dispose();
  }

  /// Escanear el código de la expedición (nombre, ej. "25/OUT/-00020") o de
  /// su documento origen entra directo, como si se hubiera tocado la card
  /// (asignación/detalle según corresponda) — matchea contra la lista
  /// completa, no la filtrada por el buscador de texto.
  void _handleScan(String value, BuildContext context) {
    final scan = value.trim().toLowerCase();
    _scanController.clear();
    if (scan.isEmpty) return;

    final bloc = context.read<ExpedicionListBloc>();
    for (final expedicion in bloc.todasLasExpediciones) {
      final nombre = expedicion.nombre?.toLowerCase() ?? '';
      final documentoOrigen = expedicion.documentoOrigen?.toLowerCase() ?? '';
      if (nombre == scan || documentoOrigen == scan) {
        _handleExpedicionTap(context, expedicion);
        Future.microtask(() => _scanFocusNode.requestFocus());
        return;
      }
    }

    _showScanError();
  }

  void _showScanError() {
    _audioService.playErrorSound();
    _vibrationService.vibrate();
    Future.microtask(() => _scanFocusNode.requestFocus());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Expedición no encontrada en la lista')),
    );
  }

  void _handleExpedicionTap(BuildContext context, ExpedicionPedido expedicion) {
    final expeditionId = expedicion.expeditionId;
    if (expeditionId == null) return;

    final sinResponsable =
        expedicion.responsableId == null || expedicion.responsableId == 0;

    if (!sinResponsable) {
      Navigator.pushNamed(
        context,
        AppRoutes.expeditionDetail,
        arguments: [expeditionId],
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => DialogAsignarExpedicionWidget(
        onCancel: () => Navigator.pop(dialogContext),
        onAccepted: () {
          Navigator.pop(dialogContext);
          context.read<ExpedicionAssignmentBloc>().add(
            AsignarResponsableEvent(expeditionId),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bloc = context.read<ExpedicionListBloc>();

    return MultiBlocListener(
      listeners: [
        BlocListener<ExpedicionAssignmentBloc, ExpedicionAssignmentState>(
          listener: (context, state) {
            if (state is ExpedicionAssignmentLoading) {
              showLoadingDialog('Asignando responsable...');
            }
            if (state is ExpedicionAssignmentSuccess) {
              hideLoadingDialog();
              context.read<ExpedicionListBloc>().add(
                const FetchExpedicionesFromDbEvent(),
              );
              Navigator.pushNamed(
                context,
                AppRoutes.expeditionDetail,
                arguments: [state.pedido.expeditionId],
              );
            }
            if (state is ExpedicionAssignmentError) {
              hideLoadingDialog();
              Get.snackbar(
                'Error',
                state.message,
                backgroundColor: white,
                colorText: red,
                snackPosition: SnackPosition.TOP,
              );
            }
          },
        ),
      ],
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: primaryColorApp,
          body: SafeArea(
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  // WarningWidgetCubit ya escucha ConnectionStatusCubit por su
                  // cuenta: envolver el header en otro BlocBuilder solo
                  // reconstruiría toda la barra sin usar el estado.
                  Container(
                    width: size.width,
                    color: primaryColorApp,
                    child: Column(
                      children: [
                        const WarningWidgetCubit(),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pushReplacementNamed(
                                context,
                                '/home',
                              ),
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const Expanded(
                              child: Text(
                                'EXPEDICIONES',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (_selectedPropietario != null)
                              IconButton(
                                onPressed: () =>
                                    setState(() => _selectedPropietario = null),
                                icon: const Icon(
                                  Icons.person_search_outlined,
                                  color: Colors.amber,
                                ),
                              ),
                            IconButton(
                              onPressed: () => bloc.add(
                                const FetchExpedicionesEvent(
                                  isLoadinDialog: true,
                                ),
                              ),
                              icon: const Icon(
                                Icons.refresh,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            BlocBuilder<
                              ExpedicionListBloc,
                              ExpedicionListState
                            >(
                              builder: (context, state) {
                                final expediciones = state is ExpedicionesLoaded
                                    ? state.expediciones
                                    : <ExpedicionPedido>[];
                                return ExpedicionSortMenuWidget(
                                  currentFilterKey: bloc.currentFilterKey,
                                  onSort: (field, ascending) => bloc.add(
                                    SortExpedicionListEvent(field, ascending),
                                  ),
                                  onFilterPropietario: () =>
                                      showExpedicionPropietarioFilterSheet(
                                        context,
                                        expediciones: expediciones,
                                        selected: _selectedPropietario,
                                        onSelected: (value) => setState(
                                          () => _selectedPropietario = value,
                                        ),
                                      ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  DynamicSearchBar(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    hintText: 'Buscar expedición...',
                    onSearchChanged: (value) =>
                        bloc.add(SearchExpedicionEvent(value)),
                    onSearchCleared: () =>
                        bloc.add(const SearchExpedicionEvent('')),
                  ),
                  BarcodeScannerField(
                    controller: _scanController,
                    focusNode: _scanFocusNode,
                    onBarcodeScanned: (value, context) =>
                        _handleScan(value, context),
                  ),
                  Expanded(
                    child: BlocConsumer<ExpedicionListBloc, ExpedicionListState>(
                      listenWhen: (previous, current) =>
                          current is NeedUpdateVersionExpedicionState ||
                          current is ExpedicionListError,
                      listener: (context, state) {
                        if (state is NeedUpdateVersionExpedicionState) {
                          Get.snackbar(
                            'Actualización disponible',
                            'Hay una nueva versión de la app disponible',
                            backgroundColor: white,
                            colorText: primaryColorApp,
                            snackPosition: SnackPosition.TOP,
                          );
                        }
                        if (state is ExpedicionListError) {
                          showScrollableErrorDialog(state.message);
                        }
                      },
                      buildWhen: (previous, current) =>
                          current is ExpedicionesLoaded ||
                          current is ExpedicionListLoading ||
                          current is ExpedicionListDbLoading ||
                          current is ExpedicionListError,
                      builder: (context, state) {
                        if (state is ExpedicionListLoading ||
                            state is ExpedicionListDbLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (state is ExpedicionListError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: red,
                                    size: 40,
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'No se pudieron cargar las expediciones.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: grey, fontSize: 14),
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: () => bloc.add(
                                      const FetchExpedicionesFromDbEvent(),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColorApp,
                                    ),
                                    child: const Text(
                                      'Reintentar',
                                      style: TextStyle(color: white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final expediciones = state is ExpedicionesLoaded
                            ? state.expediciones
                            : <ExpedicionPedido>[];

                        final listToShow = expediciones
                            .where(
                              (e) =>
                                  e.isTerminated != true &&
                                  (_selectedPropietario == null ||
                                      e.propietario == _selectedPropietario),
                            )
                            .toList();

                        if (listToShow.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'No se encontraron resultados.\nIntenta con otra búsqueda.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: grey, fontSize: 14),
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: listToShow.length,
                          itemBuilder: (context, index) {
                            final expedicion = listToShow[index];
                            return InkWell(
                              onTap: () =>
                                  _handleExpedicionTap(context, expedicion),
                              child: ExpedicionCardWidget(
                                expedicion: expedicion,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
